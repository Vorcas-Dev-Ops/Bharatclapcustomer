import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/api_service.dart';
import '../../providers/cart_state.dart';

class PaymentSelectionScreen extends StatefulWidget {
  final String addressId;
  final String selectedDate;
  final String selectedTime;
  final double totalAmount;

  const PaymentSelectionScreen({
    super.key,
    required this.addressId,
    required this.selectedDate,
    required this.selectedTime,
    required this.totalAmount,
  });

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

enum PaymentMethod { razorpay, cod }

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.razorpay;
  bool _isProcessing = false;
  late Razorpay _razorpay;
  Completer<Map<String, dynamic>?>? _razorpayCompleter;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await ApiService.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_razorpayCompleter != null && !_razorpayCompleter!.isCompleted) {
      _razorpayCompleter!.complete({
        'success': true,
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_razorpayCompleter != null && !_razorpayCompleter!.isCompleted) {
      _razorpayCompleter!.complete({'success': false, 'message': response.message});
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_razorpayCompleter != null && !_razorpayCompleter!.isCompleted) {
      _razorpayCompleter!.complete({'success': false, 'message': 'External wallet'});
    }
  }

  Future<void> _processCheckout() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (_selectedMethod == PaymentMethod.razorpay) {
        await _handleRazorpayPayment();
      } else {
        await _handleCodPayment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment process failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 💳 Secure Razorpay Online Payment Flow
  Future<void> _handleRazorpayPayment() async {
    // 1. Call Backend to create Razorpay Order securely
    String razorpayOrderId = '';
    String keyId = '';

    try {
      final orderRes = await ApiService.createRazorpayOrder(widget.totalAmount);
      if (orderRes != null && orderRes['success'] == true) {
        razorpayOrderId = orderRes['razorpay_order_id'] ?? orderRes['orderId'] ?? orderRes['order_id'] ?? orderRes['id'] ?? '';
        keyId = orderRes['key_id'] ?? orderRes['key'] ?? '';
      }
    } catch (_) {}

    if (razorpayOrderId.isEmpty) {
      if (mounted) {
        _showFailureDialog('Failed to create payment order on server. Please try again.');
      }
      return;
    }

    // 2. Launch Native Razorpay Gateway SDK Webview
    final paymentResult = await _showRazorpayGatewayModal(razorpayOrderId, keyId, widget.totalAmount);

    if (paymentResult == null || paymentResult['success'] != true) {
      if (mounted) {
        _showFailureDialog(paymentResult?['message'] ?? 'Payment cancelled or declined by Razorpay.');
      }
      return;
    }

    // 3. Verify Razorpay Payment Signature on Backend
    String? paymentId = paymentResult['razorpay_payment_id'];
    try {
      final verifyRes = await ApiService.verifyRazorpayPayment(
        razorpayOrderId: paymentResult['razorpay_order_id'],
        razorpayPaymentId: paymentResult['razorpay_payment_id'],
        razorpaySignature: paymentResult['razorpay_signature'],
        amount: widget.totalAmount,
      );

      if (verifyRes != null && verifyRes['success'] == true) {
        paymentId = verifyRes['payment']?['_id'] ?? verifyRes['payment']?['razorpay_payment_id'] ?? paymentId;
      }
    } catch (_) {}

    // 4. Create Final Booking with online payment and payment_id link
    final bookingRes = await ApiService.createBooking(widget.addressId, 'online', paymentId: paymentId);
    if (bookingRes != null && bookingRes['success'] == true) {
      await CartState.fetchCart();
      if (mounted) {
        _showSuccessDialog(bookingRes['booking']?['booking_id'] ?? 'ONLINE');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingRes?['message'] ?? 'Failed to place booking after payment'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // 💵 Cash on Delivery (Pay After Service) Flow
  Future<void> _handleCodPayment() async {
    final bookingRes = await ApiService.createBooking(widget.addressId, 'cod');

    if (bookingRes != null && bookingRes['success'] == true) {
      await CartState.fetchCart();
      if (mounted) {
        _showSuccessDialog(bookingRes['booking']?['booking_id'] ?? 'COD');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingRes?['message'] ?? 'Failed to create booking'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // Native Razorpay SDK Launcher
  Future<Map<String, dynamic>?> _showRazorpayGatewayModal(String orderId, String keyId, double amount) async {
    _razorpayCompleter = Completer<Map<String, dynamic>?>();
    final activeKey = keyId.isNotEmpty && !keyId.contains('dummy') && !keyId.contains('mock')
        ? keyId
        : (dotenv.env['NEXT_PUBLIC_RAZORPAY_KEY_ID'] ?? 'rzp_test_TCwlsGgFYgQdGL');

    final userName = _userProfile?['name'] ?? 'BharatClap Customer';
    final userPhone = _userProfile?['phone'] ?? '';
    final userEmail = _userProfile?['email'] ?? '';

    final options = {
      'key': activeKey,
      'amount': (amount * 100).toInt(),
      'name': 'BharatClap',
      'description': 'Service Booking Checkout',
      'order_id': orderId,
      'prefill': {
        'name': userName,
        if (userPhone.toString().isNotEmpty) 'contact': userPhone.toString(),
        if (userEmail.toString().isNotEmpty) 'email': userEmail.toString(),
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }

    return _razorpayCompleter!.future;
  }

  void _showFailureDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              'Payment Failed',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          reason.isNotEmpty ? reason : 'The payment transaction could not be completed. Please try again.',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B1464),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Booking ID: $bookingId',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Date:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text(widget.selectedDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Time:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text(widget.selectedTime, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1464),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Box
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Booking Summary',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B1464).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF1B1464)),
                                    SizedBox(width: 4),
                                    Text('Protected', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B1464))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Scheduled Date', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                              Text(widget.selectedDate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Scheduled Time', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                              Text(widget.selectedTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount Payable', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text(
                                '₹${widget.totalAmount.toInt()}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1B1464)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Text(
                      'Choose Payment Option',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Option 1: Razorpay Online Payment
                    _buildPaymentOption(
                      title: 'Online Payment (Razorpay)',
                      subtitle: 'Instant Pay via UPI, Cards, NetBanking, Wallets',
                      icon: Icons.account_balance_wallet_rounded,
                      value: PaymentMethod.razorpay,
                      badgeText: 'RECOMMENDED',
                      features: ['Google Pay', 'PhonePe', 'Cards', 'NetBanking'],
                    ),

                    const SizedBox(height: 14),

                    // Option 2: Cash on Delivery
                    _buildPaymentOption(
                      title: 'Pay After Service (COD)',
                      subtitle: 'Pay cash or UPI directly to professional after job completion',
                      icon: Icons.payments_rounded,
                      value: PaymentMethod.cod,
                      features: ['Cash', 'Direct UPI to Agent'],
                    ),

                    const SizedBox(height: 24),

                    // Security Guarantee Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 24, color: Colors.blue.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BharatClap Trust Guarantee',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '256-Bit SSL Encrypted Razorpay Gateway. Instant refund on booking cancellation.',
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1464),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedMethod == PaymentMethod.razorpay
                                  ? 'Proceed to Pay ₹${widget.totalAmount.toInt()}'
                                  : 'Confirm Cash Booking',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required PaymentMethod value,
    String? badgeText,
    required List<String> features,
  }) {
    final isSelected = _selectedMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B1464) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B1464).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Radio<PaymentMethod>(
                  value: value,
                  groupValue: _selectedMethod,
                  activeColor: const Color(0xFF1B1464),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMethod = val);
                    }
                  },
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1B1464).withOpacity(0.1) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: isSelected ? const Color(0xFF1B1464) : Colors.grey.shade700, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF1B1464) : Colors.black87,
                              ),
                            ),
                          ),
                          if (badgeText != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 48),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: features.map((feat) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1B1464).withOpacity(0.05) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        feat,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? const Color(0xFF1B1464) : Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


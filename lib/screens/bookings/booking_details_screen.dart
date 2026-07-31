import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'track_service_screen.dart';
import '../../services/api_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  final dynamic booking;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.booking,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _isLoading = false;
  dynamic _bookingData;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.booking;
    if (_bookingData == null) {
      _fetchBookingData();
    }
  }

  Future<void> _fetchBookingData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await ApiService.getBookingById(widget.bookingId);
      if (mounted) {
        setState(() {
          _bookingData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bookingData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: Text('Failed to load booking details.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _fetchBookingData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildServiceInfoCard(),
                    ),
                    const SizedBox(height: 24),
                    if (_bookingData['provider_id'] != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildAssignedProfessional(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildScheduleCard(),
                    ),
                    const SizedBox(height: 16),
                    if (_bookingData['address_id'] != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildAddressCard(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildPaymentMethodCard(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (['pending', 'accepted', 'on_the_way', 'arrived', 'waiting_start_otp', 'in_progress', 'waiting_end_otp'].contains(_bookingData['status']))
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (['pending', 'accepted'].contains(_bookingData['status']))
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _showCancelDialog,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel Booking',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (['pending', 'accepted'].contains(_bookingData['status']) && ['accepted', 'on_the_way', 'arrived', 'waiting_start_otp', 'in_progress', 'waiting_end_otp'].contains(_bookingData['status']))
                        const SizedBox(width: 12),
                      if (['accepted', 'on_the_way', 'arrived', 'waiting_start_otp', 'in_progress', 'waiting_end_otp'].contains(_bookingData['status']))
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrackServiceScreen(
                                      bookingId: widget.bookingId,
                                      booking: _bookingData,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B1464),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Track Service',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Cancel Booking?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Are you sure you want to cancel this booking?',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Color(0xFF1B1464)),
                              SizedBox(width: 6),
                              Text('Refund Policy Information', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B1464))),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            '• Free cancellation up to 12 hours before service.\n'
                            '• Cancellations within 3 hours are subject to a cancellation fee.\n'
                            '• Refunds for online payments will be processed to your account within 5-7 business days.',
                            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        hintText: 'Reason for cancellation (optional)',
                        hintStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Keep Booking', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final result = await ApiService.cancelBooking(
                            widget.bookingId,
                            reasonController.text.trim().isEmpty ? 'Customer requested cancellation' : reasonController.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (result != null && result['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Booking cancelled successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _fetchBookingData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result?['message'] ?? 'Failed to cancel booking'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final subservice = _bookingData['subservice_id'];
    final serviceName = subservice != null && subservice is Map
        ? subservice['subservice_name'] ?? 'Service'
        : 'Service';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Details - $serviceName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoCard() {
    final subservice = _bookingData['subservice_id'];
    final serviceName = subservice != null && subservice is Map
        ? subservice['subservice_name'] ?? 'Service'
        : 'Service';
    final bookingIdStr = _bookingData['booking_id'] ?? '#---';
    final payableAmount = _bookingData['payable_amount']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.handyman, color: Color(0xFF1B1464), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Booking ID: $bookingIdStr',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹$payableAmount',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedProfessional() {
    final provider = _bookingData['provider_id'];
    String providerName = 'Professional';
    String providerType = 'Service Provider';
    String providerRating = '4.5';

    if (provider != null && provider is Map) {
      final pUser = provider['user_id'];
      if (pUser != null && pUser is Map) {
        providerName = pUser['name'] ?? pUser['phone'] ?? providerName;
      }
      providerType = provider['profession'] ?? providerType;
      providerRating = provider['rating']?.toString() ?? providerRating;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'ASSIGNED PROFESSIONAL',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
            ),
            Text(
              'Contact',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              ClipOval(
                child: Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(providerType, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(width: 8),
                        Icon(Icons.star, color: Colors.amber.shade600, size: 14),
                        const SizedBox(width: 2),
                        Text(providerRating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.message_outlined, color: Color(0xFF1B1464), size: 20),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B1464),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard() {
    String dateStr = 'Unknown Date';
    String timeStr = 'Flexible';
    try {
      if (_bookingData['scheduled_at'] != null) {
        final dt = DateTime.parse(_bookingData['scheduled_at']).toLocal();
        dateStr = DateFormat('dd MMMM yyyy').format(dt);
        if (_bookingData['booking_time'] != null && _bookingData['booking_time'] != 'Flexible') {
          timeStr = _bookingData['booking_time'];
        } else {
          timeStr = DateFormat('hh:mm a').format(dt);
        }
      }
    } catch (e) {
      // Ignore
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1B1464), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SCHEDULED ON',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final address = _bookingData['address_id'];
    String addressLine1 = 'Address not available';
    String addressLine2 = '';

    if (address != null && address is Map) {
      final parts1 = [address['flat'], address['street']].where((e) => e != null && e.toString().isNotEmpty).toList();
      addressLine1 = parts1.isNotEmpty ? parts1.join(', ') : 'Address';
      final parts2 = [address['city'], address['state'], address['pincode']].where((e) => e != null && e.toString().isNotEmpty).toList();
      addressLine2 = parts2.join(', ');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFF1B1464)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addressLine1,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (addressLine2.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    addressLine2,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCOD() {
    if (_bookingData == null) return false;
    final method = (_bookingData['payment_method'] ?? _bookingData['payment_type'] ?? _bookingData['paymentMethod'] ?? '').toString().toLowerCase();
    final pStatus = (_bookingData['payment_status'] ?? _bookingData['paymentStatus'] ?? '').toString().toLowerCase();

    if (method == 'cod' || method == 'cash' || method == 'cash_on_delivery' || method.contains('cod')) {
      return true;
    }
    if (method == 'online' || method == 'razorpay' || method == 'upi' || method == 'card' || pStatus == 'paid' || pStatus == 'completed') {
      return false;
    }
    return pStatus != 'paid' && pStatus != 'completed';
  }

  Widget _buildPaymentMethodCard() {
    final isCOD = _isCOD();
    final amount = _bookingData['payable_amount']?.toString() ?? _bookingData['total_amount']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCOD ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCOD ? const Color(0xFFFFE082) : const Color(0xFFA5D6A7),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCOD ? Icons.payments_outlined : Icons.check_circle_rounded,
                    color: isCOD ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PAYMENT METHOD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCOD ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCOD ? const Color(0xFFFFB74D) : const Color(0xFF66BB6A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCOD ? 'CASH ON DELIVERY' : 'ONLINE PAID',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isCOD
                ? 'Please pay ₹$amount in Cash to the service provider after the job is completed.'
                : 'Payment of ₹$amount has been completed online via Razorpay / UPI.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isCOD ? const Color(0xFF5D4037) : const Color(0xFF1B5E20),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}


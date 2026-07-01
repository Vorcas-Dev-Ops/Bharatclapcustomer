import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../providers/cart_state.dart';
import 'slot_selection_screen.dart';

class CartScreen extends StatefulWidget {
  final bool useSingleCategoryDesign;
  const CartScreen({super.key, this.useSingleCategoryDesign = false});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? _currentAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
    CartState.fetchCart();
  }

  Future<void> _fetchAddress() async {
    final addresses = await ApiService.getAddresses();
    if (mounted && addresses.isNotEmpty) {
      setState(() {
        _currentAddress = addresses.first;
      });
    }
  }

  Future<void> _updateQuantity(String subserviceId, int newQuantity) async {
    setState(() => _isLoading = true);
    Map<String, dynamic>? data;
    if (newQuantity <= 0) {
      data = await ApiService.removeFromCart(subserviceId);
    } else {
      data = await ApiService.updateCartItem(subserviceId, newQuantity);
    }
    
    if (data != null) {
      CartState.cartData.value = data;
      CartState.updateCount(data);
    }
    setState(() => _isLoading = false);
  }

  void _navigateToSlotSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SlotSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: CartState.cartData,
          builder: (context, cartData, child) {
            final items = (cartData?['items'] as List<dynamic>?) ?? [];
            final totalAmount = (cartData?['total_amount'] as num?)?.toDouble() ?? 0.0;
            final isEmpty = items.isEmpty;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildAddressCard(),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildAccountDetails(),
                      ),
                      const SizedBox(height: 24),
                      if (isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: Text("Your cart is empty")),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: _buildCartItemsList(items),
                        ),
                      if (!isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: _buildPeopleAlsoChoose(),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: _buildPaymentSummary(items, totalAmount),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _navigateToSlotSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B1464),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text(
                            'Select Slot',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          const Text(
            'My Cart',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
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
                  _currentAddress?['area'] ?? 'Add an Address',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentAddress != null ? '${_currentAddress!['city']}, ${_currentAddress!['state']}' : 'No address selected',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Change',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetails() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1464),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use my account details',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Account User',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCartItemsList(List<dynamic> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.home_repair_service, color: Colors.black87, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Services',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.map((item) => _buildCartItem(item)),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Add More items',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    final subservice = item['subservice_id'];
    if (subservice == null) return const SizedBox.shrink();

    final title = subservice['subservice_name'] ?? 'Unknown Service';
    final price = item['price_snapshot'] ?? subservice['base_price'] ?? 0;
    final quantity = item['quantity'] ?? 1;
    final subserviceId = subservice['_id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${price.toInt()}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
              ),
              const SizedBox(height: 8),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8E8FF), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (!_isLoading) _updateQuantity(subserviceId, quantity - 1);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.remove, size: 16, color: Color(0xFF1B1464)),
                      ),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                    ),
                    InkWell(
                      onTap: () {
                        if (!_isLoading) _updateQuantity(subserviceId, quantity + 1);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.add, size: 16, color: Color(0xFF1B1464)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleAlsoChoose() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'People also choose',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildAlsoChooseCard('AC Repair', 'From ₹499', 'assets/images/ac_repair.png', '4.8'),
              const SizedBox(width: 16),
              _buildAlsoChooseCard('Fan Replacement', 'From ₹499', 'assets/catogries/Electrician/fan.png', '4.8'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlsoChooseCard(String title, String price, String itemImagePath, String rating) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  itemImagePath,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 90,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.green.shade600, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0).copyWith(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE8E8FF), width: 1.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B1464))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(List<dynamic> items, double itemTotal) {
    double taxes = 0; // Keeping 0 for now as requested by user to use exact real data
    double total = itemTotal + taxes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildPaymentRow('Items Total', '₹${itemTotal.toInt()}'),
              const SizedBox(height: 12),
              _buildPaymentRow('Taxes and Fee', '₹${taxes.toInt()}'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildPaymentRow('Total Amount', '₹${total.toInt()}', isBold: true),
              const SizedBox(height: 16),
              _buildPaymentRow('Amount to Pay', '₹${total.toInt()}', isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String title, String amount, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

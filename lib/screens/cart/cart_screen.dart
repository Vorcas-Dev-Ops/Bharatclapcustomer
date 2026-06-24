import 'package:flutter/material.dart';
import 'slot_selection_screen.dart';

class CartItem {
  final String id;
  final String name;
  int quantity;
  final double price;
  final String? time;
  final String? imagePath;

  CartItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    required this.price,
    this.time,
    this.imagePath,
  });
}

class CartCategory {
  final String id;
  final String name;
  final IconData icon;
  final String bookingId;
  final List<CartItem> items;

  CartCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.bookingId,
    required this.items,
  });
}

class CartScreen extends StatefulWidget {
  final bool useSingleCategoryDesign;

  const CartScreen({super.key, this.useSingleCategoryDesign = false});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartCategory> _cartCategories;

  @override
  void initState() {
    super.initState();
    if (widget.useSingleCategoryDesign) {
      _cartCategories = [
        CartCategory(
          id: 'cat1',
          name: 'Electrician',
          icon: Icons.electrical_services,
          bookingId: '#BC-98214',
          items: [
            CartItem(
              id: 'item1',
              name: 'Fan Installation',
              price: 199,
              time: '45 mins',
              imagePath: 'assets/catogries/Electrician/fan.png',
            ),
            CartItem(
              id: 'item2',
              name: 'Light & Switch Installation',
              price: 299,
              time: '45 mins',
              imagePath: 'assets/catogries/Electrician/socket.png',
            ),
          ],
        ),
      ];
    } else {
      _cartCategories = [
        CartCategory(
          id: 'cat1',
          name: 'Salon for Women',
          icon: Icons.face_retouching_natural,
          bookingId: '#BC-98214',
          items: [
            CartItem(
              id: 'item1',
              name: 'Roll-on Waxing (Full arms, legs & underarm)',
              price: 2299,
            ),
            CartItem(
              id: 'item2',
              name: 'Face & neck Bleach',
              price: 199,
            ),
          ],
        ),
        CartCategory(
          id: 'cat2',
          name: 'Cleaning',
          icon: Icons.cleaning_services_outlined,
          bookingId: '#BC-98215',
          items: [
            CartItem(
              id: 'item3',
              name: 'Bathroom (Deep clean)',
              price: 399,
            ),
            CartItem(
              id: 'item4',
              name: 'Washbasin Cleaning',
              price: 99,
            ),
          ],
        ),
      ];
    }
  }

  void _navigateToSlotSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SlotSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSingle = _cartCategories.length == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: isSingle ? 100 : 40),
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
                  ..._cartCategories.map((category) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildCategoryBlock(category, isSingle),
                      )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildPeopleAlsoChoose(),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildPaymentSummary(),
                  ),
                ],
              ),
            ),
            if (isSingle)
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
                      onPressed: _navigateToSlotSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B1464),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
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
                const Text(
                  'P and T Layout, Horama...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bengaluru, Karnataka',
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
              'Madhu Sri, 9938920830',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBlock(CartCategory category, bool isSingle) {
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
          if (!isSingle) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(category.icon, color: Colors.black87, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking ID: ${category.bookingId}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          ...category.items.map((item) => _buildCartItem(item, isSingle)),
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
          if (!isSingle) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _navigateToSlotSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1464),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Select Slot',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, bool isSingle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSingle && item.imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.imagePath!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                if (item.time != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey.shade500, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        item.time!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.price.toInt()}',
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
                        setState(() {
                          if (item.quantity > 1) item.quantity--;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.remove, size: 16, color: Color(0xFF1B1464)),
                      ),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          item.quantity++;
                        });
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

  Widget _buildPaymentSummary() {
    bool isSingle = _cartCategories.length == 1;

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
            if (!isSingle)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Includes Taxes & Fee',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
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
          child: isSingle ? _buildSinglePaymentDetails() : _buildMultiPaymentDetails(),
        ),
      ],
    );
  }

  Widget _buildSinglePaymentDetails() {
    double itemTotal = _cartCategories[0].items.fold(0, (sum, item) => sum + (item.price * item.quantity));
    double taxes = 22; // Hardcoded dummy tax to match image
    double total = itemTotal + taxes;

    return Column(
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
    );
  }

  Widget _buildMultiPaymentDetails() {
    List<Widget> rows = [];

    for (var cat in _cartCategories) {
      double catTotal = cat.items.fold(0, (sum, item) => sum + (item.price * item.quantity));
      
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            cat.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      );

      for (var item in cat.items) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildPaymentRow(item.name, '₹${(item.price * item.quantity).toInt()}'),
          ),
        );
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          child: _buildPaymentRow('Total Amount', '₹${catTotal.toInt()}', isBold: true),
        ),
      );
    }

    // Since taxes were "included" in the multi category design text
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
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

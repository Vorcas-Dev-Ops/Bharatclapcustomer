import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../providers/cart_state.dart';
import 'package:intl/intl.dart';
import 'payment_selection_screen.dart';

class SlotSelectionScreen extends StatefulWidget {
  final String addressId;
  const SlotSelectionScreen({super.key, required this.addressId});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = 4; // Default to 02:00 PM matching the image
  bool _isLoading = false;

  late List<DateTime> _dates;

  final List<String> _times = [
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
    '08:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _generateDates();
  }

  void _generateDates() {
    _dates = List.generate(4, (index) => DateTime.now().add(Duration(days: index)));
  }

  Future<void> _handleCheckout() async {
    if (_isLoading) return;
    
    final cartData = CartState.cartData.value;
    if (cartData == null || cartData['items'] == null || (cartData['items'] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedDate = DateFormat('yyyy-MM-dd').format(_dates[_selectedDateIndex]);
      final selectedTime = _times[_selectedTimeIndex];
      final totalAmount = (cartData['total_amount'] as num?)?.toDouble() ?? 0.0;

      final items = cartData['items'] as List;

      // Update slots for all items
      for (var item in items) {
        final subserviceId = item['subservice_id'];
        if (subserviceId != null) {
          final id = subserviceId['_id']?.toString() ?? subserviceId.toString();
          await ApiService.updateSlot(id, selectedDate, selectedTime);
        }
      }

      // Navigate to Payment Method Selection Screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSelectionScreen(
              addressId: widget.addressId,
              selectedDate: selectedDate,
              selectedTime: selectedTime,
              totalAmount: totalAmount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating slot: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'Select your preferred date',
                            style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          _buildDateSelector(),
                          const SizedBox(height: 32),
                          const Text(
                            'Choose a time for your service',
                            style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          _buildTimeGrid(),
                          const SizedBox(height: 100), // padding for bottom button
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                    onPressed: _isLoading ? null : _handleCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1464),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                      'Checkout',
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
            'Schedule Service',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: List.generate(_dates.length, (index) {
        bool isSelected = _selectedDateIndex == index;
        final date = _dates[index];
        final dayStr = DateFormat('E').format(date);
        final dateStr = DateFormat('d').format(date);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDateIndex = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8E8FF) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF1B1464) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  dayStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? const Color(0xFF1B1464) : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF1B1464) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: List.generate(_times.length, (index) {
        bool isSelected = _selectedTimeIndex == index;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTimeIndex = index;
            });
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 40 - 24) / 3, // 3 columns, 2 gaps of 12, padding 40
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8E8FF) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF1B1464) : Colors.transparent,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _times[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF1B1464) : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }),
    );
  }
}

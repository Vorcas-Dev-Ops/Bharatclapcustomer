import 'package:flutter/material.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({super.key});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = 4; // Default to 02:00 PM matching the image

  final List<Map<String, String>> _dates = [
    {'day': 'Fri', 'date': '12'},
    {'day': 'Sat', 'date': '13'},
    {'day': 'Sun', 'date': '14'},
    {'day': 'Mon', 'date': '15'},
  ];

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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checkout successful!')),
                      );
                      // Navigate back to home or success screen
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1464),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
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
                  _dates[index]['day']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? const Color(0xFF1B1464) : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dates[index]['date']!,
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

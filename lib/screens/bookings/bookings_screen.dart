import 'package:flutter/material.dart';
import 'booking_details_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: Ongoing, 2: Completed

  final List<String> _tabs = ['Upcoming', 'Ongoing', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                'My Bookings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildTabs(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _selectedTab == 0 ? _buildBookingsList() : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          bool isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1B1464) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBookingsList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildBookingCard(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No bookings found.',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      ),
    );
  }

  Widget _buildBookingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.ac_unit, color: Color(0xFF1B1464), size: 24), // Fan icon mock
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fan Installation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking ID: #BC-98214',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Accepted',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text('15 June 2026', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text('10:00 AM', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey.shade200,
                  child: Image.asset(
                    'assets/images/user1.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rajesh Kumar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Electrician', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(width: 8),
                        Icon(Icons.star, color: Colors.amber.shade600, size: 12),
                        const SizedBox(width: 2),
                        const Text('4.8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
              const Text(
                '₹499',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookingDetailsScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(
                  color: Color(0xFF1B1464),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

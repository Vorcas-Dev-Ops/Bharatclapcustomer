import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'booking_details_screen.dart';
import 'rate_service_screen.dart';
import '../../services/api_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: Ongoing, 2: Completed
  bool _isLoading = true;
  List<dynamic> _allBookings = [];

  final List<String> _tabs = ['Upcoming', 'Ongoing', 'Completed'];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final bookings = await ApiService.getMyBookings();
      if (mounted) {
        setState(() {
          _allBookings = bookings;
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

  List<dynamic> _getFilteredBookings() {
    return _allBookings.where((booking) {
      final status = booking['status']?.toString().toLowerCase().trim() ?? '';
      
      final completedStatuses = [
        'completed',
        'finished',
        'cancelled',
        'canceled',
        'rejected',
        'unassigned_timeout',
        'high_demand_timeout',
        'failed',
      ];

      final ongoingStatuses = [
        'accepted',
        'assigned',
        'confirmed',
        'scheduled',
        'on_the_way',
        'arrived',
        'reached',
        'waiting_start_otp',
        'in_progress',
        'started',
        'ongoing',
        'waiting_end_otp',
        'pending',
        'provider_searching',
      ];

      if (_selectedTab == 0) {
        // Upcoming: Any active non-completed booking
        return !completedStatuses.contains(status);
      } else if (_selectedTab == 1) {
        // Ongoing: Active bookings assigned, in transit, or in service
        return ongoingStatuses.contains(status) && !completedStatuses.contains(status);
      } else {
        // Completed: Finished or cancelled/expired bookings
        return completedStatuses.contains(status);
      }
    }).toList();
  }

  Future<void> _refreshBookings() async {
    await _fetchBookings();
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BharatClap',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF16155D),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'My Bookings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildTabs(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _refreshBookings,
                      child: _buildBookingsList(),
                    ),
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
    final filteredBookings = _getFilteredBookings();

    if (filteredBookings.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filteredBookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildBookingCard(filteredBookings[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView( // Use ListView so it can be refreshed
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Text(
            'No bookings found.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    // Extract data from booking object securely
    final bookingId = booking['booking_id'] ?? '#---';
    final status = booking['status']?.toString().toUpperCase() ?? 'PENDING';
    final payableAmount = booking['payable_amount']?.toString() ?? '0';

    // Subservice details
    final subservice = booking['subservice_id'];
    final serviceName = subservice != null && subservice is Map
        ? subservice['subservice_name'] ?? 'Service'
        : 'Service';
        
    // Format date and time
    String dateStr = 'Unknown Date';
    String timeStr = 'Flexible';
    try {
      if (booking['scheduled_at'] != null) {
        final dt = DateTime.parse(booking['scheduled_at']).toLocal();
        dateStr = DateFormat('dd MMMM yyyy').format(dt);
        if (booking['booking_time'] != null && booking['booking_time'] != 'Flexible') {
          timeStr = booking['booking_time'];
        } else {
          timeStr = DateFormat('hh:mm a').format(dt);
        }
      }
    } catch (e) {
      // Ignore format errors
    }

    // Provider details
    final provider = booking['provider_id'];
    String? providerName;
    String? providerType;
    String? providerRating;
    
    if (provider != null && provider is Map) {
      final pUser = provider['user_id'];
      if (pUser != null && pUser is Map) {
        providerName = pUser['name'] ?? pUser['phone'];
      }
      providerType = provider['profession'] ?? 'Professional';
      providerRating = provider['rating']?.toString();
    }
    
    // Status color mapping
    Color statusBgColor = Colors.grey.shade50;
    Color statusTextColor = Colors.grey.shade700;
    
    final lowerStatus = booking['status']?.toString().toLowerCase();
    if (lowerStatus == 'pending') {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange.shade700;
    } else if (lowerStatus == 'accepted') {
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue.shade700;
    } else if (lowerStatus == 'in_progress' || lowerStatus == 'started') {
      statusBgColor = Colors.purple.shade50;
      statusTextColor = Colors.purple.shade700;
    } else if (lowerStatus == 'completed') {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green.shade700;
    } else if (lowerStatus == 'cancelled') {
      statusBgColor = Colors.red.shade50;
      statusTextColor = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                child: const Icon(Icons.handyman, color: Color(0xFF1B1464), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking ID: $bookingId',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
          ),
          
          if (providerName != null) ...[
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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(providerType ?? 'Professional', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          if (providerRating != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.star, color: Colors.amber.shade600, size: 12),
                            const SizedBox(width: 2),
                            Text(providerRating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹$payableAmount',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Waiting for professional',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                ),
                Text(
                  '₹$payableAmount',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 20),
          Row(
            children: [
              if (lowerStatus == 'completed' && booking['is_reviewed'] != true) ...[
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RateServiceScreen(booking: booking),
                          ),
                        ).then((result) {
                          if (result == true) {
                            _fetchBookings();
                          }
                        });
                      },
                      icon: const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                      label: const Text(
                        'Rate Service',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B1464),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to details and potentially refresh upon returning
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingDetailsScreen(
                            bookingId: booking['_id'] ?? '',
                            booking: booking,
                          ),
                        ),
                      ).then((_) {
                        _fetchBookings();
                      });
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}


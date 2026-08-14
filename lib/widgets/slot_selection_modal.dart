import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../providers/cart_state.dart';
import 'app_toast.dart';

class SlotSelectionModal extends StatefulWidget {
  final List<String> subserviceIds;
  final String serviceTitle;

  const SlotSelectionModal({
    super.key,
    required this.subserviceIds,
    required this.serviceTitle,
  });

  static Future<void> show(BuildContext context, String subserviceId, String serviceTitle) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SlotSelectionModal(
        subserviceIds: [subserviceId],
        serviceTitle: serviceTitle,
      ),
    );
  }

  static Future<void> showForGroup(BuildContext context, List<String> subserviceIds, String groupTitle) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SlotSelectionModal(
        subserviceIds: subserviceIds,
        serviceTitle: groupTitle,
      ),
    );
  }

  @override
  State<SlotSelectionModal> createState() => _SlotSelectionModalState();
}

class _SlotSelectionModalState extends State<SlotSelectionModal> {
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;
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
    _dates = List.generate(4, (index) => DateTime.now().add(Duration(days: index)));
    _selectFirstAvailableSlot();
  }

  bool _isTimeSlotAvailable(String timeString) {
    if (_selectedDateIndex != 0) return true;

    try {
      final now = DateTime.now();
      final format = DateFormat('hh:mm a');
      final parsedTime = format.parse(timeString);
      
      final slotTime = DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
      // Give a 60 minutes buffer for booking
      return slotTime.isAfter(now.add(const Duration(minutes: 60)));
    } catch (e) {
      return true;
    }
  }

  void _selectFirstAvailableSlot() {
    for (int i = 0; i < _times.length; i++) {
      if (_isTimeSlotAvailable(_times[i])) {
        _selectedTimeIndex = i;
        return;
      }
    }
    _selectedTimeIndex = -1;
  }

  Future<void> _confirmSlot() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final dateObj = _dates[_selectedDateIndex];
      final selectedTime = _times[_selectedTimeIndex];
      
      DateTime combinedDateTime = dateObj;
      try {
        final parsedTime = DateFormat('hh:mm a').parse(selectedTime);
        combinedDateTime = DateTime(dateObj.year, dateObj.month, dateObj.day, parsedTime.hour, parsedTime.minute);
      } catch (_) {}

      final selectedDate = combinedDateTime.toIso8601String();

      for (final id in widget.subserviceIds) {
        await ApiService.updateSlot(id, selectedDate, selectedTime);
      }
      await CartState.fetchCart();

      if (mounted) {
        Navigator.pop(context);
        final formattedDate = DateFormat('EEE, d MMM').format(_dates[_selectedDateIndex]);
        AppToast.show(context, 'Slot scheduled for $formattedDate at $selectedTime!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Error setting slot: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Service Slot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B1464),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.serviceTitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = _selectedDateIndex == index;
                  final dayName = index == 0 ? 'Today' : DateFormat('EEE').format(date);
                  final dayNum = DateFormat('dd').format(date);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDateIndex = index;
                        if (_selectedTimeIndex == -1 || !_isTimeSlotAvailable(_times[_selectedTimeIndex])) {
                          _selectFirstAvailableSlot();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 65,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1B1464) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Time Slot',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_times.length, (index) {
                final time = _times[index];
                final isAvailable = _isTimeSlotAvailable(time);
                final isSelected = _selectedTimeIndex == index;

                return GestureDetector(
                  onTap: isAvailable ? () => setState(() => _selectedTimeIndex = index) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF1B1464) 
                          : (isAvailable ? Colors.grey.shade100 : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? Colors.white 
                            : (isAvailable ? Colors.black87 : Colors.grey.shade500),
                        decoration: isAvailable ? null : TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isLoading || _selectedTimeIndex == -1) ? null : _confirmSlot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1464),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm Slot',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

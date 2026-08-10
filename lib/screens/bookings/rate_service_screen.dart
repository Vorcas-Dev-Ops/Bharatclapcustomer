import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RateServiceScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const RateServiceScreen({
    super.key,
    required this.booking,
  });

  @override
  State<RateServiceScreen> createState() => _RateServiceScreenState();
}

class _RateServiceScreenState extends State<RateServiceScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _quickTags = [
    'Punctual',
    'Professional',
    'Clean Work',
    'Polite',
    'Great Quality',
    'On-Time Arrival',
  ];

  final Set<String> _selectedTags = {};

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Poor 😞';
      case 2:
        return 'Fair 😐';
      case 3:
        return 'Good 🙂';
      case 4:
        return 'Very Good 😊';
      case 5:
        return 'Excellent 🌟';
      default:
        return 'Tap a star to rate';
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Extract necessary Mongo ObjectIds from booking object
    final String bookingId = widget.booking['_id']?.toString() ?? '';
    
    // Extract provider _id
    final providerData = widget.booking['provider_id'];
    String providerId = '';
    if (providerData is Map) {
      providerId = providerData['_id']?.toString() ?? '';
    } else if (providerData is String) {
      providerId = providerData;
    }

    // Extract subservice and service _id
    final subserviceData = widget.booking['subservice_id'];
    String subserviceId = '';
    String serviceId = '';

    if (subserviceData is Map) {
      subserviceId = subserviceData['_id']?.toString() ?? '';
      final serviceData = subserviceData['service_id'];
      if (serviceData is Map) {
        serviceId = serviceData['_id']?.toString() ?? '';
      } else if (serviceData is String) {
        serviceId = serviceData;
      }
    } else if (subserviceData is String) {
      subserviceId = subserviceData;
    }

    // If serviceId is not found, fallback to subserviceId or service_id on booking
    if (serviceId.isEmpty) {
      serviceId = widget.booking['service_id']?.toString() ?? subserviceId;
    }

    if (bookingId.isEmpty || providerId.isEmpty || subserviceId.isEmpty || serviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing booking details required for review.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Construct final comment with tags
    String finalComment = _commentController.text.trim();
    if (_selectedTags.isNotEmpty) {
      final tagStr = _selectedTags.join(', ');
      finalComment = finalComment.isEmpty ? tagStr : '$finalComment ($tagStr)';
    }

    setState(() {
      _isSubmitting = true;
    });

    final res = await ApiService.createReview(
      bookingId: bookingId,
      providerId: providerId,
      serviceId: serviceId,
      subserviceId: subserviceId,
      rating: _rating,
      comment: finalComment.isEmpty ? 'Great service!' : finalComment,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (res['success'] == true) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to submit review.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.stars_rounded,
                color: Colors.amber,
                size: 72,
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B1464),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your rating and review have been submitted successfully. It helps us maintain service quality.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Return success to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1464),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subservice = widget.booking['subservice_id'];
    final serviceName = subservice != null && subservice is Map
        ? subservice['subservice_name'] ?? 'Service'
        : 'Service';
    final bookingIdStr = widget.booking['booking_id'] ?? '#---';

    final provider = widget.booking['provider_id'];
    String providerName = 'Service Professional';
    if (provider != null && provider is Map) {
      final pUser = provider['user_id'];
      if (pUser != null && pUser is Map) {
        providerName = pUser['name'] ?? pUser['phone'] ?? providerName;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Rate & Review',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking & Provider Overview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.handyman_rounded, color: Color(0xFF1B1464), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B1464),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking ID: $bookingIdStr',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Provided by $providerName',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Star Rating Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'How was your experience?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          iconSize: 38,
                          onPressed: () {
                            setState(() {
                              _rating = starIndex;
                            });
                          },
                          icon: Icon(
                            starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: starIndex <= _rating ? Colors.amber.shade600 : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _ratingLabel,
                        key: ValueKey(_rating),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _rating >= 4 ? Colors.green.shade700 : (_rating == 3 ? Colors.orange.shade700 : Colors.red.shade600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Tag Chips
              const Text(
                'What went well?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => _toggleTag(tag),
                    selectedColor: const Color(0xFF1B1464),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? const Color(0xFF1B1464) : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Detailed Comment Box
              const Text(
                'Add Detailed Review (Optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about the service, quality, or provider...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1B1464), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1464),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Submit Review',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

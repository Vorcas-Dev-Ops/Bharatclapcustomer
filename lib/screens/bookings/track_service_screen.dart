import 'package:flutter/material.dart';

class TrackServiceScreen extends StatefulWidget {
  const TrackServiceScreen({super.key});

  @override
  State<TrackServiceScreen> createState() => _TrackServiceScreenState();
}

class _TrackServiceScreenState extends State<TrackServiceScreen> {
  // 0: Accepted, 1: Assigned, 2: Arriving/Arrived, 3: Start Service, 4: Complete
  int _currentStep = 3; 
  bool _isArrived = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildProfessionalBanner(),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Service Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B1464),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildTimeline(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            'Track Service',
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

  Widget _buildProfessionalBanner() {
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Container(
                  width: 48,
                  height: 48,
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 14),
                        const SizedBox(width: 4),
                        const Text('4.8', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(width: 4),
                        Text('• Electrician', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '12 mins',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                  ),
                  Text(
                    'ETA',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isArrived ? Colors.yellow.shade100 : const Color(0xFFE8E8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isArrived ? Colors.yellow.shade700 : const Color(0xFF1B1464),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isArrived ? 'Arrived' : 'On the Way',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isArrived ? Colors.yellow.shade800 : const Color(0xFF1B1464),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView(
      children: [
        _buildTimelineItem(
          index: 0,
          title: 'Booking Accepted',
          subtitle: '10:30 AM',
          isLast: false,
        ),
        _buildTimelineItem(
          index: 1,
          title: 'Professional Assigned',
          subtitle: '10:45 AM',
          isLast: false,
        ),
        _buildTimelineItem(
          index: 2,
          title: _currentStep >= 2 && _isArrived ? 'Professional Arrived' : 'Arriving Soon',
          subtitle: _currentStep >= 2 && _isArrived ? '10:58 AM' : 'Professional will arrive soon',
          isLast: false,
        ),
        _buildTimelineItem(
          index: 3,
          title: 'Start Service',
          subtitle: 'Please provide the OTP to start service',
          isLast: false,
          child: _currentStep == 3
              ? Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '4 8 5 2',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1464),
                      letterSpacing: 8.0,
                    ),
                  ),
                )
              : null,
        ),
        _buildTimelineItem(
          index: 4,
          title: 'Service Complete',
          subtitle: _currentStep == 4 ? 'Please provide the OTP to complete service' : '',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required int index,
    required String title,
    required String subtitle,
    required bool isLast,
    Widget? child,
  }) {
    bool isCompleted = index < _currentStep;
    bool isActive = index == _currentStep;
    
    Color dotColor = isCompleted || isActive ? const Color(0xFF1B1464) : Colors.grey.shade300;
    Color lineColor = isCompleted ? const Color(0xFF1B1464) : Colors.grey.shade200;
    Color titleColor = isCompleted || isActive ? Colors.black87 : Colors.grey.shade400;
    Color subtitleColor = isCompleted || isActive ? Colors.grey.shade600 : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF1B1464) : (isActive ? Colors.white : Colors.grey.shade300),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? const Color(0xFF1B1464) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : (isActive
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B1464),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: isActive && child != null ? 120 : 50, // Longer line if there's an OTP box
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              if (child != null) child,
              if (!isLast) const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

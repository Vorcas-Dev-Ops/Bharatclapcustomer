import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ApiService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B1464)),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load profile details.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _loadUserProfile();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B1464),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildProfileCard(),
                          const SizedBox(height: 16),
                          _buildStatsRow(),
                          const SizedBox(height: 32),
                          _buildSectionHeader('MY ACTIVITY'),
                          const SizedBox(height: 12),
                          _buildActivityCard(),
                          const SizedBox(height: 32),
                          _buildSectionHeader('ACCOUNT'),
                          const SizedBox(height: 12),
                          _buildAccountCard(context),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final name = _userProfile?['name'] ?? 'Guest User';
    final phone = _userProfile?['phone'] ?? 'No Phone';
    final email = _userProfile?['email'] ?? 'No Email';
    final profileImage = _userProfile?['profile_image'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8FF), width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: (profileImage != null && profileImage.isNotEmpty)
                    ? NetworkImage(profileImage) as ImageProvider
                    : null,
                backgroundColor: const Color(0xFFE8E8FF),
                child: (profileImage == null || profileImage.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Color(0xFF1B1464))
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B1464),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildContactPill(Icons.phone_outlined, phone),
                  if (email.isNotEmpty && email != 'No Email') ...[
                    const SizedBox(width: 12),
                    _buildContactPill(Icons.email_outlined, email),
                  ],
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 16, color: Color(0xFF1B1464)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1B1464)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1B1464),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Bookings', '4')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Rewards', '0')),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8FF), width: 1),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B1464),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8FF), width: 1),
      ),
      child: Column(
        children: [
          _buildListTile(Icons.location_on_outlined, 'Saved Addresses'),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F8), indent: 20, endIndent: 20),
          _buildListTile(Icons.payments_outlined, 'Payment Methods'),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F8), indent: 20, endIndent: 20),
          _buildListTile(Icons.help_outline, 'Help & Support'),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8FF), width: 1),
      ),
      child: Column(
        children: [
          _buildListTile(Icons.description_outlined, 'Privacy Policy'),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F8), indent: 20, endIndent: 20),
          _buildListTile(
            Icons.logout,
            'Logout',
            isDestructive: true,
            hideChevron: false,
            onTap: () async {
              await ApiService.clearToken();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {bool isDestructive = false, bool hideChevron = false, VoidCallback? onTap}) {
    final color = isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF1B1464);
    final bgColor = isDestructive ? const Color(0xFFFFF0F0) : const Color(0xFFF3F4F8);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: isDestructive ? color : Colors.black87,
                ),
              ),
            ),
            if (!hideChevron)
              Icon(Icons.chevron_right, color: isDestructive ? color.withOpacity(0.5) : Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

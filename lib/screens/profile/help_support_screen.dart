import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  bool _hasDeletionRequest = false;
  String? _deletionScheduledDate;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _userProfile = profile;
          if (profile['deletion_requested_at'] != null || profile['deletion_scheduled_at'] != null) {
            _hasDeletionRequest = true;
            _deletionScheduledDate = profile['deletion_scheduled_at']?.toString().split('T').first;
          } else {
            _hasDeletionRequest = false;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExportData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.exportUserData();
      if (mounted) {
        if (res['success'] == true || res['status'] == 'success' || res['data'] != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.download_done_rounded, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Data Exported', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                'Your personal profile data, addresses, and booking history have been successfully compiled in compliance with DPDPA Data Portability guidelines.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16155D))),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to export user data'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Request Account Deletion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Under DPDPA Right to Erasure rules, requesting account deletion will start a 30-day cooling period.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              '• Your account will be scheduled for permanent anonymization in 30 days.\n'
              '• You can cancel your deletion request anytime during these 30 days.\n'
              '• You will be logged out of all active sessions immediately.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmAccountDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Request Deletion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountDeletion() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.requestAccountDeletion();
      if (mounted) {
        if (res['status'] == 'success' || res['success'] == true || res['message']?.toString().contains('successfully') == true) {
          await ApiService.clearToken();
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                    SizedBox(width: 10),
                    Text('Deletion Requested', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Text(
                  res['message'] ?? 'Account deletion requested successfully. Your account will be anonymized in 30 days.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16155D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to request account deletion'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelAccountDeletion() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.cancelAccountDeletion();
      if (mounted) {
        if (res['status'] == 'success' || res['success'] == true || res['message']?.toString().contains('cancelled') == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deletion request cancelled. Your account remains active!'), backgroundColor: Colors.green),
          );
          _fetchProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to cancel deletion request'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _makeCall(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Support Helpline: $phone'), backgroundColor: const Color(0xFF16155D)),
    );
  }

  void _sendEmail(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Support Email: $email'), backgroundColor: const Color(0xFF16155D)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF16155D), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Color(0xFF1C1F3E), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16155D)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Support Options Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16155D),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BharatClap Support Center',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Have questions about your booking or account? We are here to help 24/7.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _makeCall('+9118001234567'),
                                icon: const Icon(Icons.call, size: 16, color: Color(0xFF16155D)),
                                label: const Text('Call Us', style: TextStyle(color: Color(0xFF16155D), fontWeight: FontWeight.bold, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _sendEmail('support@bharatclap.com'),
                                icon: const Icon(Icons.email_outlined, size: 16, color: Colors.white),
                                label: const Text('Email Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white70, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // FAQs Section
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
                  ),
                  const SizedBox(height: 12),
                  _buildFaqTile('How do I cancel or reschedule my booking?', 'You can manage active bookings under the My Bookings tab. Select your booking to view options.'),
                  _buildFaqTile('When will my refund be processed?', 'Online payment refunds are processed back to your original payment method within 3-5 business days.'),
                  _buildFaqTile('Are BharatClap service professionals verified?', 'Yes, all professionals undergo background checks and identity verification before joining the platform.'),

                  const SizedBox(height: 24),

                  // Account Privacy & Data Rights (DPDPA Section)
                  const Text(
                    'Account & Data Privacy (DPDPA)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFFEFF1FE), shape: BoxShape.circle),
                            child: const Icon(Icons.download_outlined, color: Color(0xFF16155D), size: 20),
                          ),
                          title: const Text('Export My Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E))),
                          subtitle: const Text('Download copy of personal profile & history', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: _handleExportData,
                        ),
                        const Divider(height: 1),
                        if (_hasDeletionRequest)
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.orange.shade50,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.schedule, color: Colors.orange, size: 18),
                                    SizedBox(width: 8),
                                    Text('Account Deletion Requested', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Your account is scheduled for permanent anonymization on $_deletionScheduledDate.',
                                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _cancelAccountDeletion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade700,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Cancel Deletion Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          )
                        else
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFFFFF0F0), shape: BoxShape.circle),
                              child: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 20),
                            ),
                            title: const Text('Delete Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                            subtitle: const Text('Initiate 30-day cooling period for permanent erasure', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.red, size: 20),
                            onTap: _showDeleteAccountDialog,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildFaqTile(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1F3E))),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(content, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
        ],
      ),
    );
  }
}

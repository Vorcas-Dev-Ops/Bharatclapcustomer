import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/app_toast.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  const EditProfileScreen({super.key, this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _changePassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile?['name'] ?? '');
    _phoneController = TextEditingController(text: widget.userProfile?['phone'] ?? '');
    _emailController = TextEditingController(text: widget.userProfile?['email'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasExistingPassword {
    // The backend explicitly strips the password from the profile payload
    // and requires `currentPassword` for any password update.
    // Thus we always render the "Change Password" view and ask for Current Password.
    return true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_changePassword) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        AppToast.show(context, 'New passwords do not match', isError: true);
        return;
      }
    }

    setState(() => _isSaving = true);

    final res = await ApiService.updateUserProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      currentPassword: (_changePassword && _hasExistingPassword) ? _currentPasswordController.text : null,
      newPassword: _changePassword ? _newPasswordController.text : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (res['success'] == true) {
        AppToast.show(context, 'Profile updated successfully!');
        Navigator.pop(context, true);
      } else {
        AppToast.show(context, res['message'] ?? 'Failed to update profile', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = widget.userProfile?['profile_image'];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundImage: (profileImage != null && profileImage.toString().isNotEmpty)
                            ? NetworkImage(profileImage) as ImageProvider
                            : null,
                        backgroundColor: const Color(0xFFE8E8FF),
                        child: (profileImage == null || profileImage.toString().isEmpty)
                            ? const Icon(Icons.person, size: 48, color: Color(0xFF1B1464))
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Name field
                const Text('Full Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1B1464), size: 20),
                    hintText: 'Enter full name',
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B1464), width: 1.5)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone field
                const Text('Phone Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF1B1464), size: 20),
                    hintText: 'Enter phone number',
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B1464), width: 1.5)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email field
                const Text('Email Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1B1464), size: 20),
                    hintText: 'Enter email address',
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B1464), width: 1.5)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!val.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Password Toggle Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: _changePassword,
                      onExpansionChanged: (val) => setState(() => _changePassword = val),
                      leading: const Icon(Icons.lock_outline, color: Color(0xFF1B1464)),
                      title: Text(
                        _hasExistingPassword ? 'Change Password' : 'Add Password',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      subtitle: Text(
                        _changePassword
                            ? (_hasExistingPassword ? 'Updating login password' : 'Creating login password')
                            : (_hasExistingPassword ? 'Tap to update email password' : 'Tap to set up email password'),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(height: 8),

                              // Current Password (only if user already has a password)
                              if (_hasExistingPassword) ...[
                                const Text('Current Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _currentPasswordController,
                                  obscureText: _obscureCurrentPassword,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.lock_clock_outlined, color: Colors.grey, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                      onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                                    ),
                                    hintText: 'Enter current password',
                                    fillColor: const Color(0xFFFAFAFC),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                  validator: (val) {
                                    if (_changePassword && _hasExistingPassword && (val == null || val.isEmpty)) {
                                      return 'Current password is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],

                              // New Password / Set Password
                              Text(_hasExistingPassword ? 'New Password' : 'Password', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: _obscureNewPassword,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.key_outlined, color: Colors.grey, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                                  ),
                                  hintText: _hasExistingPassword ? 'Enter new password' : 'Create password (min 6 chars)',
                                  fillColor: const Color(0xFFFAFAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                ),
                                validator: (val) {
                                  if (_changePassword) {
                                    if (val == null || val.isEmpty) return 'Password is required';
                                    if (val.length < 6) return 'Minimum 6 characters required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Confirm Password
                              Text(_hasExistingPassword ? 'Confirm New Password' : 'Confirm Password', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.key_outlined, color: Colors.grey, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                  hintText: 'Re-enter password',
                                  fillColor: const Color(0xFFFAFAFC),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                ),
                                validator: (val) {
                                  if (_changePassword) {
                                    if (val != _newPasswordController.text) return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1464),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

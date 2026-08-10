import 'package:flutter/material.dart';
import '../address/add_address_screen.dart';
import '../../services/api_service.dart';

class BasicDetailsScreen extends StatefulWidget {
  final String phone;
  const BasicDetailsScreen({super.key, required this.phone});

  @override
  State<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends State<BasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer Not to say'];

  @override
  void initState() {
    super.initState();
    _numberController.text = widget.phone;
    _fetchExistingProfile();
  }

  Future<void> _fetchExistingProfile() async {
    try {
      final user = await ApiService.getUserProfile();
      if (user != null && mounted) {
        setState(() {
          if (user['name'] != null && user['name'].toString().isNotEmpty) {
            _nameController.text = user['name'].toString();
          }
          if (user['email'] != null && user['email'].toString().isNotEmpty) {
            _emailController.text = user['email'].toString();
          }
          if (user['phone'] != null && user['phone'].toString().isNotEmpty) {
            _numberController.text = user['phone'].toString();
          }
          if (user['gender'] != null && user['gender'].toString().isNotEmpty) {
            final genderStr = user['gender'].toString();
            if (_genders.contains(genderStr)) {
              _selectedGender = genderStr;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching existing customer profile: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final response = await ApiService.registerUser(
        widget.phone, 
        _nameController.text.trim(),
        _emailController.text.trim(),
        _selectedGender,
        _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (response['success'] == true) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AddAddressScreen()),
            (route) => false,
          );
        } else {
          String errorMsg = response['message'] ?? 'Failed to register';
          if (response['errors'] != null && response['errors'] is List && (response['errors'] as List).isNotEmpty) {
            final errList = (response['errors'] as List).map((e) => e['message']?.toString()).whereType<String>().toList();
            if (errList.isNotEmpty) {
              errorMsg = errList.join('\n');
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Basic Details',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1464),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please fill in your information to proceed.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1B1464)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number *',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1B1464)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mobile number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address *',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1B1464)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email address is required';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    helperText: 'Min 8 chars: uppercase, lowercase, number & special char',
                    helperMaxLines: 2,
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1B1464)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#^()_\-+=])[A-Za-z\d@$!%*?&#^()_\-+=]{8,}$');
                    if (!passwordRegex.hasMatch(value)) {
                      return 'Must include uppercase, lowercase, number & special char';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  items: _genders.map((String gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Gender (Optional)',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1B1464)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.white, size: 20),
                        ],
                      ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

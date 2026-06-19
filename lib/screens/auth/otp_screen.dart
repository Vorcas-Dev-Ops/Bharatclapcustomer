import 'package:flutter/material.dart';
import 'basic_details_screen.dart';
import '../home/home_screen.dart';
import '../../services/api_service.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;

  void _resendOtp() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    
    final response = await ApiService.sendOtp(widget.phone);
    
    if (mounted) {
      setState(() => _isResending = false);
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to resend OTP')),
        );
      }
    }
  }

  void _verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.verifyOtp(widget.phone, otp);

    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        final user = response['user'];
        if (user != null && user['_id'] == 'pending_verification') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BasicDetailsScreen(phone: widget.phone)),
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to verify OTP')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF4F6FC),
                ),
                child: Image.asset(
                  'assets/images/otp_illustration.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Verify your number',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B1464),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Enter the 6-digit code sent to your mobile number.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      onChanged: (value) => _onChanged(value, index),
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: _isResending ? null : _resendOtp,
                icon: _isResending 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, color: Colors.grey, size: 18),
                label: Text(
                  _isResending ? 'Resending...' : 'Resend OTP',
                  style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../../services/api_service.dart';

class AddressDetailsScreen extends StatefulWidget {
  final String? addressLine;
  final String? city;
  final String? state;
  final String? pincode;
  final String? district;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;

  const AddressDetailsScreen({
    super.key,
    this.addressLine,
    this.city,
    this.state,
    this.pincode,
    this.district,
    this.country,
    this.latitude,
    this.longitude,
    this.formattedAddress,
  });

  @override
  State<AddressDetailsScreen> createState() => _AddressDetailsScreenState();
}

class _AddressDetailsScreenState extends State<AddressDetailsScreen> {
  bool _useAccountDetails = true;
  String _selectedAddressType = 'Work';
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isLoading = false;
  String _userName = 'Loading...';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.addressLine ?? '';
    _cityController.text = widget.city ?? '';
    _stateController.text = widget.state ?? '';
    _pincodeController.text = widget.pincode ?? '';
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final user = await ApiService.getUserProfile();
    if (mounted && user != null) {
      setState(() {
        _userName = user['name'] ?? 'User';
        _userPhone = user['phone'] ?? '';
      });
    } else if (mounted) {
      setState(() {
        _userName = 'User';
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        _pincodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.addAddress({
      'address_type': _selectedAddressType,
      'label': _selectedAddressType,
      'house_no_building': _addressController.text.trim(),
      'address_line_1': widget.addressLine ?? 'Street Address',
      'area_locality': widget.addressLine ?? 'Locality',
      'city': _cityController.text.trim(),
      'district': widget.district ?? _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'country': widget.country ?? 'India',
      'pincode': _pincodeController.text.trim(),
      'latitude': widget.latitude ?? 0.0,
      'longitude': widget.longitude ?? 0.0,
      'location': {
        'type': 'Point',
        'coordinates': [widget.longitude ?? 0.0, widget.latitude ?? 0.0],
      },
      'formatted_address': widget.formattedAddress ?? '${_addressController.text.trim()}, ${widget.addressLine ?? ""}, ${_cityController.text.trim()}, ${_stateController.text.trim()}',
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to save address')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Address Details',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Delivery Details',
                style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: -2, offset: Offset(0, 4)),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.black87),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (widget.addressLine != null && widget.addressLine!.isNotEmpty)
                                ? widget.addressLine!
                                : 'P and T Layout, Horamavu',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (widget.city != null && widget.city!.isNotEmpty)
                                ? '${widget.city}, ${widget.state ?? ""}'
                                : 'Bengaluru, Karnataka',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back to map
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(color: Color(0xFF1B1464), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Address',
                style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: _buildInputDecoration('House no, floor, layout ect'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('City', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cityController,
                          decoration: _buildInputDecoration('City'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('State', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _stateController,
                          decoration: _buildInputDecoration('State'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Pincode', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('Pincode'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Receiver Details for this address',
                style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: -2, offset: Offset(0, 4)),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _useAccountDetails,
                        onChanged: (value) {
                          setState(() {
                            _useAccountDetails = value ?? true;
                          });
                        },
                        activeColor: const Color(0xFF1B1464),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Use my account details',
                            style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_userName${_userPhone.isNotEmpty ? ', $_userPhone' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Save address as',
                style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAddressTypeChip('Home', Icons.home_outlined),
                  _buildAddressTypeChip('Work', Icons.work_outline),
                  _buildAddressTypeChip('Other', Icons.near_me_outlined),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAddress,
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
                : const Text(
                    'Save Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
    );
  }

  Widget _buildAddressTypeChip(String label, IconData icon) {
    bool isSelected = _selectedAddressType == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddressType = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B1464) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF1B1464) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

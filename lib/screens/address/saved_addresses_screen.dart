import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'add_address_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;
  String _currentGpsAddress = 'Locating current location...';
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _getCurrentGpsLocation();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final addresses = await ApiService.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentGpsLocation() async {
    setState(() {
      _currentGpsAddress = 'Locating current location...';
      _isLocating = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentGpsAddress = 'Location permission denied';
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentGpsAddress = 'Location permission permanently denied';
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final apiKey = dotenv.env['NEXT_PUBLIC_GOOGLE_MAPS_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        setState(() {
          _currentGpsAddress = 'Google Maps API key missing';
          _isLocating = false;
        });
        return;
      }

      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final formattedAddress = data['results'][0]['formatted_address'] as String;
          if (mounted) {
            setState(() {
              _currentGpsAddress = formattedAddress;
              _isLocating = false;
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _currentGpsAddress = 'Failed to fetch current location address';
          _isLocating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentGpsAddress = 'Error locating: $e';
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _deleteAddress(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final response = await ApiService.deleteAddress(id);
      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address deleted successfully')),
          );
          _loadAddresses();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to delete address')),
          );
        }
      }
    }
  }

  Future<void> _setDefaultAddress(String id) async {
    setState(() => _isLoading = true);
    final response = await ApiService.setDefaultAddress(id);
    if (mounted) {
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default address updated successfully')),
        );
        _loadAddresses();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to update default address')),
        );
      }
    }
  }

  IconData _getAddressIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      case 'other':
      default:
        return Icons.near_me_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Addresses',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B1464)))
          : RefreshIndicator(
              onRefresh: () async {
                _loadAddresses();
                _getCurrentGpsLocation();
              },
              color: const Color(0xFF1B1464),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GPS Location Card
                    const Text(
                      'Current Location',
                      style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.my_location, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GPS Position',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                _isLocating
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                                      )
                                    : Text(
                                        _currentGpsAddress,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                                      ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                            onPressed: _getCurrentGpsLocation,
                            tooltip: 'Refresh GPS location',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Saved Addresses List Section
                    const Text(
                      'Saved Locations',
                      style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _addresses.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No saved addresses yet',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _addresses.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final address = _addresses[index];
                              final isDefault = address['is_default'] == true;
                              final typeLabel = address['address_type'] ?? 'Address';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDefault ? const Color(0xFF1B1464) : Colors.grey.shade200,
                                    width: isDefault ? 1.5 : 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getAddressIcon(address['address_type']),
                                          color: isDefault ? const Color(0xFF1B1464) : Colors.black54,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          typeLabel,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        if (isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B1464).withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1B1464),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          onPressed: () => _deleteAddress(address['_id']),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${address['house_no_building']}, ${address['address_line_1']}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    if (address['area_locality'] != null && address['area_locality'] != address['address_line_1']) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        address['area_locality'],
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      '${address['city']}, ${address['state']} - ${address['pincode']}',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                    if (!isDefault) ...[
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => _setDefaultAddress(address['_id']),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Set as Default',
                                            style: TextStyle(
                                              color: Color(0xFF1B1464),
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAddressScreen()),
                ).then((_) => _loadAddresses());
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add New Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1464),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

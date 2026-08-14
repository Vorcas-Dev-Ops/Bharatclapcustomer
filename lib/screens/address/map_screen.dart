import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'address_details_screen.dart';

class MapScreen extends StatefulWidget {
  final String? initialSearchQuery;
  const MapScreen({super.key, this.initialSearchQuery});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(13.0234, 77.6654); // Default to Horamavu, Bengaluru
  bool _isGeocoding = false;
  
  String _addressLine = 'P and T Layout, Horamavu';
  String _city = 'Bengaluru';
  String _state = 'Karnataka';
  String _pincode = '560043';
  String _district = 'Bengaluru';
  String _country = 'India';
  String _formattedAddress = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchLocation(widget.initialSearchQuery!);
      });
    } else {
      _getCurrentLocation();
    }
  }

  String get _apiKey {
    return dotenv.env['NEXT_PUBLIC_GOOGLE_MAPS_API_KEY'] ?? '';
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = newLatLng;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLatLng, zoom: 16),
        ),
      );

      _reverseGeocode(newLatLng);
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    if (_apiKey.isEmpty) {
      debugPrint("API Key is missing for reverse geocoding");
      return;
    }

    setState(() {
      _isGeocoding = true;
    });

    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final formattedAddress = result['formatted_address'] as String;
          
          String addressLine = '';
          String city = '';
          String state = '';
          String pincode = '';
          String district = '';
          String country = '';

          final addressComponents = result['address_components'] as List<dynamic>;
          
          for (var component in addressComponents) {
            final types = component['types'] as List<dynamic>;
            final longName = component['long_name'] as String;

            if (types.contains('postal_code')) {
              pincode = longName;
            } else if (types.contains('administrative_area_level_1')) {
              state = longName;
            } else if (types.contains('administrative_area_level_2')) {
              district = longName;
            } else if (types.contains('country')) {
              country = longName;
            } else if (types.contains('locality')) {
              city = longName;
            } else if (types.contains('sublocality_level_1') || types.contains('route') || types.contains('neighborhood')) {
              if (addressLine.isEmpty) {
                addressLine = longName;
              } else {
                addressLine = '$addressLine, $longName';
              }
            }
          }

          if (addressLine.isEmpty) {
            addressLine = formattedAddress.split(',').first;
          }

          setState(() {
            _addressLine = addressLine;
            _city = city.isNotEmpty ? city : 'Bengaluru';
            _state = state.isNotEmpty ? state : 'Karnataka';
            _pincode = pincode;
            _district = district.isNotEmpty ? district : (city.isNotEmpty ? city : 'Bengaluru');
            _country = country.isNotEmpty ? country : 'India';
            _formattedAddress = formattedAddress;
          });
        }
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    } finally {
      setState(() {
        _isGeocoding = false;
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty || _apiKey.isEmpty) return;

    setState(() {
      _isGeocoding = true;
    });

    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$_apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final lat = location['lat'] as double;
          final lng = location['lng'] as double;
          final newLatLng = LatLng(lat, lng);

          setState(() {
            _currentPosition = newLatLng;
          });

          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: newLatLng, zoom: 16),
            ),
          );

          _reverseGeocode(newLatLng);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location not found')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error searching location: $e");
    } finally {
      setState(() {
        _isGeocoding = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Real Interactive Google Map
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 16,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onCameraMove: (position) {
                  _currentPosition = position.target;
                },
                onCameraIdle: () {
                  _reverseGeocode(_currentPosition);
                },
              ),
            ),

            // Error banner if API Key missing or map loading issue
            if (_apiKey.isEmpty)
              Positioned(
                top: 90,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade800,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unable to load map details. Google Maps Error.',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Fixed Center Marker/Pin (Uber-style)
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 40),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 48,
                      color: Color(0xFF1B1464),
                    ),
                    Icon(
                      Icons.lens,
                      size: 8,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ),
            
            // Top Search Bar and Back Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (val) => _searchLocation(val),
                                decoration: const InputDecoration(
                                  hintText: 'Search location...',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward, color: Color(0xFF1B1464), size: 18),
                              onPressed: () => _searchLocation(_searchController.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Current Location Button
            Positioned(
              bottom: 220,
              left: 0,
              right: 0,
              child: Center(
                child: InkWell(
                  onTap: _getCurrentLocation,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Current Location',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Sheet Area
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF1B1464)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isGeocoding
                              ? const SizedBox(
                                  height: 40,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B1464)),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _addressLine,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_city, $_state',
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isGeocoding
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddressDetailsScreen(
                                      addressLine: _addressLine,
                                      city: _city,
                                      state: _state,
                                      pincode: _pincode,
                                      district: _district,
                                      country: _country,
                                      latitude: _currentPosition.latitude,
                                      longitude: _currentPosition.longitude,
                                      formattedAddress: _formattedAddress.isNotEmpty ? _formattedAddress : '$_addressLine, $_city, $_state $_pincode',
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B1464),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm and Proceed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'address_details_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
          // Background Map Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/map_placeholder.png',
              fit: BoxFit.cover,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          Text(
                            'Search location...',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'P and T Layout, Horamavu',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bengaluru, Karnataka',
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddressDetailsScreen()),
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

import 'package:flutter/material.dart';
import 'categories_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/api_service.dart';
import 'services_screen.dart';
import '../address/map_screen.dart';
import 'search_screen.dart';
import '../cart/cart_screen.dart';
import '../bookings/bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<dynamic> _apiCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final categories = await ApiService.getCategories();
    if (mounted) {
      setState(() {
        _apiCategories = categories;
      });
    }
  }

  String? _getCategoryId(String keyword) {
    if (_apiCategories.isEmpty) return null;
    for (var cat in _apiCategories) {
      String name = (cat['category_name'] ?? '').toLowerCase();
      if (name.contains(keyword.toLowerCase())) {
        return cat['_id'];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const CategoriesScreen();
      case 2:
        return const BookingsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 32),
              _buildCategoriesHeader(),
              const SizedBox(height: 16),
              _buildCategories(),
              const SizedBox(height: 32),
              _buildPopularServicesHeader(),
              const SizedBox(height: 16),
              _buildPopularServices(),
              const SizedBox(height: 32),
              _buildPromoBanner(),
              const SizedBox(height: 32),
              _buildRecentBookingsHeader(),
              const SizedBox(height: 16),
              _buildRecentBookings(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF1B1464)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('TC Palaya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Icon(Icons.keyboard_arrow_down, color: Color(0xFF1B1464)),
                    ],
                  ),
                  Text('Bangalore, Karnataka', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1B1464)),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B1464),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('4', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        readOnly: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
        },
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey.shade500),
          hintText: 'Search for services...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoriesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const Text('View All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B1464))),
      ],
    );
  }

  Widget _buildCategories() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryItem('Instant', Icons.bolt, null, 'Instant'),
        _buildCategoryItem('Cleaning\n& Pest', Icons.cleaning_services_outlined, _getCategoryId('clean'), 'Cleaning & Pest Control'),
        _buildCategoryItem('Womens\nSalon', Icons.face_retouching_natural, _getCategoryId('women'), 'Womens Salon'),
        _buildCategoryItem('Mens\nSalon', Icons.content_cut, _getCategoryId('men'), 'Mens Salon'),
      ],
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, String? categoryId, String fullCategoryName) {
    bool isInstant = title == 'Instant';
    return GestureDetector(
      onTap: () {
        if (categoryId != null || isInstant) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServicesScreen(
                categoryId: categoryId,
                categoryName: fullCategoryName,
              ),
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: isInstant ? Colors.green.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: isInstant ? Colors.green : const Color(0xFF1B1464), size: 28),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 75,
            child: Text(
              title, 
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12, 
                color: isInstant ? Colors.green : Colors.grey.shade800, 
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServicesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Popular Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const Text('See More', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B1464))),
      ],
    );
  }

  Widget _buildPopularServices() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildServiceCard('Full Home Repair', '4.8', '₹499', 'assets/images/service_repair.png'),
          const SizedBox(width: 16),
          _buildServiceCard('Premium Painting', '4.9', '₹2999', 'assets/images/service_painting.png'),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String rating, String price, String imagePath) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(imagePath, height: 110, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('From $price', style: const TextStyle(fontSize: 12, color: Color(0xFF1B1464), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1464),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background illustration image
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/promo_banner.png',
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Flash Sale', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(height: 12),
              const Text('Get 30% Off on\nDeep Cleaning', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B1464),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Book Now >', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsHeader() {
    return const Text('Recent Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildRecentBookings() {
    return Column(
      children: [
        _buildBookingCard('Kitchen Cleaning', '12 Oct, 10:30 AM', 'Rajesh K.', '4.8', Icons.water_drop_outlined),
        const SizedBox(height: 12),
        _buildBookingCard('TV Wall Mounting', '05 Oct, 02:00 PM', 'Amit S.', '4.2', Icons.tv),
      ],
    );
  }

  Widget _buildBookingCard(String title, String date, String by, String rating, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1B1464)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$date • by $by', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B1464),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(80, 36),
            ),
            child: const Text('Rebook', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B1464),
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

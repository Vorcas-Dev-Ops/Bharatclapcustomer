import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../cart/cart_screen.dart';

class BeautyServicesScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String gender;

  const BeautyServicesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.gender,
  });

  @override
  State<BeautyServicesScreen> createState() => _BeautyServicesScreenState();
}

class _BeautyServicesScreenState extends State<BeautyServicesScreen> {
  bool _isLoading = true;
  List<dynamic> _services = [];
  String _searchQuery = '';
  int _selectedFilterIndex = 1; // 1 represents 'All'

  List<Map<String, dynamic>> _filters = [];

  @override
  void initState() {
    super.initState();
    if (widget.gender == 'Men') {
      _filters = [
        {'icon': Icons.bolt, 'title': 'Instant', 'isInstant': true},
        {'icon': Icons.business, 'title': 'All', 'isInstant': false},
        {'icon': Icons.spa, 'title': 'Spa', 'isInstant': false},
        {'icon': Icons.content_cut, 'title': 'Hair Salon', 'isInstant': false},
      ];
    } else {
      _filters = [
        {'icon': Icons.bolt, 'title': 'Instant', 'isInstant': true},
        {'icon': Icons.business, 'title': 'All', 'isInstant': false},
        {'icon': Icons.spa, 'title': 'Spa', 'isInstant': false},
        {'icon': Icons.face_retouching_natural, 'title': 'Salon', 'isInstant': false},
        {'icon': Icons.content_cut, 'title': 'Hair cut', 'isInstant': false},
        {'icon': Icons.brush, 'title': 'Makeup', 'isInstant': false},
      ];
    }
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final subServices = await ApiService.getSubServicesByCategory(widget.categoryId);
      if (mounted) {
        setState(() {
          _services = subServices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load services: $e')),
        );
      }
    }
  }

  // Use dummy data if API returns empty, just to match the screenshot
  List<dynamic> get _displayServices {
    if (_services.isEmpty) {
      return [
        {
          '_id': 'dummy1',
          'title': 'Advanced Facial Treatment',
          'rating': '4.8',
          'time': '90 mins',
          'base_price': 1299,
          'image': '',
        },
        {
          '_id': 'dummy2',
          'title': 'Basic Cleanup',
          'rating': '4.8',
          'time': '45 mins',
          'base_price': 399,
          'image': '',
        },
        {
          '_id': 'dummy3',
          'title': 'Basic Facial',
          'rating': '4.8',
          'time': '60 mins',
          'base_price': 699,
          'image': '',
        },
        {
          '_id': 'dummy4',
          'title': 'Hair Wash & Blow Dry',
          'rating': '4.8',
          'time': '30 mins',
          'base_price': 499,
          'image': 'assets/images/beauty_placeholder.png', // Mock image
        },
        {
          '_id': 'dummy5',
          'title': 'Haircut',
          'rating': '4.8',
          'time': '30 mins',
          'base_price': 399,
          'image': 'assets/images/beauty_placeholder.png', // Mock image
        },
      ];
    }
    
    // If we have real data, filter it by search query
    return _services.where((s) {
      final title = (s['title'] ?? '').toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFiltersRow(),
            Expanded(
              child: (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) 
                  ? _buildServiceList() 
                  : _buildGroupedView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.home_outlined, size: 24, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                widget.categoryName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search for any service...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 20, bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilterIndex == index;
          final isInstant = filter['isInstant'] == true;

          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 72,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1B1464) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    filter['icon'],
                    color: isSelected ? Colors.white : (isInstant ? Colors.green.shade600 : Colors.grey.shade600),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filter['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : (isInstant ? Colors.green.shade600 : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B1464)));
    }

    final services = _displayServices;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(services[index]);
      },
    );
  }

  Widget _buildServiceCard(dynamic service) {
    String title = service['title'] ?? 'Unknown Service';
    String rating = service['rating']?.toString() ?? '4.8';
    String time = service['time']?.toString() ?? '45 mins';
    int price = service['base_price'] ?? 0;
    String imagePath = service['image'] ?? '';

    bool hasImage = imagePath.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imagePath.startsWith('http')
                  ? Image.network(
                      imagePath,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : Image.asset(
                      imagePath,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade500, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1464),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B1464),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 80,
      width: 80,
      color: Colors.grey.shade100,
      child: Icon(Icons.image, color: Colors.grey.shade400),
    );
  }

  Widget _buildGroupedView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildGroupCard(
          title: 'Premium',
          description: 'Relaxing beauty treatments to refresh your body and mind.',
          rating: '4.2',
          imagePath: 'assets/images/premium_beauty.png',
        ),
        const SizedBox(height: 20),
        _buildGroupCard(
          title: 'Luxury',
          description: 'Indulgent experiences with luxury therapies and enhanced comfort.',
          rating: '4.8',
          imagePath: 'assets/images/luxury_beauty.png',
        ),
      ],
    );
  }

  Widget _buildGroupCard({
    required String title,
    required String description,
    required String rating,
    required String imagePath,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.asset(
                  imagePath,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.spa, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B1464),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B1464),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF1B1464)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

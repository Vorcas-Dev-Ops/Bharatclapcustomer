import 'package:flutter/material.dart';
import 'service_details_screen.dart';
import '../../services/api_service.dart';

class ServicesScreen extends StatefulWidget {
  final String? categoryId;
  final String categoryName;

  const ServicesScreen({super.key, this.categoryId, this.categoryName = 'Services'});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  int _selectedTabIndex = 1;
  bool _isLoading = true;

  List<_ServiceCategory> _categories = [
    _ServiceCategory('Instant', Icons.bolt, isSpecial: true),
    _ServiceCategory('All', Icons.home_work_outlined),
  ];

  List<_ServiceItem> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.categoryId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    final servicesData = await ApiService.getServices(widget.categoryId!);
    if (mounted) {
      setState(() {
        _categories = [
          _ServiceCategory('Instant', Icons.bolt, isSpecial: true),
          _ServiceCategory('All', Icons.home_work_outlined),
        ];
        
        for (var service in servicesData) {
          _categories.add(_ServiceCategory(service['service_name'] ?? 'Unknown', Icons.electrical_services_outlined));
        }

        _services = servicesData.map((s) => _ServiceItem(
          title: s['service_name'] ?? 'Unknown',
          rating: (s['avg_rating'] ?? 4.8).toString(),
          time: s['duration']?.toString() ?? '45',
          price: '₹${s['base_price'] ?? 199}',
          imagePath: s['images'] != null && s['images'].isNotEmpty ? s['images'][0] : 'assets/images/switch.png',
        )).toList().cast<_ServiceItem>();
        
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: _buildHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 20),
            _buildTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildServiceList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.home_work_outlined, color: Colors.black87, size: 24),
            const SizedBox(width: 8),
            Text(
              widget.categoryName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Stack(
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
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text('Search for any service...', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          int idx = entry.key;
          var category = entry.value;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _buildTab(idx, category),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTab(int index, _ServiceCategory category) {
    bool isSelected = _selectedTabIndex == index;
    bool isInstant = category.isSpecial;

    Color bgColor = Colors.transparent;
    Color contentColor = Colors.grey.shade600;

    if (isSelected) {
      bgColor = isInstant ? Colors.green : const Color(0xFF1B1464);
      contentColor = Colors.white;
    } else if (isInstant) {
      contentColor = Colors.green;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: contentColor, size: 28),
            const SizedBox(height: 6),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: contentColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B1464)));
    }
    
    if (_services.isEmpty) {
      return const Center(child: Text("No services found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(context, _services[index]);
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, _ServiceItem service) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(
              title: service.title,
              price: service.price,
              rating: service.rating,
              time: service.time,
              imagePath: service.imagePath,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              service.imagePath,
              height: 90,
              width: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 90,
                  width: 90,
                  color: Colors.grey.shade100,
                  child: Icon(Icons.image, color: Colors.grey.shade400),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        service.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          service.rating,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (service.time != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.green, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        '${service.time} mins',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      service.price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B1464),
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Color(0xFF1B1464),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
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
    ),
  );
}
}

class _ServiceCategory {
  final String name;
  final IconData icon;
  final bool isSpecial;

  _ServiceCategory(this.name, this.icon, {this.isSpecial = false});
}

class _ServiceItem {
  final String title;
  final String rating;
  final String? time;
  final String price;
  final String imagePath;

  _ServiceItem({
    required this.title,
    required this.rating,
    this.time,
    required this.price,
    required this.imagePath,
  });
}

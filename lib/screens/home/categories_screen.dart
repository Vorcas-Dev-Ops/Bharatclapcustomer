import 'package:flutter/material.dart';
import 'services_screen.dart';
import 'beauty_services_screen.dart';
import '../../services/api_service.dart';
import '../cart/cart_screen.dart';
import '../../providers/cart_state.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<dynamic> _apiCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final categories = await ApiService.getCategories();
    if (mounted) {
      setState(() {
        _apiCategories = categories.reversed.toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCategories() async {
    await _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshCategories,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                _buildCategoriesPageView(context),
                const SizedBox(height: 16),
                _buildPageIndicator(),
                const SizedBox(height: 32),
                _buildMostBookedHeader(),
                const SizedBox(height: 16),
                _buildMostBookedServices(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Service Categories',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B1464),
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
                  child: ValueListenableBuilder<int>(
                    valueListenable: CartState.cartItemCount,
                    builder: (context, count, child) {
                      if (count == 0) return const SizedBox.shrink();
                      return Text(
                        '$count', 
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                      );
                    },
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildCategoriesPageView(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF1B1464))),
      );
    }
    
    if (_apiCategories.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No categories found")),
      );
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = (screenWidth - 40 - 16) / 2; // 40 for horizontal padding, 16 for crossAxisSpacing
    double cardHeight = cardWidth / 0.95; // aspect ratio is 0.95 to give comfortable height
    double pageViewHeight = (cardHeight * 2) + 16 + 10; // 2 rows, 16 mainAxisSpacing, 10 extra padding

    List<List<dynamic>> categoryPages = [];
    for (var i = 0; i < _apiCategories.length; i += 4) {
      categoryPages.add(_apiCategories.sublist(i, i + 4 > _apiCategories.length ? _apiCategories.length : i + 4));
    }

    return SizedBox(
      height: pageViewHeight,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: categoryPages.map((pageData) => _buildCategoryPage(context, pageData)).toList(),
      ),
    );
  }

  Widget _buildCategoryPage(BuildContext context, List<dynamic> categories) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _buildCategoryCard(context, categories[index]);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, dynamic data) {
    String title = data['category_name'] ?? 'Unknown';
    String subtitle = data['description'] ?? '';
    String iconUrl = data['icon'] ?? '';

    return GestureDetector(
      onTap: () {
        if (data['requiresGenderSelection'] == true) {
          _showMenWomenDialog(context, data['_id'], title);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ServicesScreen(
              categoryId: data['_id'],
              categoryName: title,
            )),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8E8FF), width: 1.2),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: iconUrl.isNotEmpty 
                ? Image.network(iconUrl, width: 24, height: 24, errorBuilder: (_,__,___) => const Icon(Icons.category, color: Color(0xFF1B1464), size: 24))
                : const Icon(Icons.category, color: Color(0xFF1B1464), size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    if (_isLoading || _apiCategories.isEmpty) return const SizedBox.shrink();

    int totalPages = (_apiCategories.length / 4).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        bool isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1B1464) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildMostBookedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Most Booked Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Text(
          'See More',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B1464),
          ),
        ),
      ],
    );
  }

  Widget _buildMostBookedServices() {
    return SizedBox(
      height: 250,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildMostBookedCard('AC Repair', '4.8', '₹499', 'assets/images/service_repair.png'),
          const SizedBox(width: 16),
          _buildMostBookedCard('Fan Replacement', '4.8', '₹499', 'assets/images/service_repair.png'), // Will replace image path later
        ],
      ),
    );
  }

  Widget _buildMostBookedCard(String title, String rating, String price, String imagePath) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              imagePath,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                 return Container(
                   height: 120,
                   width: double.infinity,
                   color: Colors.grey.shade200,
                   child: const Icon(Icons.image, color: Colors.grey),
                 );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.green.shade600, size: 12),
                          const SizedBox(width: 2),
                          Text(rating, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B1464))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text('From $price', style: const TextStyle(fontSize: 13, color: Color(0xFF1B1464), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMenWomenDialog(BuildContext context, String categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGenderOption(context, 'Men', categoryId, categoryName),
                    _buildGenderOption(context, 'Women', categoryId, categoryName),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderOption(BuildContext context, String gender, String categoryId, String categoryName) {
    String imagePath = gender == 'Men' ? 'assets/images/men_icon.png' : 'assets/images/women_icon.png';
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // close dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BeautyServicesScreen(
              categoryId: categoryId,
              categoryName: '$categoryName - $gender',
              gender: gender,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            gender,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

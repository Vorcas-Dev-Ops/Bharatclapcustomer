import 'package:flutter/material.dart';
import 'categories_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/api_service.dart';
import 'services_screen.dart';
import 'beauty_services_screen.dart';
import '../address/map_screen.dart';
import '../address/add_address_screen.dart';
import 'search_screen.dart';
import '../cart/cart_screen.dart';
import '../bookings/bookings_screen.dart';
import '../../providers/cart_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<dynamic> _apiCategories = [];
  List<dynamic> _apiBanners = [];
  List<dynamic> _apiPopularServices = [];
  List<dynamic> _apiRecentBookings = [];
  Map<String, dynamic>? _currentAddress;
  List<dynamic> _addresses = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAddress();
    _fetchBanners();
    _fetchPopularServices();
    _fetchRecentBookings();
  }

  Future<void> _fetchRecentBookings() async {
    final bookings = await ApiService.getMyBookings();
    if (mounted) {
      setState(() {
        _apiRecentBookings = bookings;
      });
    }
  }

  Future<void> _fetchPopularServices() async {
    final services = await ApiService.getPopularServices();
    if (mounted) {
      setState(() {
        _apiPopularServices = services;
      });
    }
  }

  Future<void> _fetchBanners() async {
    final banners = await ApiService.getBanners();
    if (mounted) {
      setState(() {
        _apiBanners = banners;
      });
    }
  }

  Future<void> _fetchAddress() async {
    final addresses = await ApiService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = addresses;
        _currentAddress = addresses.firstWhere(
          (a) => a['is_default'] == true,
          orElse: () => addresses.isNotEmpty ? addresses.first : null,
        );
      });
    }
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

  Future<void> _refreshHome() async {
    await Future.wait([
      _fetchCategories(),
      _fetchAddress(),
      _fetchBanners(),
      _fetchPopularServices(),
      _fetchRecentBookings(),
    ]);
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshHome,
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
                if (_apiRecentBookings.isNotEmpty) ...[
                  _buildRecentBookingsHeader(),
                  const SizedBox(height: 16),
                  _buildRecentBookings(),
                  const SizedBox(height: 32),
                ],
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
        GestureDetector(
          onTap: () {
            if (_currentAddress == null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddAddressScreen()),
              ).then((_) => _fetchAddress());
            } else {
              _showAddressSelector();
            }
          },
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF1B1464)),
              const SizedBox(width: 8),
              _currentAddress == null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1464).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1B1464).withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Color(0xFF1B1464), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Add Address',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B1464),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _currentAddress?['area_locality'] ?? _currentAddress?['address_line_1'] ?? 'Saved Address',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1B1464)),
                          ],
                        ),
                        Text(
                          '${_currentAddress?['city'] ?? ''}, ${_currentAddress?['state'] ?? ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
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

  void _showAddressSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B1464),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: _addresses.isEmpty
                          ? const Center(
                              child: Text(
                                'No saved addresses found.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _addresses.length,
                              separatorBuilder: (context, index) => const Divider(height: 16),
                              itemBuilder: (context, index) {
                                final address = _addresses[index];
                                final isSelected = _currentAddress?['_id'] == address['_id'];

                                return InkWell(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    setState(() => _currentAddress = address);
                                    await ApiService.setDefaultAddress(address['_id']);
                                    _fetchAddress();
                                  },
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        address['address_type']?.toLowerCase() == 'home'
                                            ? Icons.home_outlined
                                            : address['address_type']?.toLowerCase() == 'work'
                                                ? Icons.work_outline
                                                : Icons.near_me_outlined,
                                        color: isSelected ? const Color(0xFF1B1464) : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              address['address_type'] ?? 'Address',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? const Color(0xFF1B1464) : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${address['house_no_building']}, ${address['address_line_1']}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                            ),
                                            Text(
                                              '${address['city']}, ${address['state']} - ${address['pincode']}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF1B1464),
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddAddressScreen()),
                          ).then((_) => _fetchAddress());
                        },
                        icon: const Icon(Icons.add, color: Color(0xFF1B1464)),
                        label: const Text(
                          'Add New Address',
                          style: TextStyle(
                            color: Color(0xFF1B1464),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1B1464)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
        GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = 1;
            });
          },
          child: const Text('View All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B1464))),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    List<Widget> categoryWidgets = [];
    
    categoryWidgets.add(_buildCategoryItem('Instant', Icons.bolt, null, 'Instant'));

    Set<String> usedCategoryIds = {};

    bool tryAddCategory(String keyword, String defaultTitle, IconData defaultIcon) {
      String? id = _getCategoryId(keyword);
      if (id != null) {
        usedCategoryIds.add(id);
        categoryWidgets.add(_buildCategoryItem(defaultTitle, defaultIcon, id, defaultTitle.replaceAll('\n', ' ')));
        return true;
      }
      return false;
    }

    bool hasClean = tryAddCategory('clean', 'Cleaning\n& Pest', Icons.cleaning_services_outlined);
    bool hasWomen = tryAddCategory('beauty', 'Womens\nSalon', Icons.face_retouching_natural);
    bool hasMen = tryAddCategory('beauty', 'Mens\nSalon', Icons.content_cut);

    int missingCount = 3 - (hasClean ? 1 : 0) - (hasWomen ? 1 : 0) - (hasMen ? 1 : 0);
    
    if (missingCount > 0) {
      for (var cat in _apiCategories) {
        String id = cat['_id'];
        if (!usedCategoryIds.contains(id)) {
          String name = cat['category_name'] ?? 'Category';
          String displayName = name;
          if (displayName.length > 10 && displayName.contains(' ')) {
            displayName = displayName.replaceFirst(' ', '\n');
          }
          categoryWidgets.add(_buildCategoryItem(displayName, Icons.category_outlined, id, name));
          usedCategoryIds.add(id);
          missingCount--;
          if (missingCount == 0) break;
        }
      }
    }

    // If there are still missing spots and not enough categories, just pad with empty space
    while (missingCount > 0) {
      categoryWidgets.add(const SizedBox(width: 65));
      missingCount--;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryWidgets,
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, String? categoryId, String fullCategoryName) {
    bool isInstant = title == 'Instant';
    return GestureDetector(
      onTap: () {
        if (title.contains('Womens')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BeautyServicesScreen(
                categoryId: categoryId ?? _getCategoryId('beauty') ?? _getCategoryId('salon') ?? '',
                categoryName: 'Womens Salon',
                gender: 'Women',
              ),
            ),
          );
        } else if (title.contains('Mens')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BeautyServicesScreen(
                categoryId: categoryId ?? _getCategoryId('beauty') ?? _getCategoryId('salon') ?? '',
                categoryName: 'Mens Salon',
                gender: 'Men',
              ),
            ),
          );
        } else if (categoryId != null || isInstant) {
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
    if (_apiPopularServices.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _apiPopularServices.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final service = _apiPopularServices[index];
          String title = service['service_name'] ?? 'Service';
          String rating = (service['avg_rating'] ?? 0.0).toString();
          String price = '₹${service['base_price'] ?? 0}';
          
          String? imageUrl = service['image'] as String?;
          if (imageUrl == null || imageUrl.isEmpty) {
            if (service['images'] != null && service['images'].isNotEmpty) {
              imageUrl = service['images'][0];
            }
          }
          
          String imagePath = (imageUrl != null && imageUrl.isNotEmpty) 
              ? imageUrl 
              : 'assets/images/service_repair.png';
          
          return _buildServiceCard(title, rating, price, imagePath);
        },
      ),
    );
  }

  Widget _buildServiceCard(String title, String rating, String price, String imagePath) {
    bool isNetwork = imagePath.startsWith('http');
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
            child: isNetwork 
                ? Image.network(imagePath, height: 110, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 110, color: Colors.grey.shade200))
                : Image.asset(imagePath, height: 110, width: double.infinity, fit: BoxFit.cover),
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
    if (_apiBanners.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: _apiBanners.asMap().entries.map((entry) {
          final isLast = entry.key == _apiBanners.length - 1;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 16.0),
            child: _buildBannerItem(entry.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBannerItem(dynamic banner) {
    final title = banner['title'] ?? 'Get 30% Off on\nDeep Cleaning';
    final subtitle = banner['subtitle'] ?? 'Flash Sale';
    final buttonText = banner['button_text'] ?? 'Book Now >';
    final imageUrl = banner['image_url'];

    return Container(
      width: MediaQuery.of(context).size.width - 40,
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1464),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background illustration image
          if (imageUrl != null && imageUrl.toString().isNotEmpty)
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.8,
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/promo_banner.png',
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else
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
              if (subtitle.toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              if (subtitle.toString().isNotEmpty)
                const SizedBox(height: 12),
              Text(
                title, 
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigation can be handled based on redirect_type
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B1464),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      children: _apiRecentBookings.map((booking) {
        String title = 'Service';
        if (booking['subservice_id'] != null && booking['subservice_id']['subservice_name'] != null) {
          title = booking['subservice_id']['subservice_name'];
        } else if (booking['variant_name'] != null) {
          title = booking['variant_name'];
        }
        
        String dateStr = '';
        if (booking['scheduled_at'] != null) {
          DateTime dt = DateTime.parse(booking['scheduled_at']).toLocal();
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          String month = months[dt.month - 1];
          String hr = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
          String min = dt.minute.toString().padLeft(2, '0');
          String amPm = dt.hour >= 12 ? 'PM' : 'AM';
          dateStr = '${dt.day.toString().padLeft(2, '0')} $month, $hr:$min $amPm';
        }
        
        String byStr = 'Pending Assignment';
        if (booking['provider_id'] != null && booking['provider_id']['user_id'] != null) {
          byStr = booking['provider_id']['user_id']['name'] ?? 'Provider';
        }
        
        String rating = '0.0';
        if (booking['provider_id'] != null && booking['provider_id']['rating'] != null) {
          rating = booking['provider_id']['rating'].toString();
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildBookingCard(title, dateStr, byStr, rating, Icons.design_services),
        );
      }).toList(),
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

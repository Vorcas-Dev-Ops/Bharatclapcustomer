import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'service_details_screen.dart';
import 'categories_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/api_service.dart';
import 'services_screen.dart';
import 'beauty_services_screen.dart';
import '../address/add_address_screen.dart';
import 'search_screen.dart';
import '../cart/cart_screen.dart';
import '../bookings/bookings_screen.dart';
import '../bookings/booking_details_screen.dart';
import '../notifications_screen.dart';
import '../../services/notification_service.dart';
import '../../services/notification_sync_service.dart';
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
  StreamSubscription<String>? _notificationSub;

  @override
  void initState() {
    super.initState();
    NotificationSyncService.startSync();
    _notificationSub = NotificationService.selectNotificationStream.stream.listen((payload) {
      _handleNotificationClick(payload);
    });
    _fetchCategories();
    _fetchAddress();
    _fetchBanners();
    _fetchPopularServices();
    _fetchRecentBookings();
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    NotificationSyncService.stopSync();
    super.dispose();
  }

  void _handleNotificationClick(String payload) {
    try {
      Map<String, dynamic> data = {};
      if (payload.startsWith('{')) {
        data = jsonDecode(payload);
      }
      final bookingId = data['booking_id'] ?? data['bookingId'] ?? data['booking'];
      if (bookingId != null && bookingId.toString().isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailsScreen(bookingId: bookingId.toString()),
          ),
        );
      } else if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      }
    }
  }

  Future<void> _fetchRecentBookings() async {
    final bookings = await ApiService.getMyBookings();
    if (mounted) {
      setState(() {
        _apiRecentBookings = bookings.take(5).toList();
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Color(0xFF1B1464),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Leave BharathClap?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1464),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to exit the app?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(color: Color(0xFF1B1464)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Stay',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B1464),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            backgroundColor: const Color(0xFF1B1464),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Exit',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        if (shouldExit == true && context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
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
      children: [
        Expanded(
          child: GestureDetector(
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
                Expanded(
                  child: _currentAddress == null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
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
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _currentAddress?['area_locality'] ?? _currentAddress?['address_line_1'] ?? 'Saved Address',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1B1464)),
                              ],
                            ),
                            Text(
                              '${_currentAddress?['city'] ?? ''}, ${_currentAddress?['state'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        // Notification Bell Icon with dynamic red dot indicator
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            ).then((_) => NotificationSyncService.fetchAndUpdate());
          },
          child: ValueListenableBuilder<int>(
            valueListenable: NotificationSyncService.unreadCountNotifier,
            builder: (context, unreadCount, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_outlined, color: Color(0xFF1B1464)),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 12),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: IgnorePointer(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              icon: Icon(Icons.search, color: Colors.grey.shade500),
              hintText: 'Search for services...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
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
        String? id = cat['_id']?.toString() ?? cat['id']?.toString();
        if (id != null && id.isNotEmpty && !usedCategoryIds.contains(id)) {
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
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          child: const Text('See More', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B1464))),
        ),
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
          return _buildServiceCard(service);
        },
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    String title = service['name'] ?? service['subservice_name'] ?? service['service_name'] ?? service['title'] ?? 'Service';
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

    String? categoryId;
    if (service['category_id'] is Map) {
      categoryId = service['category_id']['_id'];
    } else if (service['category_id'] is String) {
      categoryId = service['category_id'];
    }

    bool isNetwork = imagePath.startsWith('http');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(
              subserviceId: service['_id'],
              categoryId: categoryId,
              title: title,
              price: price,
              rating: rating,
              time: service['duration']?.toString() ?? '45',
              imagePath: imagePath,
              description: service['description'],
            ),
          ),
        );
      },
      child: Container(
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

    return GestureDetector(
      onTap: () => _handleBannerTap(banner),
      child: Container(
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
                  onPressed: () => _handleBannerTap(banner),
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
      ),
    );
  }

  void _handleBannerTap(dynamic banner) {
    final title = (banner['title'] ?? '').toString().toLowerCase();
    final subtitle = (banner['subtitle'] ?? '').toString().toLowerCase();
    final redirectType = banner['redirect_type']?.toString();
    final redirectId = banner['redirect_id']?.toString();

    if (redirectType == 'category' && redirectId != null && redirectId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServicesScreen(
            categoryId: redirectId,
            categoryName: banner['title'] ?? 'Services',
          ),
        ),
      );
      return;
    } else if (redirectType == 'service' && redirectId != null && redirectId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceDetailsScreen(
            subserviceId: redirectId,
            title: banner['title'] ?? 'Service',
            price: '₹999',
            rating: '4.8',
            imagePath: banner['image_url'] ?? 'assets/images/service_repair.png',
          ),
        ),
      );
      return;
    }

    if (title.contains('loan') || title.contains('borrow') || subtitle.contains('loan') || (title.contains('pay') && title.contains('help'))) {
      final loanCatId = _getCategoryId('loan') ?? _getCategoryId('finance') ?? _getCategoryId('business');
      if (loanCatId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServicesScreen(
              categoryId: loanCatId,
              categoryName: 'Business & Service Loans',
            ),
          ),
        );
      } else {
        _showLoanModal();
      }
    } else if (title.contains('clean')) {
      final cleanCatId = _getCategoryId('clean');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServicesScreen(
            categoryId: cleanCatId,
            categoryName: 'Cleaning & Pest',
          ),
        ),
      );
    } else if (title.contains('women') || title.contains('beauty')) {
      final beautyCatId = _getCategoryId('beauty') ?? _getCategoryId('salon');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BeautyServicesScreen(
            categoryId: beautyCatId ?? '',
            categoryName: 'Womens Salon',
            gender: 'Women',
          ),
        ),
      );
    } else {
      setState(() {
        _currentIndex = 1;
      });
    }
  }

  void _showLoanModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF1B1464), size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Instant Service Loan',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1464).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1B1464).withOpacity(0.15)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flexible Payment Options',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B1464)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Split payments for high-value services into small, easy monthly installments starting at 0% interest for eligible accounts.',
                      style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Features & Benefits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildLoanFeature(Icons.flash_on_outlined, 'Instant Approval', 'Get approved within minutes with minimal documentation.'),
              const SizedBox(height: 10),
              _buildLoanFeature(Icons.calendar_month_outlined, 'Flexible Tenure', 'Choose between 3, 6, 12, or 24 months EMI.'),
              const SizedBox(height: 10),
              _buildLoanFeature(Icons.verified_user_outlined, 'Zero Hidden Charges', 'Transparent processing with no extra fee.'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final loanCatId = _getCategoryId('loan') ?? _getCategoryId('finance');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServicesScreen(
                          categoryId: loanCatId,
                          categoryName: 'Business Loan & Financing',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1464),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Apply Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanFeature(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1B1464), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBookingsHeader() {
    return const Text('Recent Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildRecentBookings() {
    return Column(
      children: _apiRecentBookings.take(5).map((booking) {
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

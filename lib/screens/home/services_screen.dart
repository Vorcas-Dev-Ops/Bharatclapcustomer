import 'package:flutter/material.dart';
import 'service_details_screen.dart';
import '../../services/api_service.dart';
import '../cart/cart_screen.dart';
import '../../providers/cart_state.dart';
import '../auth/login_screen.dart';

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
  List<_ServiceItem> _allSubServices = [];
  Map<String, dynamic>? _currentAddress;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
    _fetchData();
  }

  Future<void> _fetchAddress() async {
    final addresses = await ApiService.getAddresses();
    if (mounted && addresses.isNotEmpty) {
      setState(() {
        _currentAddress = addresses.first;
      });
    }
  }

  Future<void> _fetchData() async {
    final catId = widget.categoryId;
    final servicesData = await ApiService.getServices(catId);
    final subServicesData = await ApiService.getSubServicesByCategory(catId);

    if (mounted) {
      setState(() {
        _categories = [
          _ServiceCategory('Instant', Icons.bolt, isSpecial: true),
          _ServiceCategory('All', Icons.home_work_outlined),
        ];
        
        for (var service in servicesData) {
          _categories.add(_ServiceCategory(
            service['service_name'] ?? 'Unknown',
            Icons.electrical_services_outlined,
            imagePath: _getCategoryImagePath(service['service_name'] ?? ''),
            serviceId: service['_id'],
          ));
        }

        _allSubServices = subServicesData.map((ss) {
          String? sid;
          if (ss['service_id'] is Map) {
            sid = ss['service_id']['_id'];
          } else {
            sid = ss['service_id'];
          }
          return _ServiceItem(
            title: ss['subservice_name'] ?? 'Unknown',
            rating: (ss['avg_rating'] ?? 4.8).toString(),
            time: ss['duration']?.toString() ?? '45',
            price: '₹${ss['base_price'] ?? 199}',
            imagePath: ss['image'] != null && ss['image'].toString().isNotEmpty ? ss['image'] : 'assets/images/switch.png',
            serviceId: sid,
            subserviceId: ss['_id'],
            categoryId: widget.categoryId,
            description: ss['description'],
          );
        }).toList().cast<_ServiceItem>();
        
        _services = List.from(_allSubServices);
        
        _isLoading = false;
      });
    }
  }

  String? _getCategoryImagePath(String categoryName) {
    String lowerName = categoryName.toLowerCase();
    String widgetCategory = widget.categoryName.toLowerCase();

    // CCTV & Smart Devices categories
    if (widgetCategory.contains('cctv') || widgetCategory.contains('smart')) {
      String cctvPath = 'assets/catogries/cctv';
      if (lowerName.contains('lock') || lowerName.contains('smart')) return '$cctvPath/smartlock.png';
      if (lowerName.contains('camera') || lowerName.contains('repair')) return '$cctvPath/camerarepair.png';
      if (lowerName.contains('cctv') || lowerName.contains('install')) return '$cctvPath/cctvinstall.png';
      if (lowerName.contains('door') || lowerName.contains('video')) return '$cctvPath/videodoor.png';
    }

    // Vehicle categories
    if (widgetCategory.contains('vehicle') || widgetCategory.contains('car') || widgetCategory.contains('bike')) {
      String vehiclePath = 'assets/catogries/vehicle';
      if (lowerName.contains('interior') || lowerName.contains('clean')) return '$vehiclePath/interiorclean.png';
      if (lowerName.contains('car') || lowerName.contains('wash')) return '$vehiclePath/carwash.png';
      if (lowerName.contains('bike') || lowerName.contains('service')) return '$vehiclePath/bikeservice.png';
    }

    // Loan categories
    if (widgetCategory.contains('loan') || widgetCategory.contains('finance')) {
      String loanPath = 'assets/catogries/loan';
      if (lowerName.contains('personal')) return '$loanPath/personal.png';
      if (lowerName.contains('home')) return '$loanPath/home.png';
      if (lowerName.contains('business')) return '$loanPath/business.png';
    }
    
    // Electrician categories
    String elecPath = 'assets/catogries/Electrician';
    if (lowerName.contains('switch') || lowerName.contains('socket')) {
      return '$elecPath/socket.png';
    } else if (lowerName.contains('fan')) {
      return '$elecPath/fan.png';
    } else if (lowerName.contains('power failure') || lowerName.contains('failure')) {
      return '$elecPath/power.png';
    } else if (lowerName.contains('light')) {
      return '$elecPath/light.png';
    } else if (lowerName.contains('wiring') || lowerName.contains('rewire')) {
      return '$elecPath/rewire.png';
    } else if (lowerName.contains('inverter')) {
      return '$elecPath/invertor.png';
    }

    // Plumber categories
    String plumbPath = 'assets/catogries/plumber';
    if (lowerName.contains('toilet')) {
      return '$plumbPath/toilet.png';
    } else if (lowerName.contains('drain')) {
      return '$plumbPath/drain.png';
    } else if (lowerName.contains('tap') || lowerName.contains('faucet')) {
      return '$plumbPath/facuetrepair.png';
    } else if (lowerName.contains('pipe') || lowerName.contains('leak')) {
      return '$plumbPath/pipeleak.png';
    } else if (lowerName.contains('tank')) {
      return '$plumbPath/watertank.png';
    } else if (lowerName.contains('bathroom')) {
      if (widget.categoryName.toLowerCase().contains('clean') || widget.categoryName.toLowerCase().contains('pest')) {
        return 'assets/catogries/cleaning&pest/bathroom.png';
      }
      return '$plumbPath/bathroom.png';
    }

    // Cleaning & Pest Control categories
    String cleanPath = 'assets/catogries/cleaning&pest';
    if (lowerName.contains('mattress')) {
      return '$cleanPath/mattres.png';
    } else if (lowerName.contains('pest')) {
      return '$cleanPath/pest.png';
    } else if (lowerName.contains('sofa') || lowerName.contains('carpet')) {
      return '$cleanPath/sofa.png';
    } else if (lowerName.contains('kitchen')) {
      if (widget.categoryName.toLowerCase().contains('clean') || widget.categoryName.toLowerCase().contains('pest')) {
        return '$cleanPath/kitchen.png';
      }
    } else if (lowerName.contains('clean')) {
      return '$cleanPath/cleaning.png';
    }

    // Carpenter categories
    String carpPath = 'assets/catogries/carpenter';
    if (lowerName.contains('cupboard') || lowerName.contains('shelf')) {
      return '$carpPath/cupboard.png';
    } else if (lowerName.contains('door')) {
      return '$carpPath/door.png';
    } else if (lowerName.contains('furniture')) {
      return '$carpPath/furniture.png';
    } else if (lowerName.contains('modular') || (lowerName.contains('kitchen') && widget.categoryName.toLowerCase().contains('carpenter'))) {
      return '$carpPath/modkitchen.png';
    } else if (lowerName.contains('wood') || lowerName.contains('polish')) {
      return '$carpPath/woodpolish.png';
    }

    // Appliance categories
    String appPath = 'assets/catogries/appliance';
    if (lowerName.contains('refrigerator') || lowerName.contains('fridge')) {
      return '$appPath/fridge.png';
    } else if (lowerName.contains('ac repair') || lowerName.startsWith('ac ') || lowerName == 'ac') {
      return '$appPath/ac.png';
    } else if (lowerName.contains('washing')) {
      return '$appPath/washingmachine.png';
    } else if (lowerName.contains('microwave') || lowerName.contains('oven')) {
      return '$appPath/microwave.png';
    } else if (lowerName.contains('tv') || lowerName.contains('television')) {
      return '$appPath/tv.png';
    }

    // Bulk categories
    String bulkPath = 'assets/catogries/bulk';
    if (lowerName.contains('event')) {
      return '$bulkPath/event.png';
    } else if (lowerName.contains('office')) {
      return '$bulkPath/office.png';
    } else if (lowerName.contains('wholesale')) {
      return '$bulkPath/wholesale.png';
    }

    // Painting categories
    String paintPath = 'assets/catogries/painting';
    if (lowerName.contains('interior')) {
      return '$paintPath/interior.png';
    } else if (lowerName.contains('exterior')) {
      return '$paintPath/exterior.png';
    } else if (lowerName.contains('proof')) {
      return '$paintPath/waterproof.png';
    } else if (lowerName.contains('texture') || lowerName.contains('design') || lowerName.contains('wall')) {
      return '$paintPath/wallpaper.png';
    } else if (lowerName.contains('renovation')) {
      return '$paintPath/renovation.png';
    }

    // RO & Water Purifier categories
    String roPath = 'assets/catogries/ro';
    if (lowerName.contains('repair') || lowerName.contains('maintenance')) {
      return '$roPath/repair.png';
    } else if (lowerName.contains('quality')) {
      return '$roPath/waterquality.png';
    } else if (lowerName.contains('filter')) {
      return '$roPath/filterraplaement.png';
    } else if (lowerName.contains('installation') || lowerName.contains('install') || lowerName.contains('ro ')) {
      return '$roPath/ROinstall.png';
    }

    return null;
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
          if (index == 0) {
            _services = [];
          } else if (index == 1) {
            _services = List.from(_allSubServices);
          } else {
            final selectedCat = _categories[index];
            if (selectedCat.serviceId != null) {
              _services = _allSubServices.where((s) => s.serviceId == selectedCat.serviceId).toList();
            } else {
              _services = [];
            }
          }
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
            category.imagePath != null
                ? Image.asset(category.imagePath!, width: 28, height: 28, color: contentColor)
                : Icon(category.icon, color: contentColor, size: 28),
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

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchAddress(),
      _fetchData(),
    ]);
  }

  Widget _buildServiceList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B1464)));
    }
    
    if (_services.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Center(child: Text("No services found")),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          return _buildServiceCard(context, _services[index]);
        },
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, _ServiceItem service) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(
              subserviceId: service.subserviceId,
              categoryId: service.categoryId,
              title: service.title,
              price: service.price,
              rating: service.rating,
              time: service.time,
              imagePath: service.imagePath,
              description: service.description,
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
            child: service.imagePath.startsWith('http')
                ? Image.network(
                    service.imagePath,
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 90,
                      width: 90,
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image, color: Colors.grey.shade400),
                    ),
                  )
                : Image.asset(
                    service.imagePath,
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 90,
                      width: 90,
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image, color: Colors.grey.shade400),
                    ),
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
                        onPressed: () async {
                          if (service.subserviceId != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Adding ${service.title} to cart...')),
                            );
                             final rawLoc = _currentAddress?['area_locality'] ?? _currentAddress?['city'] ?? _currentAddress?['address_line_1'] ?? 'Bangalore';
                             final locName = rawLoc.toString().toLowerCase() == 'bengaluru' ? 'Bangalore' : rawLoc.toString();

                             final data = await ApiService.addToCart(
                               service.subserviceId!, 
                               1, 
                               _currentAddress?['_id'], 
                               locName
                             );
                            if (data != null && data['success'] == true) {
                              CartState.cartData.value = data;
                              CartState.updateCount(data);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${service.title} added to cart!')),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                
                                if (data?['message'] == 'Please login first' || data?['message'] == 'Please Login first') {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text('Login Required', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B1464))),
                                      content: const Text('Please login to add items to your cart.', style: TextStyle(fontSize: 15)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1B1464),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Login', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(data?['message'] ?? 'Failed to add to cart.')),
                                  );
                                }
                              }
                            }
                          }
                        },
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
  final String? imagePath;
  final String? serviceId;

  _ServiceCategory(this.name, this.icon, {this.isSpecial = false, this.imagePath, this.serviceId});
}

class _ServiceItem {
  final String title;
  final String rating;
  final String? time;
  final String price;
  final String imagePath;
  final String? serviceId;
  final String? subserviceId;
  final String? categoryId;
  final String? description;

  _ServiceItem({
    required this.title,
    required this.rating,
    this.time,
    required this.price,
    required this.imagePath,
    this.serviceId,
    this.subserviceId,
    this.categoryId,
    this.description,
  });
}

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../cart/cart_screen.dart';
import '../../providers/cart_state.dart';
import '../auth/login_screen.dart';
import '../../widgets/app_toast.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String? subserviceId;
  final String? categoryId;
  final String title;
  final String price;
  final String rating;
  final String? time;
  final String imagePath;
  final String? description;

  const ServiceDetailsScreen({
    super.key,
    this.subserviceId,
    this.categoryId,
    required this.title,
    required this.price,
    required this.rating,
    this.time,
    required this.imagePath,
    this.description,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  List<dynamic> _relatedServices = [];
  bool _isLoadingRelated = true;
  Map<String, dynamic>? _currentAddress;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
    _fetchRelatedServices();
  }

  Future<void> _fetchAddress() async {
    final addresses = await ApiService.getAddresses();
    if (mounted && addresses.isNotEmpty) {
      setState(() {
        _currentAddress = addresses.first;
      });
    }
  }

  Future<void> _fetchRelatedServices() async {
    if (widget.categoryId == null) {
      if (mounted) setState(() => _isLoadingRelated = false);
      return;
    }

    try {
      final subServicesData = await ApiService.getSubServicesByCategory(widget.categoryId!);
      if (mounted) {
        setState(() {
          _relatedServices = subServicesData.where((ss) {
            return ss['_id'] != widget.subserviceId;
          }).toList();
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildServiceInfo(),
                if (widget.description != null && widget.description!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _buildServicePreparation(),
                const SizedBox(height: 32),
                _buildPeopleAlsoChoose(),
                const SizedBox(height: 32),
                _buildReviews(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
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

  Widget _buildServiceInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: widget.imagePath.startsWith('http')
              ? Image.network(
                  widget.imagePath,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                )
              : Image.asset(
                  widget.imagePath,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
        ),
        const SizedBox(width: 16),
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
                      widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.green.shade600, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          widget.rating,
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey.shade500, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.time != null ? '${widget.time} mins' : '45 mins',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.price,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1464),
                    ),
                  ),
                  ValueListenableBuilder<Map<String, dynamic>?>(
                    valueListenable: CartState.cartData,
                    builder: (context, cartData, child) {
                      final inCart = CartState.isItemInCart(widget.subserviceId);

                      return InkWell(
                        onTap: () async {
                          if (widget.subserviceId != null) {
                            if (inCart) {
                              AppToast.show(context, '${widget.title} is already in cart');
                              return;
                            }

                             final rawLoc = _currentAddress?['area_locality'] ?? _currentAddress?['city'] ?? _currentAddress?['address_line_1'] ?? 'Bangalore';
                             final locName = rawLoc.toString().toLowerCase() == 'bengaluru' ? 'Bangalore' : rawLoc.toString();

                             final data = await ApiService.addToCart(
                               widget.subserviceId!, 
                               1, 
                               _currentAddress?['_id'], 
                               locName
                             );
                             if (data != null && data['success'] == true) {
                               CartState.cartData.value = data;
                               CartState.updateCount(data);
                               if (context.mounted) {
                                 AppToast.show(context, 'Added ${widget.title} to cart');
                               }
                             } else {
                               if (context.mounted) {
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
                                   AppToast.show(context, data?['message'] ?? 'Failed to add to cart.', isError: true);
                                 }
                              }
                            }
                          }
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: inCart ? Colors.green.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: inCart ? Colors.green : const Color(0xFFE8E8FF), width: 1.5),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (inCart) ...[
                                  const Icon(Icons.check, size: 16, color: Colors.green),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  inCart ? 'Added to Cart' : 'Add to Cart',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: inCart ? Colors.green.shade700 : const Color(0xFF1B1464),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicePreparation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Preparation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildPrepItem('Ladder should be available if required'),
              const SizedBox(height: 12),
              _buildPrepItem('Power supply must be available.'),
              const SizedBox(height: 12),
              _buildPrepItem('Wiring beyond 2 meters will be charged extra.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrepItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check, color: Colors.black87, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleAlsoChoose() {
    if (_isLoadingRelated) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'People also choose',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 12),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_relatedServices.isEmpty) {
      // Fallback to static if no related services found or if API fails
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'People also choose',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildAlsoChooseCard('AC Repair', 'From ₹499', 'assets/images/ac_repair.png'),
                const SizedBox(width: 16),
                _buildAlsoChooseCard('Fan Replacement', 'From ₹499', 'assets/images/fan.png'),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'People also choose',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _relatedServices.length,
            itemBuilder: (context, index) {
              final rs = _relatedServices[index];
              final title = rs['subservice_name'] ?? 'Unknown';
              final price = 'From ₹${rs['base_price'] ?? 499}';
              final image = (rs['image'] != null && rs['image'].toString().isNotEmpty) 
                  ? rs['image'] 
                  : 'assets/images/switch.png';

              return Padding(
                padding: EdgeInsets.only(right: index == _relatedServices.length - 1 ? 0 : 16.0),
                child: _buildAlsoChooseCard(title, price, image),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlsoChooseCard(String title, String price, String itemImagePath) {
    return Container(
      width: 160,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: itemImagePath.startsWith('http')
                ? Image.network(
                    itemImagePath,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Image.asset(
                    itemImagePath,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        // Assuming subserviceId is passed or available, but here we don't have it easily.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select this service from the main list to add to cart.')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE8E8FF), width: 1.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B1464))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  price,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildReviewCard(
                'Madhu Sri',
                '4.2',
                'The technician arrived on time and installed the fan quickly. The work was neat and professional. Very satisfied with the service.',
              ),
              const SizedBox(width: 16),
              _buildReviewCard(
                'Madhu Sri',
                '4.2',
                'The technician arrived on time and installed the fan quickly. The work was neat and professional. Very satisfied with the service.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String name, String reviewRating, String reviewText) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/user1.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 24,
                        height: 24,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.person, size: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.green.shade600, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      reviewRating,
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              reviewText,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

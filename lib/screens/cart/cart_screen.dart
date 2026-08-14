import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../providers/cart_state.dart';
import 'payment_selection_screen.dart';
import '../address/add_address_screen.dart';
import '../home/categories_screen.dart';
import '../../widgets/slot_selection_modal.dart';
import '../../widgets/app_toast.dart';

class CartScreen extends StatefulWidget {
  final bool useSingleCategoryDesign;
  const CartScreen({super.key, this.useSingleCategoryDesign = false});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? _currentAddress;
  List<dynamic> _addresses = [];
  List<dynamic> _popularServices = [];
  bool _isLoading = false;
  bool _isPopularLoading = true;
  final Set<String> _customIndividualSlotsCategories = {};

  @override
  void initState() {
    super.initState();
    _fetchAddress();
    _fetchPopularServices();
    CartState.fetchCart();
  }

  Future<void> _fetchAddress() async {
    final addresses = await ApiService.getAddresses();
    if (mounted && addresses.isNotEmpty) {
      setState(() {
        _addresses = addresses;
        _currentAddress = addresses.firstWhere(
          (a) => a['is_default'] == true,
          orElse: () => addresses.first,
        );
      });
    }
  }

  Future<void> _fetchPopularServices() async {
    try {
      final services = await ApiService.getPopularServices();
      if (mounted) {
        setState(() {
          _popularServices = services;
          _isPopularLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPopularLoading = false);
      }
    }
  }

  Future<void> _updateQuantity(String subserviceId, int newQuantity) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final cartData = CartState.cartData.value;
      final rawItems = (cartData?['items'] as List<dynamic>?) ?? [];

      int duplicateCount = 0;
      for (var item in rawItems) {
        final sub = item['subservice_id'];
        final id = sub is Map ? sub['_id']?.toString() : sub?.toString();
        if (id == subserviceId) {
          duplicateCount++;
        }
      }

      Map<String, dynamic>? data;

      if (duplicateCount > 1) {
        await ApiService.removeFromCart(subserviceId);
        if (newQuantity > 0) {
          final rawLoc = _currentAddress?['area_locality'] ?? _currentAddress?['city'] ?? _currentAddress?['address_line_1'] ?? 'Bangalore';
          final locName = rawLoc.toString().toLowerCase() == 'bengaluru' ? 'Bangalore' : rawLoc.toString();
          data = await ApiService.addToCart(subserviceId, newQuantity, _currentAddress?['_id'], locName);
        } else {
          data = await ApiService.getCart();
        }
      } else {
        if (newQuantity <= 0) {
          data = await ApiService.removeFromCart(subserviceId);
        } else {
          data = await ApiService.updateCartItem(subserviceId, newQuantity);
        }
      }

      if (data != null) {
        CartState.cartData.value = data;
        CartState.updateCount(data);
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addRecommendedService(dynamic service) async {
    final subserviceId = service['_id'];
    if (subserviceId == null) return;

    final rawLoc = _currentAddress?['area_locality'] ?? _currentAddress?['city'] ?? _currentAddress?['address_line_1'] ?? 'Bangalore';
    final locName = rawLoc.toString().toLowerCase() == 'bengaluru' ? 'Bangalore' : rawLoc.toString();

    setState(() => _isLoading = true);
    final data = await ApiService.addToCart(
      subserviceId.toString(),
      1,
      _currentAddress?['_id'],
      locName,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (data != null && data['success'] == true) {
        CartState.cartData.value = data;
        CartState.updateCount(data);
        final title = service['name'] ?? service['subservice_name'] ?? service['service_name'] ?? service['title'] ?? 'Service';
        AppToast.show(context, 'Added $title to cart');
      } else {
        AppToast.show(context, data?['message'] ?? 'Failed to add item', isError: true);
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchAddress(),
      _fetchPopularServices(),
      CartState.fetchCart(),
    ]);
  }

  void _showAddressSelectorSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Delivery Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B1464),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No saved addresses found.'),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _addresses.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final addr = _addresses[index];
                          final id = addr['_id'];
                          final isSelected = _currentAddress?['_id'] == id;
                          final title = addr['area_locality'] ?? addr['address_line_1'] ?? 'Address ${index + 1}';
                          final subtitle = '${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['pincode'] ?? ''}';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: Icon(
                              Icons.location_on,
                              color: isSelected ? const Color(0xFF1B1464) : Colors.grey,
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF1B1464) : Colors.black87,
                              ),
                            ),
                            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Color(0xFF1B1464))
                                : null,
                            onTap: () async {
                              setState(() {
                                _currentAddress = addr;
                              });
                              Navigator.pop(context);
                              if (id != null) {
                                await ApiService.setDefaultAddress(id);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
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
            );
          },
        );
      },
    );
  }

  void _onAddMoreItemsPressed() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CategoriesScreen()),
      );
    }
  }

  void _navigateToSlotSelection() {
    if (_currentAddress == null || _currentAddress!['_id'] == null) {
      AppToast.show(context, 'Please select or add an address first', isError: true);
      return;
    }

    final cartData = CartState.cartData.value;
    final items = (cartData?['items'] as List<dynamic>?) ?? [];

    if (items.isEmpty) {
      AppToast.show(context, 'Your cart is empty', isError: true);
      return;
    }

    // Check if ALL services in the cart have a selected date and time slot
    final List<String> unselectedServices = [];
    for (var item in items) {
      final subservice = item['subservice_id'];
      final title = subservice is Map 
          ? (subservice['subservice_name'] ?? subservice['name'] ?? subservice['service_name'] ?? 'Service')
          : 'Service';
      final selectedDate = item['selected_date']?.toString();
      final selectedTimeSlot = item['selected_time_slot']?.toString();

      if (selectedDate == null || selectedDate.trim().isEmpty || selectedTimeSlot == null || selectedTimeSlot.trim().isEmpty) {
        unselectedServices.add(title);
      }
    }

    if (unselectedServices.isNotEmpty) {
      AppToast.show(
        context,
        'Please select a time slot for all services before proceeding to checkout',
        isError: true,
      );
      return;
    }

    final totalAmount = (cartData?['total_amount'] as num?)?.toDouble() ?? 0.0;
    final firstItem = items[0];
    final selectedDate = firstItem['selected_date']?.toString() ?? DateTime.now().toString().split(' ')[0];
    final selectedTime = firstItem['selected_time_slot']?.toString() ?? '02:00 PM';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSelectionScreen(
          addressId: _currentAddress!['_id'],
          selectedDate: selectedDate,
          selectedTime: selectedTime,
          totalAmount: totalAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: CartState.cartData,
          builder: (context, cartData, child) {
            final items = (cartData?['items'] as List<dynamic>?) ?? [];
            final totalAmount = (cartData?['total_amount'] as num?)?.toDouble() ?? 0.0;
            final isEmpty = items.isEmpty;

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: _buildAddressCard(),
                        ),
                        const SizedBox(height: 20),
                        if (isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: Text("Your cart is empty")),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildCartItemsList(items),
                          ),
                        if (!isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildPeopleAlsoChoose(),
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: _buildPaymentSummary(items, totalAmount),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!isEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _navigateToSlotSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B1464),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text(
                            'Proceed to Checkout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          const Text(
            'My Cart',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final title = _currentAddress?['area_locality'] ?? _currentAddress?['address_line_1'] ?? 'Add an Address';
    final subtitle = _currentAddress != null
        ? '${_currentAddress!['city'] ?? ''}, ${_currentAddress!['state'] ?? ''}'
        : 'No address selected';

    return GestureDetector(
      onTap: _showAddressSelectorSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined, color: Color(0xFF1B1464)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _showAddressSelectorSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _deduplicateCartItems(List<dynamic> items) {
    final Map<String, dynamic> combined = {};
    for (var item in items) {
      final subservice = item['subservice_id'];
      if (subservice == null) continue;

      final id = subservice is Map ? subservice['_id']?.toString() : subservice.toString();
      if (id == null || id.isEmpty) continue;

      if (!combined.containsKey(id)) {
        combined[id] = Map<String, dynamic>.from(item as Map<String, dynamic>);
      } else {
        final existing = combined[id] as Map<String, dynamic>;
        final q1 = (existing['quantity'] as num?)?.toInt() ?? 1;
        final q2 = (item['quantity'] as num?)?.toInt() ?? 1;
        existing['quantity'] = q1 + q2;

        if (item['selected_date'] != null && item['selected_date'].toString().isNotEmpty) {
          existing['selected_date'] = item['selected_date'];
        }
        if (item['selected_time_slot'] != null && item['selected_time_slot'].toString().isNotEmpty) {
          existing['selected_time_slot'] = item['selected_time_slot'];
        }
      }
    }
    return combined.values.toList();
  }

  String _getCategoryName(dynamic item) {
    final subservice = item['subservice_id'];
    
    // 1. Check explicit fields in item or subservice object
    if (item is Map) {
      if (item['category_name'] != null && item['category_name'].toString().trim().isNotEmpty) {
        return item['category_name'].toString().trim();
      }
      if (item['category'] != null && item['category'].toString().trim().isNotEmpty) {
        return item['category'].toString().trim();
      }
    }
    
    if (subservice is Map) {
      if (subservice['category_name'] != null && subservice['category_name'].toString().trim().isNotEmpty) {
        return subservice['category_name'].toString().trim();
      }
      final catObj = subservice['category_id'];
      if (catObj is Map) {
        if (catObj['category_name'] != null && catObj['category_name'].toString().trim().isNotEmpty) {
          return catObj['category_name'].toString().trim();
        }
        if (catObj['name'] != null && catObj['name'].toString().trim().isNotEmpty) {
          return catObj['name'].toString().trim();
        }
      }
      if (subservice['service_name'] != null && subservice['service_name'].toString().trim().isNotEmpty) {
        return subservice['service_name'].toString().trim();
      }
      if (subservice['category'] != null && subservice['category'].toString().trim().isNotEmpty) {
        return subservice['category'].toString().trim();
      }
    }

    // 2. Fallback: infer category from item title / subservice name
    String title = '';
    if (subservice is Map) {
      title = (subservice['subservice_name'] ?? subservice['name'] ?? subservice['title'] ?? '').toString();
    }
    if (title.isEmpty && item is Map) {
      title = (item['title'] ?? item['name'] ?? item['package_name'] ?? '').toString();
    }

    final lower = title.toLowerCase();
    if (lower.contains('water') || lower.contains('ro ') || lower.contains('purifier') || lower.contains('filter')) {
      return 'Water Purifier & Testing';
    }
    if (lower.contains('delivery') || lower.contains('logistics') || lower.contains('bulk') || lower.contains('office supply') || lower.contains('pack')) {
      return 'Bulk Delivery & Logistics';
    }
    if (lower.contains('ac ') || lower.contains('air conditioner')) {
      return 'AC Repair & Service';
    }
    if (lower.contains('clean') || lower.contains('pest') || lower.contains('sofa') || lower.contains('mattress') || lower.contains('disinfection')) {
      return 'Cleaning & Pest Control';
    }
    if (lower.contains('paint') || lower.contains('wall') || lower.contains('renovation')) {
      return 'Painting & Waterproofing';
    }
    if (lower.contains('plumb') || lower.contains('pipe') || lower.contains('leak') || lower.contains('drain') || lower.contains('faucet') || lower.contains('tank')) {
      return 'Plumbing Services';
    }
    if (lower.contains('electric') || lower.contains('fan') || lower.contains('switch') || lower.contains('light') || lower.contains('wiring') || lower.contains('invertor')) {
      return 'Electrician Services';
    }
    if (lower.contains('carpent') || lower.contains('door') || lower.contains('cupboard') || lower.contains('furniture') || lower.contains('wood')) {
      return 'Carpentry Services';
    }
    if (lower.contains('cctv') || lower.contains('camera') || lower.contains('lock') || lower.contains('security')) {
      return 'CCTV & Smart Security';
    }
    if (lower.contains('vehicle') || lower.contains('car') || lower.contains('bike') || lower.contains('wash')) {
      return 'Vehicle Services';
    }
    if (lower.contains('loan') || lower.contains('finance')) {
      return 'Financial & Loan Services';
    }
    if (lower.contains('beauty') || lower.contains('facial') || lower.contains('hair') || lower.contains('massage') || lower.contains('pedicure') || lower.contains('wax')) {
      return 'Beauty & Wellness';
    }

    if (title.isNotEmpty) {
      return title;
    }

    return 'Services';
  }

  Widget _buildCartItemsList(List<dynamic> rawItems) {
    final items = _deduplicateCartItems(rawItems);

    final Map<String, List<dynamic>> groupedItems = {};
    for (var item in items) {
      final catName = _getCategoryName(item);
      groupedItems.putIfAbsent(catName, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groupedItems.entries.map((entry) {
          final categoryName = entry.key;
          final categoryItems = entry.value;
          return _buildCategoryGroupCard(categoryName, categoryItems);
        }),
        const SizedBox(height: 8),
        Center(
          child: InkWell(
            onTap: _onAddMoreItemsPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1464).withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, color: Color(0xFF1B1464), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Add More items',
                    style: TextStyle(fontSize: 14, color: Color(0xFF1B1464), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _shouldShowIndividualSlots(String categoryName, List<dynamic> categoryItems) {
    if (_customIndividualSlotsCategories.contains(categoryName)) {
      return true;
    }

    String? firstSlotKey;
    for (var item in categoryItems) {
      final d = item['selected_date']?.toString().trim();
      final t = item['selected_time_slot']?.toString().trim();
      if (d != null && d.isNotEmpty && t != null && t.isNotEmpty) {
        final key = '$d|$t';
        if (firstSlotKey == null) {
          firstSlotKey = key;
        } else if (firstSlotKey != key) {
          return true;
        }
      }
    }

    return false;
  }

  Widget _buildCategoryGroupCard(String categoryName, List<dynamic> categoryItems) {
    final List<String> subserviceIds = categoryItems
        .map((item) {
          final subservice = item['subservice_id'];
          return subservice is Map ? subservice['_id']?.toString() : subservice?.toString();
        })
        .whereType<String>()
        .toList();

    String slotText = 'Select category time slot';
    bool hasSlot = false;
    for (var item in categoryItems) {
      final selectedDate = item['selected_date']?.toString();
      final selectedTimeSlot = item['selected_time_slot']?.toString();
      if (selectedDate != null && selectedDate.isNotEmpty && selectedTimeSlot != null && selectedTimeSlot.isNotEmpty) {
        hasSlot = true;
        try {
          final parsedDate = DateTime.parse(selectedDate);
          final formattedDate = DateFormat('EEE, d MMM').format(parsedDate);
          slotText = '$formattedDate at $selectedTimeSlot';
        } catch (_) {
          slotText = '$selectedDate at $selectedTimeSlot';
        }
        break;
      } else if (selectedTimeSlot != null && selectedTimeSlot.isNotEmpty) {
        hasSlot = true;
        slotText = selectedTimeSlot;
        break;
      }
    }

    final bool showIndividualSlots = _shouldShowIndividualSlots(categoryName, categoryItems);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1464).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.home_repair_service, color: Color(0xFF1B1464), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  categoryName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              if (subserviceIds.isNotEmpty) {
                await SlotSelectionModal.showForGroup(context, subserviceIds, categoryName);
                if (mounted) {
                  setState(() {
                    _customIndividualSlotsCategories.remove(categoryName);
                  });
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasSlot ? const Color(0xFF1B1464).withOpacity(0.06) : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hasSlot ? const Color(0xFF1B1464).withOpacity(0.18) : Colors.amber.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 13,
                    color: hasSlot ? const Color(0xFF1B1464) : Colors.amber.shade900,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    slotText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasSlot ? const Color(0xFF1B1464) : Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit,
                    size: 12,
                    color: hasSlot ? const Color(0xFF1B1464) : Colors.amber.shade900,
                  ),
                ],
              ),
            ),
          ),
          if (categoryItems.length > 1) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                if (showIndividualSlots) {
                  _customIndividualSlotsCategories.remove(categoryName);
                  
                  String? refDate;
                  String? refSlot;
                  for (var item in categoryItems) {
                    final d = item['selected_date']?.toString();
                    final t = item['selected_time_slot']?.toString();
                    if (d != null && d.isNotEmpty && t != null && t.isNotEmpty) {
                      refDate = d;
                      refSlot = t;
                      break;
                    }
                  }

                  if (refDate != null && refSlot != null && subserviceIds.isNotEmpty) {
                    setState(() => _isLoading = true);
                    for (var sId in subserviceIds) {
                      await ApiService.updateSlot(sId, refDate, refSlot);
                    }
                    final updatedCart = await ApiService.getCart();
                    if (mounted) {
                      if (updatedCart != null) {
                        CartState.cartData.value = updatedCart;
                      }
                      setState(() => _isLoading = false);
                    }
                  } else if (subserviceIds.isNotEmpty) {
                    await SlotSelectionModal.showForGroup(context, subserviceIds, categoryName);
                    if (mounted) {
                      setState(() {
                        _customIndividualSlotsCategories.remove(categoryName);
                      });
                    }
                  } else {
                    setState(() {});
                  }
                } else {
                  setState(() {
                    _customIndividualSlotsCategories.add(categoryName);
                  });
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showIndividualSlots ? Icons.link_off_rounded : Icons.tune_rounded,
                      size: 13,
                      color: const Color(0xFF1B1464),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      showIndividualSlots 
                          ? 'Use same time slot for all services'
                          : 'Select different time slot for each service',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B1464),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...categoryItems.map((item) => _buildCategoryCartItemRow(item, showIndividualSlots)),
        ],
      ),
    );
  }

  Widget _buildCategoryCartItemRow(dynamic item, bool showIndividualSlot) {
    final subservice = item['subservice_id'];
    if (subservice == null) return const SizedBox.shrink();

    final title = subservice['subservice_name'] ?? subservice['name'] ?? subservice['service_name'] ?? 'Unknown Service';
    final price = item['price_snapshot'] ?? subservice['base_price'] ?? 0;
    final subserviceId = subservice is Map ? subservice['_id']?.toString() : subservice.toString();
    final imagePath = subservice['image'] ?? '';

    final selectedDate = item['selected_date']?.toString();
    final selectedTimeSlot = item['selected_time_slot']?.toString();

    String itemSlotText = 'Select time slot';
    bool hasItemSlot = false;
    if (selectedDate != null && selectedDate.isNotEmpty && selectedTimeSlot != null && selectedTimeSlot.isNotEmpty) {
      hasItemSlot = true;
      try {
        final parsedDate = DateTime.parse(selectedDate);
        final formattedDate = DateFormat('EEE, d MMM').format(parsedDate);
        itemSlotText = '$formattedDate at $selectedTimeSlot';
      } catch (_) {
        itemSlotText = '$selectedDate at $selectedTimeSlot';
      }
    } else if (selectedTimeSlot != null && selectedTimeSlot.isNotEmpty) {
      hasItemSlot = true;
      itemSlotText = selectedTimeSlot;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (imagePath.toString().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imagePath.toString().startsWith('http')
                      ? Image.network(
                          imagePath,
                          height: 44,
                          width: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 44, width: 44, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 18, color: Colors.grey)),
                        )
                      : Image.asset(
                          imagePath,
                          height: 44,
                          width: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 44, width: 44, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 18, color: Colors.grey)),
                        ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${(price as num).toInt()}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  if (!_isLoading && subserviceId != null) {
                    _updateQuantity(subserviceId, 0);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                ),
              ),
            ],
          ),
          if (showIndividualSlot) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                if (subserviceId != null) {
                  SlotSelectionModal.show(context, subserviceId, title);
                }
              },
              child: Container(
                margin: EdgeInsets.only(left: imagePath.toString().isNotEmpty ? 56 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasItemSlot ? const Color(0xFF1B1464).withOpacity(0.05) : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: hasItemSlot ? const Color(0xFF1B1464).withOpacity(0.12) : Colors.amber.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: hasItemSlot ? const Color(0xFF1B1464) : Colors.amber.shade900,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      itemSlotText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasItemSlot ? const Color(0xFF1B1464) : Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 10,
                      color: hasItemSlot ? const Color(0xFF1B1464) : Colors.amber.shade900,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeopleAlsoChoose() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'People also choose',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: _isPopularLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B1464)))
              : _popularServices.isEmpty
                  ? ListView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      children: [
                        _buildFallbackAlsoChooseCard('AC Repair', '₹499', 'assets/images/service_repair.png', '4.8'),
                        const SizedBox(width: 16),
                        _buildFallbackAlsoChooseCard('Fan Replacement', '₹499', 'assets/images/service_repair.png', '4.8'),
                      ],
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: _popularServices.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final service = _popularServices[index];
                        return _buildDynamicAlsoChooseCard(service);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDynamicAlsoChooseCard(dynamic service) {
    final title = service['subservice_name'] ?? service['service_name'] ?? 'Service';
    final price = service['base_price'] ?? service['price'] ?? 499;
    final image = service['image'] ?? service['icon'] ?? '';
    final rating = (service['avg_rating'] ?? 4.8).toString();

    return Container(
      width: 150,
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: image.toString().startsWith('http')
                    ? Image.network(
                        image,
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 90,
                          width: double.infinity,
                          color: const Color(0xFFF0F2FF),
                          child: const Icon(Icons.category, color: Color(0xFF1B1464), size: 32),
                        ),
                      )
                    : Image.asset(
                        image.toString().isNotEmpty ? image : 'assets/images/service_repair.png',
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 90,
                          width: double.infinity,
                          color: const Color(0xFFF0F2FF),
                          child: const Icon(Icons.category, color: Color(0xFF1B1464), size: 32),
                        ),
                      ),
              ),
              Positioned(
                bottom: -10,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.green.shade600, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0).copyWith(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ValueListenableBuilder<Map<String, dynamic>?>(
                      valueListenable: CartState.cartData,
                      builder: (context, cartData, child) {
                        final subserviceId = service['_id']?.toString();
                        final inCart = CartState.isItemInCart(subserviceId);

                        return InkWell(
                          onTap: () {
                            if (inCart && subserviceId != null) {
                              SlotSelectionModal.show(context, subserviceId, title);
                            } else {
                              _addRecommendedService(service);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: inCart ? Colors.green.shade50 : Colors.white,
                              border: Border.all(color: inCart ? Colors.green : const Color(0xFFE8E8FF), width: 1.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (inCart) ...[
                                  const Icon(Icons.check, size: 10, color: Colors.green),
                                  const SizedBox(width: 2),
                                ],
                                Text(
                                  inCart ? 'Added' : 'Add',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: inCart ? Colors.green.shade700 : const Color(0xFF1B1464),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'From ₹$price',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAlsoChooseCard(String title, String price, String itemImagePath, String rating) {
    return Container(
      width: 150,
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  itemImagePath,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 90,
                    width: double.infinity,
                    color: const Color(0xFFF0F2FF),
                    child: const Icon(Icons.category, color: Color(0xFF1B1464), size: 32),
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.green.shade600, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0).copyWith(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE8E8FF), width: 1.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B1464))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'From $price',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B1464)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(List<dynamic> items, double itemTotal) {
    double taxes = 0;
    double total = itemTotal + taxes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Item Total', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  Text('₹${itemTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Item Discount', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const Text('- ₹0', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Taxes and Fee', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  Text('₹${taxes.toInt()}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  Text('₹${total.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B1464))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

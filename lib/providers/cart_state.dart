import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class CartState {
  static final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);
  static final ValueNotifier<Map<String, dynamic>?> cartData = ValueNotifier<Map<String, dynamic>?>(null);

  static Future<void> fetchCart() async {
    try {
      final data = await ApiService.getCart();
      cartData.value = data;
      updateCount(data);
    } catch (e) {
      debugPrint('Error fetching cart: $e');
    }
  }

  static void updateCount(Map<String, dynamic>? data) {
    if (data == null || data['items'] == null) {
      cartItemCount.value = 0;
      return;
    }
    
    final items = List<dynamic>.from(data['items']);
    int count = 0;
    for (var item in items) {
      count += (item['quantity'] as num).toInt();
    }
    cartItemCount.value = count;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'server_error_handler.dart';
import '../providers/cart_state.dart';

class ApiService {
  static String get baseUrl {
    String url = dotenv.env['NEXT_PUBLIC_API_URL'] ?? 'http://localhost:5000/api';
    if (!kIsWeb && Platform.isAndroid) {
      url = url.replaceAll('localhost', '10.0.2.2');//10.0.2.2
    }
    return url;
  }

  static void _checkResponse(http.Response response) {
    if (response.statusCode == 503 || response.statusCode == 502 || response.statusCode == 504) {
      ServerErrorHandler.handle503Error(
        message: 'Server is currently unavailable (${response.statusCode}). Please try again later.',
      );
    }
  }

  static void _handleError(Object e) {
    ServerErrorHandler.handle503Error(
      message: 'Unable to communicate with the server. Please check your network or try again later.',
    );
  }

  static Future<http.Response> _get(Uri url, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(url, headers: headers);
      _checkResponse(response);
      return response;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  static Future<http.Response> _post(Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      final response = await http.post(url, headers: headers, body: body);
      _checkResponse(response);
      return response;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  static Future<http.Response> _put(Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      final response = await http.put(url, headers: headers, body: body);
      _checkResponse(response);
      return response;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  static Future<http.Response> _delete(Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      final response = await http.delete(url, headers: headers, body: body);
      _checkResponse(response);
      return response;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  static Future<http.Response> _patch(Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      final response = await http.patch(url, headers: headers, body: body);
      _checkResponse(response);
      return response;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  static const String _tokenKey = 'auth_token';

  // Helper to save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Helper to get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Helper to clear token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty || token == 'pending_auth_token') {
      return false;
    }
    final profile = await getUserProfile();
    return profile != null && profile['_id'] != null && profile['_id'] != 'pending_verification';
  }

  // Helper to sanitize phone number by stripping +91, +, spaces, and formatting
  static String cleanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]+'), '');
    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned.trim();
  }

  // Send OTP
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final identifier = cleanPhone(phone);

      final response = await _post(
        Uri.parse('$baseUrl/users/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'role': 'customer',
          'useEmail': false
        }),
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final identifier = cleanPhone(phone);

      final response = await _post(
        Uri.parse('$baseUrl/users/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
          'otp': otp,
          'useEmail': false
        }),
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;
      
      if (data['success'] == true) {
        final user = data['user'];
        final token = user?['token'] ?? data['token'];
        if (token != null && token != 'pending_auth_token') {
          await saveToken(token);
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Register User
  static Future<Map<String, dynamic>> registerUser(String phone, String name, [String? email, String? gender]) async {
    try {
      final Map<String, dynamic> body = {'phone': cleanPhone(phone), 'name': name};
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      if (gender != null && gender.isNotEmpty) {
        body['gender'] = gender;
      }

      final response = await _post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;

      if (data['success'] == true) {
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Email Login
  static Future<Map<String, dynamic>> emailLogin(String email, String password) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;

      if (data['success'] == true) {
        final token = data['token'] ?? (data['user'] != null ? data['user']['token'] : null);
        if (token != null) {
          await saveToken(token);
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Google Login
  static Future<Map<String, dynamic>> googleLogin(String googleToken) async {
    try {
      final response = await _post(
        Uri.parse('$baseUrl/users/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': googleToken,
        }),
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;

      if (data['success'] == true) {
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Add Address
  static Future<Map<String, dynamic>> addAddress(Map<String, dynamic> addressData) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _post(
        Uri.parse('$baseUrl/address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(addressData),
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete Address
  static Future<Map<String, dynamic>> deleteAddress(String id) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _delete(
        Uri.parse('$baseUrl/address/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Set Address as Default
  static Future<Map<String, dynamic>> setDefaultAddress(String id) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _patch(
        Uri.parse('$baseUrl/address/$id/set-default'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get Addresses
  static Future<List<dynamic>> getAddresses() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await _get(
        Uri.parse('$baseUrl/address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get User Profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update User Profile
  static Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phone,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final Map<String, dynamic> body = {};
      if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
      if (phone != null && phone.trim().isNotEmpty) body['phone'] = cleanPhone(phone);
      if (email != null && email.trim().isNotEmpty) body['email'] = email.trim();
      if (currentPassword != null && currentPassword.isNotEmpty) {
        body['currentPassword'] = currentPassword;
      }
      if (newPassword != null && newPassword.isNotEmpty) {
        body['newPassword'] = newPassword;
      }

      final response = await _put(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get Popular Services (Sub-services)
  static Future<List<dynamic>> getPopularServices() async {
    try {
      final response = await _get(Uri.parse('$baseUrl/sub-services'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is List) {
          var activeServices = data.where((item) => item['status'] == 'active').toList();
          
          // Sort by total_reviews descending, then avg_rating descending
          activeServices.sort((a, b) {
            int reviewsA = (a['total_reviews'] ?? 0);
            int reviewsB = (b['total_reviews'] ?? 0);
            if (reviewsA != reviewsB) return reviewsB.compareTo(reviewsA);
            
            num ratingA = (a['avg_rating'] ?? 0);
            num ratingB = (b['avg_rating'] ?? 0);
            return ratingB.compareTo(ratingA);
          });

          // Check if all active services have 0 reviews
          bool noReviews = activeServices.every((item) => (item['total_reviews'] ?? 0) == 0);
          
          if (noReviews && activeServices.isNotEmpty) {
            // Shuffle to show random services if no reviews are present
            activeServices.shuffle();
          }

          return activeServices.take(5).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get Banners
  static Future<List<dynamic>> getBanners() async {
    try {
      final response = await _get(Uri.parse('$baseUrl/banners'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.where((item) => item['status'] == 'active').toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get Categories
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await _get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.where((item) => item['status'] == 'active').toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get Services by Category
  static Future<List<dynamic>> getServices(String? categoryId, {String? gender}) async {
    try {
      String url = '$baseUrl/services';
      List<String> params = [];
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          categoryId != 'all' &&
          RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(categoryId)) {
        params.add('category_id=$categoryId');
      }
      if (gender != null && gender.isNotEmpty) {
        params.add('gender=${gender.toLowerCase()}');
      }
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      final response = await _get(Uri.parse(url));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.where((item) => item['status'] == 'active').toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get Sub-services by Category
  static Future<List<dynamic>> getSubServicesByCategory(String? categoryId) async {
    try {
      String url = '$baseUrl/sub-services';
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          categoryId != 'all' &&
          RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(categoryId)) {
        url += '?category_id=$categoryId';
      }
      final response = await _get(Uri.parse(url));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.where((item) => item['status'] == 'active').toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get My Bookings
  static Future<List<dynamic>> getMyBookings({int limit = 100, int page = 1}) async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await _get(
        Uri.parse('$baseUrl/bookings/my?limit=$limit&page=$page'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data != null && data['data'] is List) {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get Booking By ID
  static Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Cancel Booking
  static Future<Map<String, dynamic>?> cancelBooking(String bookingId, String reason) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await _put(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Booking cancelled successfully', 'booking': decoded['booking']};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to cancel booking'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get Notifications
  static Future<List<dynamic>> getNotifications() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await _get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['data'] is List) {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Cart APIs
  static Future<Map<String, dynamic>?> getCart() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _get(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> addToCart(String subserviceId, int quantity, String? locationId, String? locationName) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Please login first'};

      if (CartState.isItemInCart(subserviceId)) {
        int currentQty = CartState.getItemQuantity(subserviceId);
        int newQty = currentQty + quantity;
        final updateRes = await updateCartItem(subserviceId, newQty);
        if (updateRes != null) {
          updateRes['success'] = true;
          return updateRes;
        }
      }

      final response = await _post(
        Uri.parse('$baseUrl/cart/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subservice_id': subserviceId,
          'quantity': quantity,
          if (locationId != null) 'location_id': locationId,
          if (locationName != null) 'location_name': locationName,
        }),
      );
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        data['success'] = true;
        return data;
      } else {
        debugPrint('Failed to add to cart: ${response.statusCode} - ${response.body}');
        data['success'] = false;
        return data;
      }
    } catch (e) {
      debugPrint('Exception in addToCart: $e');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  static Future<Map<String, dynamic>?> updateCartItem(String subserviceId, int quantity) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _put(
        Uri.parse('$baseUrl/cart/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subservice_id': subserviceId,
          'quantity': quantity,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> removeFromCart(String subserviceId) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _delete(
        Uri.parse('$baseUrl/cart/item/$subserviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> clearCart() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _delete(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Update Slot for Cart Item
  static Future<Map<String, dynamic>?> updateSlot(String subserviceId, String selectedDate, String selectedTimeSlot) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _put(
        Uri.parse('$baseUrl/cart/slot'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subservice_id': subserviceId,
          'selected_date': selectedDate,
          'selected_time_slot': selectedTimeSlot,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Checkout / Create Booking
  static Future<Map<String, dynamic>?> createBooking(String addressId, String paymentMethod, {String? couponCode, String? paymentId}) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final Map<String, dynamic> body = {
        'address': addressId,
        'payment_method': paymentMethod,
      };
      if (couponCode != null && couponCode.isNotEmpty) {
        body['coupon_code'] = couponCode;
      }
      if (paymentId != null && paymentId.isNotEmpty) {
        body['payment_id'] = paymentId;
      }

      final response = await _post(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      
      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Create Razorpay Order (Secure Backend Call - API Secret key stays on backend)
  static Future<Map<String, dynamic>?> createRazorpayOrder(double amount) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Please login first'};

      final response = await _post(
        Uri.parse('$baseUrl/payments/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        data['success'] = true;
        return data;
      }
      data['success'] = false;
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Verify Razorpay Payment (Secure Backend Verification using SHA256 HMAC)
  static Future<Map<String, dynamic>?> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required double amount,
    String? bookingId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Please login first'};

      final response = await _post(
        Uri.parse('$baseUrl/payments/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
          'amount': amount,
          if (bookingId != null) 'booking_id': bookingId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        data['success'] = true;
        return data;
      }
      data['success'] = false;
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

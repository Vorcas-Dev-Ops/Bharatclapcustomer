import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
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
    if (response.statusCode >= 500) {
      debugPrint('[ApiService] Server response status: ${response.statusCode}');
    }
  }

  static void _handleError(Object e) {
    debugPrint('[ApiService] Connection error: $e');
  }

  static String? _extractRefreshTokenFromHeaders(Map<String, String> headers) {
    final rawCookie = headers['set-cookie'] ?? headers['Set-Cookie'];
    if (rawCookie != null && rawCookie.isNotEmpty) {
      final cookies = rawCookie.split(',');
      for (var cookie in cookies) {
        final trimmed = cookie.trim();
        if (trimmed.startsWith('jwt=')) {
          final parts = trimmed.split(';');
          if (parts.isNotEmpty) {
            return parts[0].substring(4); // Remove 'jwt=' prefix
          }
        }
      }
    }
    return null;
  }

  static Future<bool>? _refreshFuture;

  static Future<bool> _performTokenRefresh() async {
    try {
      final refreshToken = await getRefreshToken();
      final currentToken = await getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/users/refresh'),
        headers: {
          'Content-Type': 'application/json',
          if (refreshToken != null && refreshToken.isNotEmpty) 'Cookie': 'jwt=$refreshToken',
          if (currentToken != null && currentToken.isNotEmpty) 'Authorization': 'Bearer $currentToken',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'] ?? data['accessToken'];
        if (newToken != null && newToken is String && newToken.isNotEmpty) {
          final newRefreshToken = _extractRefreshTokenFromHeaders(response.headers);
          await saveToken(newToken, refreshToken: newRefreshToken);
          return true;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Token refresh failed: $e');
    }
    return false;
  }

  static Future<bool> _refreshAccessToken() async {
    _refreshFuture ??= _performTokenRefresh();
    final success = await _refreshFuture;
    _refreshFuture = null;
    return success ?? false;
  }

  static Future<http.Response> _get(Uri url, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 401 && !url.path.endsWith('/users/refresh') && !url.path.endsWith('/users/verify-otp')) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final newToken = await getToken();
          final updatedHeaders = Map<String, String>.from(headers ?? {});
          if (newToken != null) updatedHeaders['Authorization'] = 'Bearer $newToken';
          return await http.get(url, headers: updatedHeaders);
        }
      }
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
      if (response.statusCode == 401 && !url.path.endsWith('/users/refresh') && !url.path.endsWith('/users/verify-otp')) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final newToken = await getToken();
          final updatedHeaders = Map<String, String>.from(headers ?? {});
          if (newToken != null) updatedHeaders['Authorization'] = 'Bearer $newToken';
          return await http.post(url, headers: updatedHeaders, body: body);
        }
      }
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
      if (response.statusCode == 401 && !url.path.endsWith('/users/refresh') && !url.path.endsWith('/users/verify-otp')) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final newToken = await getToken();
          final updatedHeaders = Map<String, String>.from(headers ?? {});
          if (newToken != null) updatedHeaders['Authorization'] = 'Bearer $newToken';
          return await http.put(url, headers: updatedHeaders, body: body);
        }
      }
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
      if (response.statusCode == 401 && !url.path.endsWith('/users/refresh') && !url.path.endsWith('/users/verify-otp')) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final newToken = await getToken();
          final updatedHeaders = Map<String, String>.from(headers ?? {});
          if (newToken != null) updatedHeaders['Authorization'] = 'Bearer $newToken';
          return await http.delete(url, headers: updatedHeaders, body: body);
        }
      }
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
      if (response.statusCode == 401 && !url.path.endsWith('/users/refresh') && !url.path.endsWith('/users/verify-otp')) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final newToken = await getToken();
          final updatedHeaders = Map<String, String>.from(headers ?? {});
          if (newToken != null) updatedHeaders['Authorization'] = 'Bearer $newToken';
          return await http.patch(url, headers: updatedHeaders, body: body);
        }
      }
      _checkResponse(response);
      return response;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Helper to save token
  static Future<void> saveToken(String token, {String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  // Helper to get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
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
    await prefs.remove(_refreshTokenKey);
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
        String? refreshToken = user?['refreshToken'] ?? data['refreshToken'];
        if (refreshToken == null || refreshToken.isEmpty) {
          refreshToken = _extractRefreshTokenFromHeaders(response.headers);
        }
        if (token != null && token != 'pending_auth_token') {
          await saveToken(token, refreshToken: refreshToken);
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Register User
  static Future<Map<String, dynamic>> registerUser(String phone, String name, [String? email, String? gender, String? password]) async {
    try {
      final Map<String, dynamic> body = {'phone': cleanPhone(phone), 'name': name};
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      if (gender != null && gender.isNotEmpty) {
        body['gender'] = gender;
      }
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await _post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;

      if (data['success'] == true) {
        final token = data['token'] ?? (data['user'] != null ? data['user']['token'] : null);
        final refreshToken = _extractRefreshTokenFromHeaders(response.headers);
        if (token != null) {
          await saveToken(token, refreshToken: refreshToken);
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
        final refreshToken = _extractRefreshTokenFromHeaders(response.headers);
        if (token != null) {
          await saveToken(token, refreshToken: refreshToken);
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
        final token = data['token'] ?? (data['user'] != null ? data['user']['token'] : null);
        final refreshToken = _extractRefreshTokenFromHeaders(response.headers);
        if (token != null) {
          await saveToken(token, refreshToken: refreshToken);
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
        if (data != null) {
          if (data['data'] is List) {
            return data['data'];
          } else if (data is List) {
            return data;
          } else if (data['bookings'] is List) {
            return data['bookings'];
          }
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
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] != null && decoded['data'] is Map<String, dynamic>) {
            return decoded['data'] as Map<String, dynamic>;
          }
          if (decoded['booking'] != null && decoded['booking'] is Map<String, dynamic>) {
            return decoded['booking'] as Map<String, dynamic>;
          }
          return decoded;
        }
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
          'location_id': ?locationId,
          'location_name': ?locationName,
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

  // Request Account Deletion (DPDPA Right to Erasure - 30 days cooling period)
  static Future<Map<String, dynamic>> requestAccountDeletion({String? reason}) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await _post(
        Uri.parse('$baseUrl/users/deletion/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'status': data['status'],
          'scheduled_deletion_date': data['scheduled_deletion_date'] ?? data['scheduled_date'],
          'blocking_obligations': data['blocking_obligations'],
          'message': data['message'] ?? 'Account deletion request initiated',
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to request account deletion'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to request account deletion: $e'};
    }
  }

  // Cancel Account Deletion Request
  static Future<Map<String, dynamic>> cancelAccountDeletion() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await _delete(
        Uri.parse('$baseUrl/users/me/delete-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Account deletion request cancelled successfully'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to cancel deletion request'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to cancel account deletion: $e'};
    }
  }

  // Export User Data (DPDPA Data Portability)
  static Future<Map<String, dynamic>> exportUserData() async {
    try {
      final token = await getToken();
      final response = await _get(
        Uri.parse('$baseUrl/users/me/export'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Failed to export user data'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to export user data: $e'};
    }
  }

  static String _normalizeDateString(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    String d = dateStr.trim();
    if (d.contains('T')) {
      d = d.split('T')[0];
    } else if (d.contains(' ')) {
      d = d.split(' ')[0];
    }
    return d;
  }

  // Update Slot for Cart Item
  static Future<Map<String, dynamic>?> updateSlot(String subserviceId, String selectedDate, String selectedTimeSlot) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final cleanDate = _normalizeDateString(selectedDate);

      final response = await _put(
        Uri.parse('$baseUrl/cart/slot'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subservice_id': subserviceId,
          'selected_date': cleanDate,
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

  // Validate Multi-Service Schedule & Get Signed Schedule Token
  static Future<Map<String, dynamic>> validateSchedule({
    required String addressId,
    String? preferredDate,
    String? preferredStartTime,
    String schedulingMode = 'sequential',
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'available': false, 'message': 'Not logged in'};

      final cleanDate = _normalizeDateString(preferredDate);

      final response = await _post(
        Uri.parse('$baseUrl/bookings/validate-schedule'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'address_id': addressId,
          'preferred_date': cleanDate.isNotEmpty ? cleanDate : null,
          'preferred_start_time': preferredStartTime,
          'scheduling_mode': schedulingMode,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }
      return {'available': false, 'message': data['message'] ?? 'Schedule validation failed'};
    } catch (e) {
      return {'available': false, 'message': 'Network error during schedule validation'};
    }
  }

  // Checkout / Create Booking
  static Future<Map<String, dynamic>?> createBooking(
    String addressId,
    String paymentMethod, {
    String? couponCode,
    String? paymentId,
    String? scheduleToken,
    String? preferredDate,
    String? preferredStartTime,
    String schedulingMode = 'sequential',
  }) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final cleanDate = _normalizeDateString(preferredDate);

      final Map<String, dynamic> body = {
        'address': addressId,
        'payment_method': paymentMethod,
        'scheduling_mode': schedulingMode,
      };
      if (couponCode != null && couponCode.isNotEmpty) {
        body['coupon_code'] = couponCode;
      }
      if (paymentId != null && paymentId.isNotEmpty) {
        body['payment_id'] = paymentId;
      }
      if (scheduleToken != null && scheduleToken.isNotEmpty) {
        body['schedule_token'] = scheduleToken;
      }
      if (cleanDate.isNotEmpty) {
        body['preferred_date'] = cleanDate;
      }
      if (preferredStartTime != null && preferredStartTime.isNotEmpty) {
        body['preferred_start_time'] = preferredStartTime;
      }
      if (preferredStartTime != null && preferredStartTime.isNotEmpty) {
        body['preferred_start_time'] = preferredStartTime;
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
          'booking_id': ?bookingId,
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

  // Create Review for Service and Provider
  static Future<Map<String, dynamic>> createReview({
    required String bookingId,
    required String providerId,
    required String serviceId,
    required String subserviceId,
    required int rating,
    required String comment,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await _post(
        Uri.parse('$baseUrl/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': bookingId,
          'provider_id': providerId,
          'service_id': serviceId,
          'subservice_id': subserviceId,
          'rating': rating,
          'comment': comment,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        data['success'] = true;
        return data;
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to submit review'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get Reviews for a Provider
  static Future<List<dynamic>> getProviderReviews(String providerId) async {
    try {
      final response = await _get(Uri.parse('$baseUrl/reviews/provider/$providerId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Resend Completion OTP for a booking (type: 'end')
  static Future<Map<String, dynamic>> resendCompletionOtp(String bookingId) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await _post(
        Uri.parse('$baseUrl/bookings/$bookingId/resend-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'type': 'end'}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Completion OTP sent to your phone!'};
      }
      return {'success': false, 'message': data['message'] ?? data['error'] ?? 'Failed to resend completion OTP'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get Invoice URL for completed booking
  static String getInvoiceUrl(String bookingId) {
    return '$baseUrl/payments/invoices/$bookingId';
  }

  // Fetch Chat Conversations / Messages
  static Future<Map<String, dynamic>> getChatMessages(String bookingId) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final rawId = bookingId.replaceAll('CHAT-BKG-', '');
      final convId = 'CHAT-BKG-$rawId';

      var response = await _get(
        Uri.parse('$baseUrl/chat/conversations/$convId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final payload = data['data'] ?? data;
        return {'success': true, 'data': payload};
      }

      // Fallback: Query conversation by booking_id
      final convResponse = await _get(
        Uri.parse('$baseUrl/chat/conversations?booking_id=$rawId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (convResponse.statusCode == 200) {
        final convData = jsonDecode(convResponse.body);
        final convPayload = convData['data'] ?? convData;
        if (convPayload is List && convPayload.isNotEmpty) {
          final firstConv = convPayload.first;
          final actualConvId = firstConv['conversation_id'] ?? firstConv['_id'];
          if (actualConvId != null) {
            final msgResponse = await _get(
              Uri.parse('$baseUrl/chat/conversations/$actualConvId/messages'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            );
            if (msgResponse.statusCode == 200) {
              final msgData = jsonDecode(msgResponse.body);
              return {'success': true, 'data': msgData['data'] ?? msgData};
            }
          }
        }
      }

      return {'success': false, 'message': 'Failed to load chat'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Send Chat Message
  static Future<Map<String, dynamic>> sendChatMessage({
    required String bookingId,
    required String text,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final convId = bookingId.startsWith('CHAT-BKG-') ? bookingId : 'CHAT-BKG-$bookingId';
      final response = await _post(
        Uri.parse('$baseUrl/chat/conversations/$convId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bookingId': bookingId,
          'text': text,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data'] ?? data};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to send message'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get Chat Conversations
  static Future<List<dynamic>> getChatConversations() async {
    try {
      final token = await getToken();
      if (token == null) return [];
      final response = await _get(
        Uri.parse('$baseUrl/chat/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final payload = data['data'] ?? data;
        if (payload is List) return payload;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Initiate Phone Change (Send OTP)
  static Future<Map<String, dynamic>> initiatePhoneChange(String newPhone) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await _post(
        Uri.parse('$baseUrl/users/phone-change/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'newPhone': newPhone}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'OTP sent to new phone number'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to initiate phone change'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Verify Phone Change (Confirm OTP & Update)
  static Future<Map<String, dynamic>> verifyPhoneChange(String newPhone, String otp) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await _post(
        Uri.parse('$baseUrl/users/phone-change/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'newPhone': newPhone,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Phone number updated successfully!', 'user': data['user'] ?? data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP or verification failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}


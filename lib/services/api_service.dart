import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    String url = dotenv.env['NEXT_PUBLIC_API_URL'] ?? 'http://localhost:5000/api';
    if (!kIsWeb && Platform.isAndroid) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
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
    return token != null && token.isNotEmpty;
  }

  // Send OTP
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': phone,
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
      final response = await http.post(
        Uri.parse('$baseUrl/users/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': phone,
          'otp': otp,
          'useEmail': false
        }),
      );

      final data = jsonDecode(response.body);
      data['success'] = response.statusCode == 200 || response.statusCode == 201;
      
      if (data['success'] == true) {
        // Handle token which might be nested under user object
        if (data['user'] != null && data['user']['token'] != null && data['user']['token'] != 'pending_auth_token') {
          await saveToken(data['user']['token']);
        } else if (data['token'] != null) {
          await saveToken(data['token']);
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
      final Map<String, dynamic> body = {'phone': phone, 'name': name};
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      if (gender != null && gender.isNotEmpty) {
        body['gender'] = gender;
      }

      final response = await http.post(
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

  // Add Address
  static Future<Map<String, dynamic>> addAddress(Map<String, dynamic> addressData) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
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

  // Get User Profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
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

  // Get Categories
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
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

  // Get Services by Category
  static Future<List<dynamic>> getServices(String categoryId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/services?category_id=$categoryId'));
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
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/notification_sync_service.dart';
import 'bookings/booking_details_screen.dart';
import 'bookings/track_service_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        setState(() {
          _notifications = body['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      await http.put(
        Uri.parse('${ApiService.baseUrl}/notifications/$id/read'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      _fetchNotifications();
    } catch (_) {}
  }

  bool get _hasUnread => _notifications.any((item) => item['is_read'] != true);

  Future<void> _markAllAsRead() async {
    final unreadItems = _notifications.where((item) => item['is_read'] != true).toList();
    if (unreadItems.isEmpty) return;

    setState(() {
      for (var item in _notifications) {
        if (item is Map) {
          item['is_read'] = true;
        }
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final futures = unreadItems.map((item) {
        final id = item['_id']?.toString() ?? item['id']?.toString();
        if (id != null) {
          return http.put(
            Uri.parse('${ApiService.baseUrl}/notifications/$id/read'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          );
        }
        return Future.value(null);
      });
      await Future.wait(futures);
    } catch (_) {}

    _fetchNotifications();
    NotificationSyncService.fetchAndUpdate();
  }

  String? _extractBookingId(Map<String, dynamic> item) {
    if (item['booking_id'] != null && item['booking_id'].toString().trim().isNotEmpty) {
      return item['booking_id'].toString().trim();
    }
    if (item['bookingId'] != null && item['bookingId'].toString().trim().isNotEmpty) {
      return item['bookingId'].toString().trim();
    }

    var metadata = item['metadata'];
    if (metadata is String && metadata.trim().startsWith('{')) {
      try {
        metadata = json.decode(metadata);
      } catch (_) {}
    }
    if (metadata is Map) {
      if (metadata['booking_id'] != null && metadata['booking_id'].toString().trim().isNotEmpty) {
        return metadata['booking_id'].toString().trim();
      }
      if (metadata['bookingId'] != null && metadata['bookingId'].toString().trim().isNotEmpty) {
        return metadata['bookingId'].toString().trim();
      }
      if (metadata['booking'] != null && metadata['booking'].toString().trim().isNotEmpty) {
        return metadata['booking'].toString().trim();
      }
      if (metadata['_id'] != null && metadata['_id'].toString().trim().isNotEmpty) {
        return metadata['_id'].toString().trim();
      }
    }

    var data = item['data'];
    if (data is String && data.trim().startsWith('{')) {
      try {
        data = json.decode(data);
      } catch (_) {}
    }
    if (data is Map) {
      if (data['booking_id'] != null && data['booking_id'].toString().trim().isNotEmpty) {
        return data['booking_id'].toString().trim();
      }
      if (data['bookingId'] != null && data['bookingId'].toString().trim().isNotEmpty) {
        return data['bookingId'].toString().trim();
      }
    }

    final text = '${item['title'] ?? ''} ${item['message'] ?? ''}';
    final regExp = RegExp(r'BK-[A-Z0-9]+', caseSensitive: false);
    final match = regExp.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.done_all,
              color: _hasUnread ? const Color(0xFF1E1B4B) : Colors.grey.shade400,
            ),
            tooltip: 'Mark all as read',
            onPressed: _hasUnread ? _markAllAsRead : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No notifications yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final isRead = item['is_read'] ?? false;
                          final title = item['title'] ?? 'Notification';
                          final message = item['message'] ?? '';

                          return ListTile(
                            tileColor: isRead ? Colors.white : const Color(0xFFF0F7FF),
                            leading: CircleAvatar(
                              backgroundColor: isRead ? Colors.grey.shade200 : const Color(0xFF1E1B4B),
                              child: Icon(
                                isRead ? Icons.notifications_outlined : Icons.notifications_active,
                                color: isRead ? Colors.grey : Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text(message),
                            onTap: () {
                              if (!isRead) {
                                _markAsRead(item['_id']);
                                NotificationSyncService.fetchAndUpdate();
                              }
                              if (item is Map) {
                                final bId = _extractBookingId(Map<String, dynamic>.from(item));
                                if (bId != null && bId.isNotEmpty) {
                                  final titleLower = (title).toString().toLowerCase();
                                  final messageLower = (message).toString().toLowerCase();
                                  final typeLower = (item['type'] ?? '').toString().toLowerCase();

                                  final isRateNotif = titleLower.contains('rate') ||
                                      titleLower.contains('review') ||
                                      messageLower.contains('rate') ||
                                      messageLower.contains('review') ||
                                      typeLower.contains('rate') ||
                                      typeLower.contains('review');

                                  final isActiveTrackingNotif = titleLower.contains('started') ||
                                      titleLower.contains('arrived') ||
                                      titleLower.contains('way') ||
                                      titleLower.contains('otp');

                                  if (isRateNotif) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingDetailsScreen(
                                          bookingId: bId,
                                          autoOpenRate: true,
                                        ),
                                      ),
                                    );
                                  } else if (isActiveTrackingNotif) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TrackServiceScreen(bookingId: bId),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingDetailsScreen(bookingId: bId),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}


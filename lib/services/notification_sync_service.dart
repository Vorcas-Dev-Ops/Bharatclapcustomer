import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'notification_service.dart';

class NotificationSyncService {
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static Timer? _timer;
  static final Set<String> _shownNotificationIds = <String>{};

  static void startSync() {
    _timer?.cancel();
    fetchAndUpdate();
    // Poll every 12 seconds
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      fetchAndUpdate();
    });
  }

  static void stopSync() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> fetchAndUpdate() async {
    try {
      final notifications = await ApiService.getNotifications();
      if (notifications.isEmpty) {
        unreadCountNotifier.value = 0;
        return;
      }

      int unread = 0;
      for (var item in notifications) {
        final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
        final isRead = item['is_read'] == true;
        final title = item['title'] ?? 'Notification';
        final message = item['message'] ?? item['body'] ?? '';
        final type = item['type'] ?? '';

        if (!isRead) {
          unread++;
          // Exclude OTP login notifications as per user requirement
          if (id.isNotEmpty && !_shownNotificationIds.contains(id) && !type.contains('otp')) {
            _shownNotificationIds.add(id);
            int notifId = id.hashCode.abs() % 100000;
            Map<String, dynamic> payloadMap = {};
            if (item['metadata'] != null && item['metadata'] is Map) {
              payloadMap = Map<String, dynamic>.from(item['metadata']);
            }
            if (!payloadMap.containsKey('booking_id') && item['booking_id'] != null) {
              payloadMap['booking_id'] = item['booking_id'];
            }
            payloadMap['type'] = type;

            NotificationService.showNotification(
              id: notifId,
              title: title,
              body: message,
              payload: jsonEncode(payloadMap),
            );
          }
        }
      }
      unreadCountNotifier.value = unread;
    } catch (e) {
      // Ignore network errors during background sync
    }
  }
}

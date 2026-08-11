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
      int unread = 0;
      if (notifications.isNotEmpty) {
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
      }
      unreadCountNotifier.value = unread;

      // Sync unread chat notifications from conversations or active bookings
      try {
        final chatRes = await ApiService.getChatConversations();
        if (chatRes is List && chatRes.isNotEmpty) {
          for (var conv in chatRes) {
            final unreadCust = (conv['unread_count_customer'] as num?)?.toInt() ?? 0;
            final lastMsg = conv['last_message'] ?? '';
            final convId = conv['conversation_id'] ?? conv['_id'] ?? '';
            final bookingId = conv['booking_id'] ?? convId.toString().replaceAll('CHAT-BKG-', '');
            final providerName = conv['provider']?['name'] ?? 'Provider';

            if (unreadCust > 0 && lastMsg.isNotEmpty) {
              final notifKey = 'chat_${convId}_${lastMsg.hashCode}';
              if (!_shownNotificationIds.contains(notifKey)) {
                _shownNotificationIds.add(notifKey);
                NotificationService.showNotification(
                  id: notifKey.hashCode.abs() % 100000,
                  title: 'New message from $providerName',
                  body: lastMsg,
                  payload: jsonEncode({'booking_id': bookingId, 'type': 'chat'}),
                );
              }
            }
          }
        }

        // Direct active booking chat check fallback
        final bookings = await ApiService.getMyBookings();
        for (var booking in bookings.take(10)) {
          final bId = (booking['booking_id'] ?? booking['display_id'] ?? booking['_id'] ?? booking['id'])?.toString();
          if (bId == null || bId.isEmpty) continue;
          
          final status = (booking['status'] ?? '').toString().toLowerCase();
          final isCompleted = ['completed', 'finished', 'cancelled', 'canceled', 'rejected'].contains(status);
          if (isCompleted) continue;

          final chatRes = await ApiService.getChatMessages(bId);
          if (chatRes['success'] == true && chatRes['data'] != null) {
            final payload = chatRes['data'];
            List<dynamic> messagesList = [];
            if (payload is Map && payload['messages'] is List) {
              messagesList = payload['messages'];
            } else if (payload is List) {
              messagesList = payload;
            }

            if (messagesList.isNotEmpty) {
              final lastMsg = messagesList.last;
              if (lastMsg is Map) {
                final senderRole = (lastMsg['sender_role'] ?? lastMsg['senderRole'] ?? '').toString().toLowerCase();
                final msgId = (lastMsg['_id'] ?? lastMsg['id'] ?? lastMsg['createdAt'])?.toString() ?? '';
                final text = (lastMsg['text'] ?? lastMsg['message'] ?? '').toString();
                final senderName = (lastMsg['sender_name'] ?? lastMsg['senderName'] ?? 'Provider').toString();

                if (senderRole != 'customer' && text.isNotEmpty && msgId.isNotEmpty) {
                  final notifKey = 'chat_msg_$msgId';
                  if (!_shownNotificationIds.contains(notifKey)) {
                    _shownNotificationIds.add(notifKey);
                    NotificationService.showNotification(
                      id: notifKey.hashCode.abs() % 100000,
                      title: 'New message from $senderName',
                      body: text,
                      payload: jsonEncode({'booking_id': bId, 'type': 'chat'}),
                    );
                  }
                }
              }
            }
          }
        }
      } catch (_) {}
    } catch (e) {
      // Ignore network errors during background sync
    }
  }
}

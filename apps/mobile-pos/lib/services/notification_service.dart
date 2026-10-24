import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/notification_provider.dart';

/// Firebase Cloud Messaging (FCM) & Push Notification Client Service
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  bool _isInitialized = false;

  /// Initialize Firebase FCM client listener
  Future<void> initialize(WidgetRef ref) async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Simulate / Acquire FCM device token for push broadcasts
    _fcmToken = 'fcm_token_${DateTime.now().millisecondsSinceEpoch}_omniluxe_device';
    debugPrint('[Firebase FCM] Device push token initialized: $_fcmToken');

    // Sync token with Central Cloud ERP if user is logged in
    await syncTokenWithBackend(_fcmToken!);
  }

  /// Sync device push token with Laravel Central API
  Future<bool> syncTokenWithBackend(String token, {String? authToken}) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/v1/customer/device-token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'device_token': token,
          'platform': defaultTargetPlatform.name,
          'provider': 'firebase_fcm',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[Firebase FCM] Token sync skipped (offline or unauthenticated): $e');
      return false;
    }
  }

  /// Fetch persistent notifications from Central API inbox
  Future<List<NotificationItem>> fetchNotificationsFromBackend(
    WidgetRef ref, {
    String? authToken,
    String? customerUuid,
  }) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/v1/customer/notifications');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
          if (customerUuid != null) 'X-Customer-Uuid': customerUuid,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] ?? [];
        final items = list.map((item) {
          return NotificationItem(
            id: item['uuid']?.toString() ?? item['id']?.toString() ?? '',
            title: item['title']?.toString() ?? '',
            body: item['body']?.toString() ?? '',
            type: item['type']?.toString() ?? 'order',
            timestamp: item['created_at'] != null
                ? DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
            isRead: item['read'] == true,
            payload: item['data'] != null ? jsonEncode(item['data']) : null,
          );
        }).toList();

        if (items.isNotEmpty) {
          ref.read(notificationProvider.notifier).setNotifications(items);
        }
        return items;
      }
    } catch (e) {
      debugPrint('[Notifications] Fetch from central API skipped: $e');
    }
    return [];
  }

  /// Mark single notification as read on Central API
  Future<bool> markAsReadOnBackend(String uuid, {String? authToken, String? customerUuid}) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/v1/customer/notifications/$uuid/read');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
          if (customerUuid != null) 'X-Customer-Uuid': customerUuid,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[Notifications] Mark read remote call skipped: $e');
      return false;
    }
  }

  /// Mark all notifications as read on Central API
  Future<bool> markAllAsReadOnBackend({String? authToken, String? customerUuid}) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/v1/customer/notifications/read-all');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
          if (customerUuid != null) 'X-Customer-Uuid': customerUuid,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[Notifications] Mark all read remote call skipped: $e');
      return false;
    }
  }

  /// Trigger a simulated incoming FCM push notification or Reverb WebSocket event
  void handleIncomingRemoteMessage(
    WidgetRef ref, {
    required String title,
    required String body,
    required String type,
    String? payload,
    String? id,
  }) {
    ref.read(notificationProvider.notifier).addNotification(
          title: title,
          body: body,
          type: type,
          payload: payload,
          id: id,
        );
  }
}

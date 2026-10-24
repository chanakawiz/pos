import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type; // 'order', 'vip', 'promo', 'security'
  final DateTime timestamp;
  final bool isRead;
  final String? payload;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.payload,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? payload,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }
}

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier()
      : super([
          NotificationItem(
            id: 'notif-1',
            title: 'Welcome to OmniLuxe Privilege VIP',
            body: '100 Welcome Points have been credited to your digital VIP card. Enjoy exclusive boutique perks!',
            type: 'vip',
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            isRead: false,
          ),
          NotificationItem(
            id: 'notif-2',
            title: 'Order Dispatched (Express Delivery)',
            body: 'Your order ORD-2026-0819 has been packed and handed over to our white-glove courier.',
            type: 'order',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: false,
          ),
          NotificationItem(
            id: 'notif-3',
            title: 'New Department Arrivals: Designer Fragrance',
            body: 'Explore our newly curated Dior Sauvage and luxury accessories now in-stock at Colombo boutique.',
            type: 'promo',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            isRead: true,
          ),
          NotificationItem(
            id: 'notif-4',
            title: 'Verified SMS Digital Warranty Dispatched',
            body: 'Official tamper-evident digital warranty link was successfully routed to your verified mobile.',
            type: 'security',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            isRead: true,
          ),
        ]);

  int get unreadCount => state.where((n) => !n.isRead).length;

  void setNotifications(List<NotificationItem> items) {
    state = items;
  }

  void markAsRead(String id) {
    state = state.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void addNotification({
    required String title,
    required String body,
    required String type,
    String? id,
    String? payload,
    DateTime? timestamp,
  }) {
    final newItem = NotificationItem(
      id: id ?? 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      timestamp: timestamp ?? DateTime.now(),
      isRead: false,
      payload: payload,
    );
    state = [newItem, ...state];
  }

  void clearAll() {
    state = [];
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationProvider);
  return notifs.where((n) => !n.isRead).length;
});

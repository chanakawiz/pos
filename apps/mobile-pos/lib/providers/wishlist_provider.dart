import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../data/models/product.dart';

class WishlistState {
  final Set<String> savedProductKeys;
  final Set<String> alertSubscribedKeys;
  final String sessionToken;
  final bool isSubmitting;
  final String? statusMessage;

  const WishlistState({
    this.savedProductKeys = const {},
    this.alertSubscribedKeys = const {},
    this.sessionToken = 'mobile-guest-omniluxe',
    this.isSubmitting = false,
    this.statusMessage,
  });

  static String keyFor(ProductModel product) =>
      product.id?.toString() ?? product.uuid;

  bool isSaved(ProductModel product) =>
      savedProductKeys.contains(keyFor(product));

  bool hasStockAlert(ProductModel product) =>
      alertSubscribedKeys.contains(keyFor(product));

  int get savedCount => savedProductKeys.length;

  WishlistState copyWith({
    Set<String>? savedProductKeys,
    Set<String>? alertSubscribedKeys,
    String? sessionToken,
    bool? isSubmitting,
    String? statusMessage,
  }) {
    return WishlistState(
      savedProductKeys: savedProductKeys ?? this.savedProductKeys,
      alertSubscribedKeys: alertSubscribedKeys ?? this.alertSubscribedKeys,
      sessionToken: sessionToken ?? this.sessionToken,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      statusMessage: statusMessage,
    );
  }
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  WishlistNotifier() : super(const WishlistState());

  Future<bool> toggleWishlist(
    ProductModel product, {
    String? variantLabel,
  }) async {
    final key = WishlistState.keyFor(product);
    final updated = Set<String>.from(state.savedProductKeys);
    final bool nowSaved;

    if (updated.contains(key)) {
      updated.remove(key);
      nowSaved = false;
    } else {
      updated.add(key);
      nowSaved = true;
    }

    state = state.copyWith(
      savedProductKeys: updated,
      statusMessage: nowSaved
          ? 'Saved to your OmniLuxe Wishlist'
          : 'Removed from Wishlist',
    );

    if (product.id != null) {
      try {
        await ApiClient.instance.dio.post(
          '/api/v1/wishlist/toggle',
          data: {
            'product_id': product.id,
            'session_token': state.sessionToken,
            if (variantLabel != null && variantLabel.trim().isNotEmpty)
              'variant_label': variantLabel.trim(),
          },
          options: Options(
            sendTimeout: const Duration(seconds: 2),
            receiveTimeout: const Duration(seconds: 2),
          ),
        );
      } catch (_) {
        // Optimistic wishlist state retained when offline
      }
    }

    return nowSaved;
  }

  Future<bool> subscribeBackInStock({
    required ProductModel product,
    required String phone,
    String? customerName,
    String? email,
  }) async {
    final trimmedPhone = phone.trim();
    final trimmedEmail = email?.trim() ?? '';

    if (trimmedPhone.isEmpty && trimmedEmail.isEmpty) {
      state = state.copyWith(
        statusMessage: 'Enter a mobile number or email for restock alerts.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, statusMessage: null);
    final identifier = product.id?.toString() ?? product.uuid;

    try {
      await ApiClient.instance.dio.post(
        '/api/v1/products/$identifier/notify-stock',
        data: {
          if (trimmedPhone.isNotEmpty) 'phone': trimmedPhone,
          if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
          if (customerName != null && customerName.trim().isNotEmpty)
            'customer_name': customerName.trim(),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      // Offline optimistic subscription registration
    }

    if (!mounted) return false;

    final updatedAlerts = Set<String>.from(state.alertSubscribedKeys)
      ..add(WishlistState.keyFor(product));

    state = state.copyWith(
      alertSubscribedKeys: updatedAlerts,
      isSubmitting: false,
      statusMessage:
          "We'll SMS you immediately when ${product.name} is restocked.",
    );
    return true;
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) => WishlistNotifier(),
);

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/branch_stock.dart';
import '../models/pos_product.dart';
import 'pos_auth_provider.dart';

class PosBranchStockState {
  final PosProduct? selectedProduct;
  final List<BranchStock> stores;
  final bool isLoading;
  final bool isOfflineFallback;
  final String? errorMessage;

  const PosBranchStockState({
    this.selectedProduct,
    this.stores = const [],
    this.isLoading = false,
    this.isOfflineFallback = false,
    this.errorMessage,
  });

  double get totalNetworkAvailable =>
      stores.fold(0.0, (sum, s) => sum + s.quantityAvailable);

  int get branchesWithStock => stores.where((s) => !s.isOutOfStock).length;

  PosBranchStockState copyWith({
    PosProduct? selectedProduct,
    List<BranchStock>? stores,
    bool? isLoading,
    bool? isOfflineFallback,
    String? errorMessage,
  }) {
    return PosBranchStockState(
      selectedProduct: selectedProduct ?? this.selectedProduct,
      stores: stores ?? this.stores,
      isLoading: isLoading ?? this.isLoading,
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
      errorMessage: errorMessage,
    );
  }
}

class PosBranchStockNotifier extends StateNotifier<PosBranchStockState> {
  final Ref ref;

  PosBranchStockNotifier(this.ref) : super(const PosBranchStockState());

  Future<List<BranchStock>> lookupProductStock(PosProduct product) async {
    state = state.copyWith(
      selectedProduct: product,
      isLoading: true,
      isOfflineFallback: false,
      errorMessage: null,
    );

    final session = ref.read(posAuthProvider).session;

    try {
      final identifier = product.id > 0 ? product.id.toString() : product.sku;
      final uri = Uri.parse('${session.apiUrl}/api/v1/products/$identifier/cross-store-stock');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-Device-UUID': session.deviceUuid,
          if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['stores'] as List?) ?? [];
        final stores = list
            .map((s) => BranchStock.fromJson(Map<String, dynamic>.from(s)))
            .toList();
        if (mounted) {
          state = state.copyWith(
            stores: stores,
            isLoading: false,
            isOfflineFallback: false,
          );
        }
        return stores;
      }
    } catch (_) {
      // Offline boutique fallback
    }

    final fallback = _buildOfflineFallback(product);
    if (mounted) {
      state = state.copyWith(
        stores: fallback,
        isLoading: false,
        isOfflineFallback: true,
      );
    }
    return fallback;
  }

  List<BranchStock> _buildOfflineFallback(PosProduct product) {
    final flagshipQty = product.stock.toDouble();
    final kandyQty = (product.id % 3 == 0) ? 0.0 : ((product.stock * 0.4).ceil()).toDouble().clamp(2.0, 12.0);
    final galleQty = ((product.stock * 0.25).floor()).toDouble().clamp(1.0, 6.0);

    return [
      BranchStock(
        storeId: 1,
        storeCode: 'STORE-001',
        storeName: 'OmniLuxe Colombo Flagship',
        address: '42 Galle Road, Colombo 03',
        phone: '+94 11 234 5678',
        quantityOnHand: flagshipQty,
        quantityReserved: flagshipQty > 2 ? 1 : 0,
        quantityAvailable: (flagshipQty - (flagshipQty > 2 ? 1 : 0)).clamp(0.0, double.infinity),
      ),
      BranchStock(
        storeId: 2,
        storeCode: 'STORE-002',
        storeName: 'OmniLuxe Kandy Galleria',
        address: 'Level 2, Kandy City Centre',
        phone: '+94 81 223 4455',
        quantityOnHand: kandyQty,
        quantityReserved: 0,
        quantityAvailable: kandyQty,
      ),
      BranchStock(
        storeId: 3,
        storeCode: 'STORE-003',
        storeName: 'OmniLuxe Galle Fort Boutique',
        address: '18 Pedlar Street, Galle Fort',
        phone: '+94 91 224 7788',
        quantityOnHand: galleQty,
        quantityReserved: 0,
        quantityAvailable: galleQty,
      ),
    ];
  }
}

final posBranchStockProvider =
    StateNotifierProvider<PosBranchStockNotifier, PosBranchStockState>((ref) {
  return PosBranchStockNotifier(ref);
});

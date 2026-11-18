import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/pos_product.dart';
import 'pos_auth_provider.dart';

class PosCatalogState {
  final List<PosProduct> products;
  final List<PosProduct> filteredProducts;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const PosCatalogState({
    this.products = const [],
    this.filteredProducts = const [],
    this.categories = const ['All'],
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  PosCatalogState copyWith({
    List<PosProduct>? products,
    List<PosProduct>? filteredProducts,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PosCatalogState(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PosCatalogNotifier extends StateNotifier<PosCatalogState> {
  final Ref ref;

  PosCatalogNotifier(this.ref)
      : super(
          PosCatalogState(
            products: _fallbackCatalog,
            filteredProducts: _fallbackCatalog,
            categories: {'All', ..._fallbackCatalog.map((p) => p.category)}.toList(),
          ),
        ) {
    loadCatalog();
  }

  // Curated Luxury Flagship Catalog (Offline Fallback & Instant Demo)
  static final List<PosProduct> _fallbackCatalog = [
    const PosProduct(
      id: 1,
      uuid: 'prod-001',
      name: 'Apple iPhone 16 Pro Max 256GB (Space Black)',
      sku: 'TECH-IPH-16PM',
      barcode: '445566',
      category: 'Smartphones & Tech',
      brand: 'Apple',
      sellingPrice: 415000.00,
      costPrice: 370000.00,
      stock: 15,
      unit: 'device',
      warrantyPeriod: '1 Year Apple Care',
      requiresSerial: true,
      variants: ['256GB Space Black', '512GB Space Black', '1TB Natural Titanium'],
    ),
    const PosProduct(
      id: 2,
      uuid: 'prod-002',
      name: 'Samsung Galaxy S24 Ultra 512GB (Titanium Gray)',
      sku: 'TECH-SAM-S24U',
      barcode: '556677',
      category: 'Smartphones & Tech',
      brand: 'Samsung',
      sellingPrice: 385000.00,
      costPrice: 340000.00,
      stock: 12,
      unit: 'device',
      warrantyPeriod: '1 Year Samsung Care+',
      requiresSerial: true,
      variants: ['256GB Titanium Gray', '512GB Titanium Black'],
    ),
    const PosProduct(
      id: 3,
      uuid: 'prod-003',
      name: 'Apple AirPods Pro 2 (USB-C MagSafe)',
      sku: 'TECH-APP-APP2',
      barcode: '667788',
      category: 'Smartphones & Tech',
      brand: 'Apple',
      sellingPrice: 78500.00,
      costPrice: 68000.00,
      stock: 25,
      unit: 'pair',
      warrantyPeriod: '1 Year Official Warranty',
      requiresSerial: true,
    ),
    const PosProduct(
      id: 4,
      uuid: 'prod-004',
      name: 'Studio Ceylon Handloom Silk Linen Shirt',
      sku: 'FASH-SC-SLS',
      barcode: '112233',
      category: 'Designer Fashion',
      brand: 'Studio Ceylon',
      sellingPrice: 24500.00,
      costPrice: 15000.00,
      stock: 30,
      unit: 'piece',
      variants: ['Small', 'Medium', 'Large', 'X-Large'],
    ),
    const PosProduct(
      id: 5,
      uuid: 'prod-005',
      name: 'Nike Air Pegasus 40 Running Shoes (Black/Gold)',
      sku: 'FOOT-NK-PEG40',
      barcode: '223344',
      category: 'Footwear & Sneakers',
      brand: 'Nike',
      sellingPrice: 38500.00,
      costPrice: 28000.00,
      stock: 18,
      unit: 'pair',
      variants: ['UK 8', 'UK 9', 'UK 10', 'UK 11'],
    ),
    const PosProduct(
      id: 6,
      uuid: 'prod-006',
      name: 'Dior Sauvage Elixir Eau de Parfum 60ml',
      sku: 'BEAUTY-DR-SE60',
      barcode: '334455',
      category: 'Fragrances & Beauty',
      brand: 'Dior',
      sellingPrice: 56000.00,
      costPrice: 42000.00,
      stock: 14,
      unit: 'bottle',
    ),
    const PosProduct(
      id: 7,
      uuid: 'prod-007',
      name: 'Ralph Lauren Slim Fit Oxford Cotton Shirt',
      sku: 'FASH-RL-OXF',
      barcode: '778899',
      category: 'Designer Fashion',
      brand: 'Ralph Lauren',
      sellingPrice: 32000.00,
      costPrice: 21000.00,
      stock: 22,
      unit: 'piece',
      variants: ['Medium White', 'Large White', 'Medium Navy'],
    ),
    const PosProduct(
      id: 8,
      uuid: 'prod-008',
      name: 'Chanel Coco Mademoiselle Intense 100ml',
      sku: 'BEAUTY-CH-CMI',
      barcode: '889900',
      category: 'Fragrances & Beauty',
      brand: 'Chanel',
      sellingPrice: 62000.00,
      costPrice: 46000.00,
      stock: 10,
      unit: 'bottle',
    ),
  ];

  Future<void> loadCatalog() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final session = ref.read(posAuthProvider).session;
    List<PosProduct> fetched = [];

    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/products');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] ?? data['products'] ?? data;
        if (list is List && list.isNotEmpty) {
          fetched = list.map((item) => PosProduct.fromJson(item)).toList();
        }
      }
    } catch (_) {
      // Graceful offline fallback
    }

    final catalog = fetched.isNotEmpty ? fetched : _fallbackCatalog;
    final categories = {'All', ...catalog.map((p) => p.category)}.toList();

    if (!mounted) return;

    state = state.copyWith(
      products: catalog,
      filteredProducts: catalog,
      categories: categories,
      selectedCategory: 'All',
      isLoading: false,
    );
  }

  void filterByCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilters();
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = state.products;

    if (state.selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category == state.selectedCategory).toList();
    }

    if (state.searchQuery.trim().isNotEmpty) {
      final q = state.searchQuery.toLowerCase().trim();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.barcode.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q);
      }).toList();
    }

    state = state.copyWith(filteredProducts: filtered);
  }

  PosProduct? lookupByBarcode(String barcode) {
    final clean = barcode.trim();
    try {
      return state.products.firstWhere(
        (p) => p.barcode == clean || p.sku.toLowerCase() == clean.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

final posCatalogProvider = StateNotifierProvider<PosCatalogNotifier, PosCatalogState>((ref) {
  return PosCatalogNotifier(ref);
});

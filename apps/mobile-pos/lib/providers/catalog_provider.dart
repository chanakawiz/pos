import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../data/repositories/catalog_repository.dart';

class CatalogState {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final String? selectedCategoryUuid;
  final String searchQuery;
  final bool isLoading;
  final bool isBilingual;

  const CatalogState({
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryUuid,
    this.searchQuery = '',
    this.isLoading = false,
    this.isBilingual = true,
  });

  CatalogState copyWith({
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    String? selectedCategoryUuid,
    bool clearCategory = false,
    String? searchQuery,
    bool? isLoading,
    bool? isBilingual,
  }) {
    return CatalogState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryUuid: clearCategory ? null : (selectedCategoryUuid ?? this.selectedCategoryUuid),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isBilingual: isBilingual ?? this.isBilingual,
    );
  }
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final CatalogRepository _repo;

  CatalogNotifier(this._repo) : super(const CatalogState()) {
    loadCatalog();
  }

  Future<void> loadCatalog() async {
    state = state.copyWith(isLoading: true);
    final cats = await _repo.getCategories();
    final prods = await _repo.getProducts(
      categoryUuid: state.selectedCategoryUuid,
      search: state.searchQuery,
    );
    state = state.copyWith(
      categories: cats,
      products: prods,
      isLoading: false,
    );
  }

  void selectCategory(String? categoryUuid) {
    if (state.selectedCategoryUuid == categoryUuid) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryUuid: categoryUuid);
    }
    _filterProducts();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _filterProducts();
  }

  void toggleBilingual() {
    state = state.copyWith(isBilingual: !state.isBilingual);
  }

  Future<ProductModel?> findByBarcode(String barcode) async {
    return await _repo.findByBarcode(barcode);
  }

  Future<void> _filterProducts() async {
    final prods = await _repo.getProducts(
      categoryUuid: state.selectedCategoryUuid,
      search: state.searchQuery,
    );
    state = state.copyWith(products: prods);
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository();
});

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final repo = ref.watch(catalogRepositoryProvider);
  return CatalogNotifier(repo);
});

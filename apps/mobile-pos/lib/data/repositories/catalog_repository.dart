import '../../core/database/database_helper.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/product.dart';

class CatalogRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<ProductModel>> getProducts({String? categoryUuid, String? search}) async {
    return await _dbHelper.getAllProducts(categoryUuid: categoryUuid, search: search);
  }

  Future<ProductModel?> findByBarcode(String barcode) async {
    return await _dbHelper.findProductByBarcode(barcode);
  }

  Future<List<CategoryModel>> getCategories() async {
    return await _dbHelper.getAllCategories();
  }

  Future<List<CustomerModel>> searchCustomers(String query) async {
    return await _dbHelper.searchCustomers(query);
  }

  Future<List<CustomerModel>> getCustomers([String query = '']) async {
    return await _dbHelper.searchCustomers(query);
  }
}

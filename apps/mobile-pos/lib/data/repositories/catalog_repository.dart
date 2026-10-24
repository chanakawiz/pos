import 'package:uuid/uuid.dart';
import '../../core/network/api_client.dart';
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

  Future<CustomerModel> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    double creditLimit = 0.0,
  }) async {
    final newCustomer = CustomerModel(
      uuid: const Uuid().v4(),
      name: name,
      phone: phone,
      email: email,
      address: address,
      creditLimit: creditLimit,
      loyaltyPoints: 0,
      balance: 0.0,
    );

    await _dbHelper.insertCustomer(newCustomer);

    try {
      await ApiClient.instance.dio.post(
        '/api/v1/customers',
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
          if (address != null && address.isNotEmpty) 'address': address,
          'credit_limit': creditLimit,
        },
      );
    } catch (_) {
      // Offline fallback
    }

    return newCustomer;
  }
}

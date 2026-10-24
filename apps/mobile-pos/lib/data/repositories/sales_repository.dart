import '../../core/database/database_helper.dart';
import '../models/sale.dart';

class SalesRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> createSale(SaleModel sale) async {
    await _dbHelper.insertSale(sale);
  }

  Future<List<SaleModel>> getPendingSales() async {
    return await _dbHelper.getPendingSales();
  }

  Future<List<SaleModel>> getRecentSales({int limit = 50, String? search}) async {
    return await _dbHelper.getRecentSales(limit: limit, search: search);
  }

  Future<Map<String, dynamic>> getShiftSummary() async {
    return await _dbHelper.getShiftSummary();
  }
}

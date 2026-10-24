import 'package:dio/dio.dart';
import '../../core/database/database_helper.dart';
import '../../core/network/api_client.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/product.dart';

class SyncRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> pushPendingSales() async {
    final pendingSales = await _dbHelper.getPendingSales();
    if (pendingSales.isEmpty) return 0;

    final deviceUuid = _apiClient.deviceUuid;
    if (deviceUuid == null || deviceUuid.isEmpty) return 0;

    try {
      final payload = {
        'device_uuid': deviceUuid,
        'transactions': pendingSales.map((s) => s.toJson()).toList(),
      };

      final response = await _apiClient.dio.post(
        '/api/v1/sync/push',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<String> syncedUuids = [];
        if (data is Map<String, dynamic> && data['synced_uuids'] is List) {
          syncedUuids = (data['synced_uuids'] as List).map((u) => u.toString()).toList();
        } else {
          syncedUuids = pendingSales.map((s) => s.transactionUuid).toList();
        }
        await _dbHelper.markSalesSynced(syncedUuids);
        return syncedUuids.length;
      }
    } on DioException catch (_) {
      // Offline or network error, retain pending status for future retry
      return 0;
    }
    return 0;
  }

  Future<int> pullCatalogDelta() async {
    try {
      final currentVersion = await _dbHelper.getLastSyncVersion();
      final response = await _apiClient.dio.get(
        '/api/v1/sync/pull',
        queryParameters: {
          'since_version': currentVersion,
          if (_apiClient.deviceUuid != null) 'device_uuid': _apiClient.deviceUuid,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final newVersion = (data['current_version'] as int?) ?? currentVersion;

        int updatedCount = 0;

        // Categories
        if (data['categories'] is List) {
          final cats = (data['categories'] as List)
              .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
              .toList();
          await _dbHelper.upsertCategories(cats);
          updatedCount += cats.length;
        }

        // Products
        if (data['products'] is List) {
          final prods = (data['products'] as List)
              .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
              .toList();
          await _dbHelper.upsertProducts(prods);
          updatedCount += prods.length;
        }

        // Customers
        if (data['customers'] is List) {
          final custs = (data['customers'] as List)
              .map((c) => CustomerModel.fromJson(c as Map<String, dynamic>))
              .toList();
          await _dbHelper.upsertCustomers(custs);
          updatedCount += custs.length;
        }

        if (newVersion > currentVersion) {
          await _dbHelper.setLastSyncVersion(newVersion);
        }

        return updatedCount;
      }
    } on DioException catch (_) {
      // Offline, continue with cached local catalog
      return 0;
    }
    return 0;
  }
}

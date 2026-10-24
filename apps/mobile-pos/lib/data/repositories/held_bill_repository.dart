import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/network/api_client.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/held_bill.dart';

class HeldBillRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<HeldBillModel>> getHeldBills() async {
    try {
      final response = await ApiClient.instance.dio.get('/api/v1/held-bills');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final list = (response.data['data'] as List)
            .map((item) => HeldBillModel.fromMap(item as Map<String, dynamic>))
            .toList();

        // Sync to local SQLite
        for (final bill in list) {
          await _dbHelper.insertHeldBill(bill);
        }
        return list;
      }
    } catch (_) {
      // Offline fallback
    }

    return await _dbHelper.getAllHeldBills();
  }

  Future<HeldBillModel> holdBill({
    required List<CartItemModel> items,
    required double subtotal,
    required String cashierName,
    CustomerModel? customer,
    String? reference,
  }) async {
    final holdRef = reference ?? 'HOLD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final uuid = const Uuid().v4();

    final heldBill = HeldBillModel(
      uuid: uuid,
      holdReference: holdRef,
      cashierName: cashierName,
      customerName: customer?.name,
      customerPhone: customer?.phone,
      customerUuid: customer?.uuid,
      itemsCount: items.length,
      subtotal: subtotal,
      heldAt: DateTime.now(),
      items: items,
    );

    // Save locally
    await _dbHelper.insertHeldBill(heldBill);

    // Sync to backend if online
    try {
      final res = await ApiClient.instance.dio.post(
        '/api/v1/held-bills',
        data: {
          'hold_reference': holdRef,
          'cart_items_json': items.map((i) => i.toMap()).toList(),
          'subtotal': subtotal,
          if (customer?.uuid != null) 'customer_uuid': customer!.uuid,
        },
      );
      if (res.statusCode == 201 && res.data['data']?['uuid'] != null) {
        final serverUuid = res.data['data']['uuid'] as String;
        if (serverUuid != uuid) {
          await _dbHelper.deleteHeldBill(uuid);
          final updated = heldBill.copyWith(uuid: serverUuid);
          await _dbHelper.insertHeldBill(updated);
          return updated;
        }
      }
    } catch (_) {
      // Offline fallback
    }

    return heldBill;
  }

  Future<void> recallOrDeleteBill(String uuid) async {
    // Delete locally
    await _dbHelper.deleteHeldBill(uuid);

    // Delete on server if online
    try {
      await ApiClient.instance.dio.delete('/api/v1/held-bills/$uuid');
    } catch (_) {
      // Best-effort cloud deletion
    }
  }
}

final heldBillRepositoryProvider = Provider<HeldBillRepository>((ref) {
  return HeldBillRepository();
});

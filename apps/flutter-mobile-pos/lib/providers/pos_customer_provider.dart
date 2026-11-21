import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/pos_customer.dart';
import 'pos_auth_provider.dart';

class PosCustomerState {
  final List<PosCustomer> customers;
  final String searchQuery;
  final bool isLoading;
  final bool isCreating;
  final String? errorMessage;

  const PosCustomerState({
    this.customers = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.isCreating = false,
    this.errorMessage,
  });

  List<PosCustomer> get filteredCustomers {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return customers;
    return customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          (c.email?.toLowerCase().contains(q) ?? false) ||
          c.tierTitle.toLowerCase().contains(q);
    }).toList();
  }

  PosCustomerState copyWith({
    List<PosCustomer>? customers,
    String? searchQuery,
    bool? isLoading,
    bool? isCreating,
    String? errorMessage,
  }) {
    return PosCustomerState(
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: errorMessage,
    );
  }
}

class PosCustomerNotifier extends StateNotifier<PosCustomerState> {
  final Ref ref;

  static const List<PosCustomer> _defaultVipDirectory = [
    PosCustomer(
      id: 101,
      uuid: 'cust-vip-alexander',
      name: 'Alexander Wright',
      phone: '+94 77 123 4567',
      email: 'alexander@omniluxe.store',
      vipTier: 'gold',
      loyaltyPoints: 1450,
      totalSpend: 165000.0,
      creditLimit: 250000.0,
    ),
    PosCustomer(
      id: 102,
      uuid: 'cust-vip-natasha',
      name: 'Natasha Perera',
      phone: '+94 71 987 6543',
      email: 'natasha.perera@lifestyle.lk',
      vipTier: 'black',
      loyaltyPoints: 3420,
      totalSpend: 485000.0,
      creditLimit: 500000.0,
    ),
    PosCustomer(
      id: 103,
      uuid: 'cust-vip-dulantha',
      name: 'Dulantha Silva',
      phone: '+94 77 456 7890',
      email: 'dulantha@omniluxe.store',
      vipTier: 'gold',
      loyaltyPoints: 1120,
      totalSpend: 128000.0,
      creditLimit: 150000.0,
    ),
    PosCustomer(
      id: 104,
      uuid: 'cust-vip-amaya',
      name: 'Amaya Fernando',
      phone: '+94 76 321 0987',
      email: 'amaya.f@colombo.lk',
      vipTier: 'silver',
      loyaltyPoints: 350,
      totalSpend: 42000.0,
      creditLimit: 50000.0,
    ),
  ];

  PosCustomerNotifier(this.ref)
      : super(const PosCustomerState(customers: _defaultVipDirectory));

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Fetch customers from ERP `/api/v1/customers` with offline directory fallback
  Future<void> searchCustomers({String? query}) async {
    final search = query ?? state.searchQuery;
    state = state.copyWith(searchQuery: search, isLoading: true, errorMessage: null);
    final session = ref.read(posAuthProvider).session;

    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/customers').replace(
        queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          'per_page': '30',
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-Device-UUID': session.deviceUuid,
          if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
        final fetched = list
            .map((e) => PosCustomer.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (fetched.isNotEmpty) {
          state = state.copyWith(customers: fetched, isLoading: false);
          return;
        }
      }
    } catch (_) {
      // Offline fallback keeps cached VIP directory
    }

    state = state.copyWith(isLoading: false);
  }

  /// Quick register a new VIP customer from handheld POS
  Future<PosCustomer?> registerCustomer({
    required String name,
    required String phone,
    String? email,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    if (cleanName.isEmpty || cleanPhone.isEmpty) {
      state = state.copyWith(errorMessage: 'Customer name and mobile number are required.');
      return null;
    }

    state = state.copyWith(isCreating: true, errorMessage: null);
    final session = ref.read(posAuthProvider).session;
    PosCustomer? created;

    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/customers');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Device-UUID': session.deviceUuid,
              if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
            },
            body: jsonEncode({
              'name': cleanName,
              'phone': cleanPhone,
              if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final raw = data['customer'] ?? data['data'];
        if (raw is Map) {
          created = PosCustomer.fromJson(Map<String, dynamic>.from(raw));
        }
      }
    } catch (_) {
      // Offline fallback creates local VIP profile
    }

    created ??= PosCustomer(
      uuid: 'cust-${const Uuid().v4().substring(0, 8)}',
      name: cleanName,
      phone: cleanPhone,
      email: email?.trim().isNotEmpty == true ? email!.trim() : null,
      vipTier: 'silver',
      loyaltyPoints: 100, // Welcome VIP points
    );

    final updated = [created, ...state.customers.where((c) => c.uuid != created!.uuid)];
    state = state.copyWith(customers: updated, isCreating: false);
    return created;
  }
}

final posCustomerProvider = StateNotifierProvider<PosCustomerNotifier, PosCustomerState>((ref) {
  return PosCustomerNotifier(ref);
});

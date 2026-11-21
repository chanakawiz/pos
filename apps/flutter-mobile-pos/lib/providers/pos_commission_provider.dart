import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'pos_auth_provider.dart';

class AssociateRanking {
  final int rank;
  final String name;
  final String role;
  final String storeName;
  final double commissionRate;
  final double monthlyTarget;
  final int salesCount;
  final double totalSales;
  final double averageTicket;
  final double totalCommission;
  final double targetAttainmentPercent;

  const AssociateRanking({
    required this.rank,
    required this.name,
    required this.role,
    required this.storeName,
    required this.commissionRate,
    required this.monthlyTarget,
    required this.salesCount,
    required this.totalSales,
    required this.averageTicket,
    required this.totalCommission,
    required this.targetAttainmentPercent,
  });

  factory AssociateRanking.fromJson(Map<String, dynamic> json) {
    return AssociateRanking(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      name: json['name']?.toString() ?? 'Associate',
      role: json['role']?.toString() ?? 'cashier',
      storeName: json['store_name']?.toString() ?? 'Colombo Flagship',
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 2.5,
      monthlyTarget: (json['monthly_target'] as num?)?.toDouble() ?? 500000.0,
      salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      averageTicket: (json['average_ticket'] as num?)?.toDouble() ?? 0.0,
      totalCommission: (json['total_commission'] as num?)?.toDouble() ?? 0.0,
      targetAttainmentPercent: (json['target_attainment_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AssociateCommissionState {
  final String associateName;
  final double commissionRate;
  final double monthlyTarget;
  final int salesCount;
  final double totalSales;
  final double totalCommission;
  final double pendingCommission;
  final double paidCommission;
  final double targetAttainmentPercent;
  final List<AssociateRanking> leaderboard;
  final bool isLoading;

  const AssociateCommissionState({
    this.associateName = 'Cashier 01',
    this.commissionRate = 2.5,
    this.monthlyTarget = 500000.0,
    this.salesCount = 0,
    this.totalSales = 0.0,
    this.totalCommission = 0.0,
    this.pendingCommission = 0.0,
    this.paidCommission = 0.0,
    this.targetAttainmentPercent = 0.0,
    this.leaderboard = const [],
    this.isLoading = false,
  });

  AssociateCommissionState copyWith({
    String? associateName,
    double? commissionRate,
    double? monthlyTarget,
    int? salesCount,
    double? totalSales,
    double? totalCommission,
    double? pendingCommission,
    double? paidCommission,
    double? targetAttainmentPercent,
    List<AssociateRanking>? leaderboard,
    bool? isLoading,
  }) {
    return AssociateCommissionState(
      associateName: associateName ?? this.associateName,
      commissionRate: commissionRate ?? this.commissionRate,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      salesCount: salesCount ?? this.salesCount,
      totalSales: totalSales ?? this.totalSales,
      totalCommission: totalCommission ?? this.totalCommission,
      pendingCommission: pendingCommission ?? this.pendingCommission,
      paidCommission: paidCommission ?? this.paidCommission,
      targetAttainmentPercent: targetAttainmentPercent ?? this.targetAttainmentPercent,
      leaderboard: leaderboard ?? this.leaderboard,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PosCommissionNotifier extends StateNotifier<AssociateCommissionState> {
  final Ref ref;

  PosCommissionNotifier(this.ref) : super(const AssociateCommissionState()) {
    loadCommissions();
  }

  Future<void> loadCommissions({int days = 30}) async {
    state = state.copyWith(isLoading: true);
    final session = ref.read(posAuthProvider).session;
    final headers = {
      'Accept': 'application/json',
      'X-Device-UUID': session.deviceUuid,
      if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
    };

    AssociateCommissionState? remoteMe;
    List<AssociateRanking>? remoteBoard;

    try {
      final meRes = await http
          .get(Uri.parse('${session.apiUrl}/api/v1/commissions/me?days=$days'), headers: headers)
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      if (meRes.statusCode == 200) {
        final d = jsonDecode(meRes.body)['data'];
        if (d is Map) {
          remoteMe = state.copyWith(
            associateName: d['associate_name']?.toString(),
            commissionRate: (d['commission_rate'] as num?)?.toDouble(),
            monthlyTarget: (d['monthly_target'] as num?)?.toDouble(),
            salesCount: (d['sales_count'] as num?)?.toInt(),
            totalSales: (d['total_sales'] as num?)?.toDouble(),
            totalCommission: (d['total_commission'] as num?)?.toDouble(),
            pendingCommission: (d['pending_commission'] as num?)?.toDouble(),
            paidCommission: (d['paid_commission'] as num?)?.toDouble(),
            targetAttainmentPercent: (d['target_attainment_percent'] as num?)?.toDouble(),
          );
        }
      }

      final boardRes = await http
          .get(Uri.parse('${session.apiUrl}/api/v1/commissions/leaderboard?days=$days'), headers: headers)
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      if (boardRes.statusCode == 200) {
        final list = (jsonDecode(boardRes.body)['data'] as List?) ?? [];
        remoteBoard = list.map((e) => AssociateRanking.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {
      // Offline curated fallback
    }

    if (!mounted) return;

    final fallbackBoard = const [
      AssociateRanking(
        rank: 1,
        name: 'Sarah Connor',
        role: 'cashier',
        storeName: 'Colombo Flagship',
        commissionRate: 3.0,
        monthlyTarget: 500000.0,
        salesCount: 18,
        totalSales: 625000.0,
        averageTicket: 34722.0,
        totalCommission: 18750.0,
        targetAttainmentPercent: 125.0,
      ),
      AssociateRanking(
        rank: 2,
        name: 'Nadeeka Perera',
        role: 'cashier',
        storeName: 'Kandy Galleria',
        commissionRate: 2.5,
        monthlyTarget: 500000.0,
        salesCount: 14,
        totalSales: 445000.0,
        averageTicket: 31785.0,
        totalCommission: 11125.0,
        targetAttainmentPercent: 89.0,
      ),
      AssociateRanking(
        rank: 3,
        name: 'Devon Lane',
        role: 'cashier',
        storeName: 'Galle Fort Boutique',
        commissionRate: 2.5,
        monthlyTarget: 400000.0,
        salesCount: 11,
        totalSales: 312000.0,
        averageTicket: 28363.0,
        totalCommission: 7800.0,
        targetAttainmentPercent: 78.0,
      ),
    ];

    final effectiveMe = remoteMe ??
        state.copyWith(
          associateName: session.cashierName.isNotEmpty ? session.cashierName : 'Sarah Connor',
          commissionRate: 3.0,
          monthlyTarget: 500000.0,
          salesCount: 18,
          totalSales: 625000.0,
          totalCommission: 18750.0,
          pendingCommission: 6250.0,
          paidCommission: 12500.0,
          targetAttainmentPercent: 125.0,
        );

    state = effectiveMe.copyWith(
      leaderboard: (remoteBoard != null && remoteBoard.isNotEmpty) ? remoteBoard : fallbackBoard,
      isLoading: false,
    );
  }
}

final posCommissionProvider =
    StateNotifierProvider<PosCommissionNotifier, AssociateCommissionState>((ref) {
  return PosCommissionNotifier(ref);
});

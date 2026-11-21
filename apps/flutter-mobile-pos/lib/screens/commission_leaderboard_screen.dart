import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../providers/pos_commission_provider.dart';

class CommissionLeaderboardScreen extends ConsumerWidget {
  const CommissionLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posCommissionProvider);
    final currency = NumberFormat('#,##0');
    final progress = (state.targetAttainmentPercent / 100.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: PosTheme.background,
      appBar: AppBar(
        backgroundColor: PosTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PosTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMMISSIONS & LEADERBOARD',
              style: TextStyle(
                color: PosTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '30-Day Associate Sales Targets & Earnings',
              style: TextStyle(color: PosTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: PosTheme.primaryGold),
            onPressed: () => ref.read(posCommissionProvider.notifier).loadCommissions(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: PosTheme.primaryGold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Personal Associate Target & Commission Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        PosTheme.forestGreen.withValues(alpha: 0.75),
                        PosTheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: PosTheme.primaryGold.withValues(alpha: 0.45)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            state.associateName.toUpperCase(),
                            style: const TextStyle(
                              color: PosTheme.primaryGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: PosTheme.primaryGold.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${state.commissionRate.toStringAsFixed(1)}% RATE',
                              style: const TextStyle(
                                color: PosTheme.primaryGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LKR ${currency.format(state.totalCommission)}',
                        style: const TextStyle(
                          color: PosTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Earned across ${state.salesCount} sales (LKR ${currency.format(state.totalSales)})',
                        style: const TextStyle(color: PosTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Monthly Target Progress',
                            style: TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                          ),
                          Text(
                            '${state.targetAttainmentPercent.toStringAsFixed(0)}% of LKR ${currency.format(state.monthlyTarget)}',
                            style: const TextStyle(
                              color: PosTheme.primaryGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: PosTheme.card,
                          valueColor: const AlwaysStoppedAnimation<Color>(PosTheme.primaryGold),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _miniPill('Pending Payout', 'LKR ${currency.format(state.pendingCommission)}', PosTheme.accentAmber),
                          const SizedBox(width: 10),
                          _miniPill('Settled / Paid', 'LKR ${currency.format(state.paidCommission)}', PosTheme.accentGreen),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                const Text(
                  'BOUTIQUE ASSOCIATE LEADERBOARD',
                  style: TextStyle(
                    color: PosTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                ...state.leaderboard.map((row) {
                  final rankColor = row.rank == 1
                      ? PosTheme.primaryGold
                      : (row.rank == 2 ? const Color(0xFFD1D5DB) : const Color(0xFFD97706));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PosTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: row.rank == 1 ? PosTheme.primaryGold.withValues(alpha: 0.5) : PosTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: rankColor.withValues(alpha: 0.18),
                          child: Text(
                            '#${row.rank}',
                            style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.name,
                                style: const TextStyle(
                                  color: PosTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${row.storeName} • ${row.salesCount} bills • ${row.targetAttainmentPercent.toStringAsFixed(0)}% target',
                                style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'LKR ${currency.format(row.totalSales)}',
                              style: const TextStyle(
                                color: PosTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '+LKR ${currency.format(row.totalCommission)} comm.',
                              style: const TextStyle(
                                color: PosTheme.accentGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _miniPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: PosTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PosTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: PosTheme.textMuted, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

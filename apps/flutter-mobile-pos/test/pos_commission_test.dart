import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/providers/pos_commission_provider.dart';
import 'package:flutter_mobile_pos/screens/commission_leaderboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 33: Staff Commissions & Associate Leaderboard Tests', () {
    test('Loads personal earnings summary and boutique associate rankings offline', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(posCommissionProvider.notifier).loadCommissions();
      final state = container.read(posCommissionProvider);

      expect(state.totalCommission, greaterThan(0));
      expect(state.leaderboard.length, greaterThanOrEqualTo(3));
      expect(state.leaderboard.first.rank, equals(1));
      expect(state.leaderboard.first.totalSales, greaterThanOrEqualTo(state.leaderboard[1].totalSales));
    });

    testWidgets('CommissionLeaderboardScreen renders target progress and associate rankings', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CommissionLeaderboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COMMISSIONS & LEADERBOARD'), findsOneWidget);
      expect(find.text('BOUTIQUE ASSOCIATE LEADERBOARD'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/providers/pos_auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PosAuthNotifier initial state is paired and locked', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(posAuthProvider);
    expect(state.session.deviceCode, equals('ROAMING-01'));
    expect(state.isLocked, isTrue);
  });

  test('PosAuthNotifier rejects invalid PIN', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final success = container.read(posAuthProvider.notifier).verifyPin('9999');
    expect(success, isFalse);
    expect(container.read(posAuthProvider).errorMessage, isNotNull);
    expect(container.read(posAuthProvider).isLocked, isTrue);
  });

  test('PosAuthNotifier accepts valid PIN 1234 and unlocks', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final success = container.read(posAuthProvider.notifier).verifyPin('1234');
    expect(success, isTrue);
    expect(container.read(posAuthProvider).isLocked, isFalse);
    expect(container.read(posAuthProvider).errorMessage, isNull);
  });

  test('PosAuthNotifier opens shift with opening float', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(posAuthProvider.notifier).verifyPin('1234');
    final opened = await container.read(posAuthProvider.notifier).openShift(
      openingFloat: 15000.00,
      notes: 'Test Shift',
    );

    expect(opened, isTrue);
    final session = container.read(posAuthProvider).session;
    expect(session.openingFloat, equals(15000.00));
    expect(session.hasActiveShift, isTrue);
  });

  test('PosAuthNotifier locks and logs out', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(posAuthProvider.notifier).verifyPin('1234');
    expect(container.read(posAuthProvider).isLocked, isFalse);

    container.read(posAuthProvider.notifier).lockTerminal();
    expect(container.read(posAuthProvider).isLocked, isTrue);

    container.read(posAuthProvider.notifier).logoutCashier();
    expect(container.read(posAuthProvider).session.cashierId, isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/pos_theme.dart';
import 'providers/pos_auth_provider.dart';
import 'screens/device_pairing_screen.dart';
import 'screens/pos_home_screen.dart';
import 'screens/staff_pin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: OmniLuxeMobilePosApp(),
    ),
  );
}

class OmniLuxeMobilePosApp extends ConsumerWidget {
  const OmniLuxeMobilePosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(posAuthProvider);
    final session = authState.session;

    Widget homeScreen;
    if (!session.isPaired) {
      homeScreen = const DevicePairingScreen();
    } else if (authState.isLocked) {
      homeScreen = const StaffPinScreen();
    } else {
      homeScreen = const PosHomeScreen();
    }

    return MaterialApp(
      title: 'OmniLuxe Handheld Staff POS',
      debugShowCheckedModeBanner: false,
      theme: PosTheme.darkTheme,
      home: homeScreen,
    );
  }
}

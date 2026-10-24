import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_helper.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/pos/pos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API client & SQLite persistence
  await ApiClient.instance.init();
  await DatabaseHelper.instance.seedDemoCatalogIfEmpty();

  runApp(
    const ProviderScope(
      child: SmartShopMobilePosApp(),
    ),
  );
}

class SmartShopMobilePosApp extends ConsumerWidget {
  const SmartShopMobilePosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'SmartShop Mobile POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.isAuthenticated ? const PosScreen() : const LoginScreen(),
    );
  }
}

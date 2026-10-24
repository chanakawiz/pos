import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_helper.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/store/store_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API client & SQLite persistence
  await ApiClient.instance.init();
  await DatabaseHelper.instance.seedDemoCatalogIfEmpty(forceRefresh: true);

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
    return MaterialApp(
      title: 'SmartShop Flagship Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const StoreMainScreen(),
    );
  }
}

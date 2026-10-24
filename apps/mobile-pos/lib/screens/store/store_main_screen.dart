import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import 'store_cart_screen.dart';
import 'store_catalog_screen.dart';
import 'store_home_screen.dart';
import 'store_orders_screen.dart';

class StoreMainScreen extends ConsumerStatefulWidget {
  const StoreMainScreen({super.key});

  @override
  ConsumerState<StoreMainScreen> createState() => _StoreMainScreenState();
}

class _StoreMainScreenState extends ConsumerState<StoreMainScreen> {
  int _currentIndex = 0;

  void _navigateToCatalog([String? categoryUuid]) {
    ref.read(catalogProvider.notifier).selectCategory(categoryUuid);
    setState(() => _currentIndex = 1);
  }

  void _navigateToBag() {
    setState(() => _currentIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    final screens = [
      StoreHomeScreen(
        onSelectCategory: _navigateToCatalog,
        onOpenBag: _navigateToBag,
      ),
      StoreCatalogScreen(
        onOpenBag: _navigateToBag,
      ),
      StoreCartScreen(
        onBrowseCatalog: () => setState(() => _currentIndex = 1),
      ),
      const StoreOrdersScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.gold.withOpacity(0.18),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
                selectedIcon: const Icon(Icons.home, color: AppColors.gold),
                label: 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.explore_outlined, color: AppColors.textSecondary),
                selectedIcon: const Icon(Icons.explore, color: AppColors.gold),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: cart.totalItemCount > 0,
                  label: Text(
                    '${cart.totalItemCount}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  backgroundColor: AppColors.gold,
                  child: const Icon(Icons.shopping_bag_outlined, color: AppColors.textSecondary),
                ),
                selectedIcon: Badge(
                  isLabelVisible: cart.totalItemCount > 0,
                  label: Text(
                    '${cart.totalItemCount}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  backgroundColor: AppColors.gold,
                  child: const Icon(Icons.shopping_bag, color: AppColors.gold),
                ),
                label: 'Bag',
              ),
              NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary),
                selectedIcon: const Icon(Icons.receipt_long, color: AppColors.gold),
                label: 'Orders',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

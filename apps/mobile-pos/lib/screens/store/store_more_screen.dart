import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'store_notifications_screen.dart';
import 'store_profile_screen.dart';

class StoreMoreScreen extends ConsumerWidget {
  const StoreMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'MORE & SERVICES',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Customer Account Header
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoreProfileScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'G',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null ? user.name : 'Guest Shopper',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          user != null ? 'View profile and delivery addresses' : 'Tap to sign in or view settings',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionHeader('CUSTOMER SERVICES'),
          _buildMenuContainer([
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications Center',
              subtitle: 'Firebase FCM order & promo updates',
              badge: unreadCount > 0 ? '$unreadCount' : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoreNotificationsScreen()),
                );
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.storefront_outlined,
              title: 'Find a Boutique (Store Locator)',
              subtitle: 'Colombo 03 Flagship • Kandy • Galle',
              onTap: () => _showBoutiquesDialog(context),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.verified_user_outlined,
              title: 'Warranty & Exchange Policy',
              subtitle: 'Official brand guarantees & digital receipts',
              onTap: () => _showPolicyDialog(context),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.support_agent_outlined,
              title: 'Customer Concierge & Support',
              subtitle: 'Dedicated luxury retail assistant',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Concierge WhatsApp: +94 11 234 5678 (Mon-Sun 9AM - 8PM)')),
                );
              },
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader('PRIVILEGE & POLICIES'),
          _buildMenuContainer([
            _buildMenuItem(
              icon: Icons.card_membership_outlined,
              title: 'Privilege Club Tiers & Rewards',
              subtitle: 'Earn 1 Pt per Rs. 10 spent • Exclusive member events',
              accentColor: AppColors.gold,
              onTap: () => _showPrivilegeTiersDialog(context),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.security_outlined,
              title: 'Customer Privacy & Data Protection',
              subtitle: 'Encrypted bills & telephone number privacy masking',
              onTap: () => _showPrivacyDialog(context),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.verified_outlined,
              title: '100% Authenticity Guarantee',
              subtitle: 'Direct brand partnerships & genuine luxury sourcing',
              onTap: () => _showAuthenticityDialog(context),
            ),
          ]),

          const SizedBox(height: 32),

          Center(
            child: Column(
              children: [
                Text(
                  'OMNILUXE STORE',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  'Curated Fashion, Fragrances & Lifestyle Retail',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Color? accentColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: accentColor ?? AppColors.primary, size: 22),
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(color: AppColors.border, height: 1);

  void _showBoutiquesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Flagship Boutiques', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _boutiqueItem('Colombo 03 Flagship', '48 Galle Road, Colombo 03', 'Open 10:00 AM - 8:00 PM Daily'),
            const SizedBox(height: 12),
            _boutiqueItem('Kandy City Centre Boutique', 'Level 2, KCC, Dalada Veediya', 'Open 10:00 AM - 7:30 PM Daily'),
            const SizedBox(height: 12),
            _boutiqueItem('Galle Fort Boutique', 'Lighthouse Street, Galle Fort', 'Open 9:30 AM - 7:00 PM Daily'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _boutiqueItem(String name, String address, String hours) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(address, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        Text(hours, style: GoogleFonts.inter(fontSize: 10, color: AppColors.sage)),
      ],
    );
  }

  void _showPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Warranty & Returns', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(
          '1. Official Brand Guarantee: All items purchased via Web, App or Boutique carry official manufacturer warranties.\n\n'
          '2. 14-Day Exchanges: Items in original packaging with intact tags can be exchanged at any flagship boutique.\n\n'
          '3. SMS Digital E-Receipts: Receipts sent to your mobile phone serve as official proof of purchase across all branches.',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Understood')),
        ],
      ),
    );
  }
  void _showPrivilegeTiersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Privilege Tiers', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tierItem('Silver Tier (Entry)', 'Earn 1 point per Rs. 10 spent. Free digital warranty lookup.'),
            const SizedBox(height: 10),
            _tierItem('Gold Tier (5,000+ Pts)', '1.5x point multiplier, complimentary boutique gift wrapping.'),
            const SizedBox(height: 10),
            _tierItem('Platinum VIP (15,000+ Pts)', '2x point multiplier, private concierge appointments, priority delivery.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _tierItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(desc, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Privacy & Security', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(
          '• Telephone Number Masking: Customer contact numbers are encrypted and masked on digital e-receipts (e.g. 077 •••• 567).\n\n'
          '• Zero Advertising Trackers: Your shopping history is exclusively utilized for personal warranty records and VIP loyalty rewards.\n\n'
          '• Verified Push Delivery: Notifications are transmitted through official Firebase FCM with zero third-party data broker sharing.',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Understood')),
        ],
      ),
    );
  }

  void _showAuthenticityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Authenticity Guarantee', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(
          'Every fragrance, leather handbag, garment, and lifestyle tech device in OmniLuxe Store is sourced directly from authorized brand distributors with genuine import documentation and verified barcodes.',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Understood')),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'store_auth_steps_screen.dart';

class StoreProfileScreen extends ConsumerStatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  ConsumerState<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends ConsumerState<StoreProfileScreen> {
  bool _fcmOrderAlerts = true;
  bool _fcmPromoAlerts = true;
  bool _smsReceipts = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'MY PROFILE & SETTINGS',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'G',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null ? user.name : 'Guest Shopper',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user != null ? user.email : 'Browsing without account',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: user != null ? AppColors.gold.withOpacity(0.18) : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: user != null ? AppColors.gold.withOpacity(0.4) : AppColors.border,
                            ),
                          ),
                          child: Text(
                            user != null ? '${user.tier.toUpperCase()} VIP MEMBER' : 'GUEST EXPLORER',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: user != null ? AppColors.gold : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (user == null) ...[
              // Guest Onboarding Prompt
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to OmniLuxe Privilege VIP',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unlock 100 Welcome Points, unified in-store POS points, and private event allocations.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StoreAuthStepsScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Sign In or Join with Steps (+100 Pts)',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Section: Verified SMS & Contact Information
            _buildSectionHeader('CONTACT & VERIFICATION'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.phone_iphone,
                    title: 'SMS E-Receipt Mobile',
                    subtitle: user?.phone ?? '077 123 4567 (Verified for SMS Bills)',
                    trailing: const Icon(Icons.verified, size: 16, color: AppColors.success),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _buildProfileTile(
                    icon: Icons.location_on_outlined,
                    title: 'Saved Delivery Address',
                    subtitle: '48 Horton Place, Colombo 07',
                    trailing: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Push Notifications & Firebase FCM Settings
            _buildSectionHeader('PUSH NOTIFICATIONS & ALERTS'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _fcmOrderAlerts,
                    onChanged: (val) => setState(() => _fcmOrderAlerts = val),
                    activeColor: AppColors.primary,
                    title: Text(
                      'FCM Order Status Alerts',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Push notifications when orders dispatch & reach courier',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    value: _fcmPromoAlerts,
                    onChanged: (val) => setState(() => _fcmPromoAlerts = val),
                    activeColor: AppColors.primary,
                    title: Text(
                      'VIP Collection Drops & Promos',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Exclusive invitations to member-only new arrivals',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    value: _smsReceipts,
                    onChanged: (val) => setState(() => _smsReceipts = val),
                    activeColor: AppColors.primary,
                    title: Text(
                      'Tamper-Evident SMS Receipts',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Instant warranty confirmation routed to verified mobile number',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sign Out / Demo action
            if (user != null)
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout, size: 16, color: AppColors.danger),
                label: Text(
                  'Sign Out of VIP Account',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.danger),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: trailing,
    );
  }
}

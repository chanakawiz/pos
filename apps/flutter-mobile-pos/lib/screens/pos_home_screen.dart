import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../providers/pos_auth_provider.dart';
import 'staff_pin_screen.dart';

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(posAuthProvider);
    final session = authState.session;
    final currencyFormat = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: PosTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Staff Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: PosTheme.surface,
                border: Border(bottom: BorderSide(color: PosTheme.border)),
              ),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: PosTheme.forestGreen,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PosTheme.primaryGold),
                    ),
                    child: Center(
                      child: Text(
                        'O',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: PosTheme.primaryGold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Store & Terminal Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              session.storeName,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: PosTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: PosTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: PosTheme.border),
                              ),
                              child: Text(
                                session.deviceCode,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: PosTheme.primaryGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Staff: ${session.cashierName.isNotEmpty ? session.cashierName : "Cashier 01"} • Float LKR ${currencyFormat.format(session.openingFloat)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: PosTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lock Action
                  IconButton(
                    onPressed: () {
                      ref.read(posAuthProvider.notifier).lockTerminal();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const StaffPinScreen()),
                      );
                    },
                    tooltip: 'Lock Terminal',
                    icon: const Icon(Icons.lock_outline, color: PosTheme.primaryGold, size: 22),
                  ),

                  // Logout Action
                  IconButton(
                    onPressed: () {
                      ref.read(posAuthProvider.notifier).logoutCashier();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const StaffPinScreen()),
                      );
                    },
                    tooltip: 'Logout Staff',
                    icon: const Icon(Icons.power_settings_new_rounded, color: PosTheme.accentRed, size: 22),
                  ),
                ],
              ),
            ),

            // Main Dashboard Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Shift Float Metrics Banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            PosTheme.forestGreen.withValues(alpha: 0.6),
                            PosTheme.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: PosTheme.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ACTIVE CASHIER SHIFT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: PosTheme.primaryGold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'LKR ${currencyFormat.format(session.openingFloat)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: PosTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Opening Float in Mobile Drawer',
                                  style: GoogleFonts.inter(fontSize: 12, color: PosTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: PosTheme.accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: PosTheme.accentGreen.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: PosTheme.accentGreen, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'Shift Active',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: PosTheme.accentGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cashier Action Cards Grid
                    Text(
                      'TERMINAL WORKFLOW',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: PosTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Primary Action: New Register Checkout
                    _buildFeatureCard(
                      context,
                      title: 'Register Checkout & Barcode Scanner',
                      subtitle: 'Continuous camera optical scanning, catalog touch grid & rapid cart management.',
                      icon: Icons.qr_code_scanner_rounded,
                      accentColor: PosTheme.primaryGold,
                      isHighlighted: true,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: PosTheme.forestGreen,
                            content: Text(
                              'Checkout Cart initialized on ${session.deviceCode}',
                              style: GoogleFonts.inter(color: PosTheme.primaryGold),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Line-Busting & Held Bills
                    _buildFeatureCard(
                      context,
                      title: 'Multi-Lane Line-Busting & Held Bills',
                      subtitle: 'Scan customer items in aisle, hold order with 4-digit token or barcode for counter recall.',
                      icon: Icons.pause_circle_outline_rounded,
                      accentColor: PosTheme.accentGreen,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: PosTheme.surface,
                            content: Text(
                              'Syncing with Central Held Bills API at ${session.apiUrl}...',
                              style: GoogleFonts.inter(color: PosTheme.textPrimary),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Mid-Shift X-Report
                    _buildFeatureCard(
                      context,
                      title: 'Mid-Shift X-Report & Cash Audit',
                      subtitle: 'Review mid-day transactions, expected drawer balances & tender totals without closing.',
                      icon: Icons.analytics_outlined,
                      accentColor: PosTheme.primaryGold,
                      onTap: () {
                        _showXReportModal(context, session, currencyFormat);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Close Register Z-Report
                    _buildFeatureCard(
                      context,
                      title: 'Close Register Shift (Z-Report)',
                      subtitle: 'Perform cash count, record drawer discrepancy, and generate official closing Z-report.',
                      icon: Icons.lock_clock_outlined,
                      accentColor: PosTheme.accentAmber,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: PosTheme.surface,
                            content: Text(
                              'Close Register routine ready. Integrated with pos:eod-closeout scheduler.',
                              style: GoogleFonts.inter(color: PosTheme.accentAmber),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Connection Status Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: PosTheme.surface,
                border: Border(top: BorderSide(color: PosTheme.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, color: PosTheme.accentGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connected to ERP: ${session.apiUrl}',
                      style: GoogleFonts.inter(fontSize: 11, color: PosTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'OmniLuxe POS v1.0',
                    style: GoogleFonts.outfit(fontSize: 11, color: PosTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isHighlighted ? PosTheme.forestGreen.withValues(alpha: 0.35) : PosTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted ? accentColor : PosTheme.border,
            width: isHighlighted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: PosTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: PosTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: PosTheme.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  void _showXReportModal(BuildContext context, dynamic session, NumberFormat currencyFormat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PosTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MID-SHIFT X-REPORT AUDIT',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: PosTheme.primaryGold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: PosTheme.textSecondary),
                  ),
                ],
              ),
              const Divider(color: PosTheme.border),
              const SizedBox(height: 12),
              _buildReportRow('Store Location', session.storeName),
              _buildReportRow('Device Terminal', session.deviceCode),
              _buildReportRow('Cashier Staff', session.cashierName.isNotEmpty ? session.cashierName : 'Cashier 01'),
              _buildReportRow('Opening Cash Float', 'LKR ${currencyFormat.format(session.openingFloat)}'),
              _buildReportRow('Total Cash Sales', 'LKR 0.00'),
              _buildReportRow('Total Card Sales', 'LKR 0.00'),
              _buildReportRow('Expected Drawer Cash', 'LKR ${currencyFormat.format(session.openingFloat)}'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('X-Report queued to Bluetooth ESC/POS printer')),
                  );
                },
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('PRINT X-REPORT TO BLUETOOTH PRINTER'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: PosTheme.textSecondary)),
          Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: PosTheme.textPrimary)),
        ],
      ),
    );
  }
}

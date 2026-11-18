import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/pos_theme.dart';
import '../providers/pos_auth_provider.dart';
import 'device_pairing_screen.dart';
import 'pos_home_screen.dart';
import 'shift_open_dialog.dart';

class StaffPinScreen extends ConsumerStatefulWidget {
  const StaffPinScreen({super.key});

  @override
  ConsumerState<StaffPinScreen> createState() => _StaffPinScreenState();
}

class _StaffPinScreenState extends ConsumerState<StaffPinScreen> {
  String _enteredPin = '';
  Map<String, dynamic>? _selectedCashier;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(posAuthProvider);
    if (authState.cashiers.isNotEmpty) {
      _selectedCashier = authState.cashiers.first;
    }
  }

  void _onKeyPressed(String key) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += key;
    });

    if (_enteredPin.length == 4) {
      _handleSubmitPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _enteredPin = '';
    });
  }

  void _handleSubmitPin() {
    final success = ref.read(posAuthProvider.notifier).verifyPin(
      _enteredPin,
      selectedCashier: _selectedCashier,
    );

    if (success) {
      final session = ref.read(posAuthProvider).session;
      if (session.hasActiveShift) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PosHomeScreen()),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ShiftOpenDialog(
            onShiftOpened: () {
              Navigator.of(context).pop(); // Dismiss dialog
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PosHomeScreen()),
              );
            },
          ),
        );
      }
    } else {
      setState(() {
        _enteredPin = '';
      });
    }
  }

  Widget _buildKeypadButton(String label, {VoidCallback? onPressed, IconData? icon}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed ?? () => _onKeyPressed(label),
        borderRadius: BorderRadius.circular(16),
        splashColor: PosTheme.primaryGold.withValues(alpha: 0.2),
        highlightColor: PosTheme.surfaceLight,
        child: Container(
          decoration: BoxDecoration(
            color: PosTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PosTheme.border, width: 1),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: PosTheme.textPrimary, size: 24)
                : Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: PosTheme.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(posAuthProvider);
    final session = authState.session;

    return Scaffold(
      backgroundColor: PosTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top Device Status Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: PosTheme.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: PosTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: PosTheme.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          session.storeName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: PosTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: PosTheme.forestGreen.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
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
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Text(
                    'STAFF REGISTER ACCESS',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: PosTheme.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter 4-Digit Staff PIN',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: PosTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cashier Selector Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: authState.cashiers.map((cashier) {
                        final isSelected = _selectedCashier?['id'] == cashier['id'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(cashier['name']),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCashier = cashier;
                                  _enteredPin = '';
                                });
                              }
                            },
                            selectedColor: PosTheme.forestGreen,
                            backgroundColor: PosTheme.surface,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? PosTheme.primaryGold : PosTheme.textSecondary,
                            ),
                            side: BorderSide(
                              color: isSelected ? PosTheme.primaryGold : PosTheme.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? PosTheme.primaryGold : Colors.transparent,
                          border: Border.all(
                            color: isFilled ? PosTheme.primaryGold : PosTheme.border,
                            width: 2,
                          ),
                          boxShadow: isFilled
                              ? [
                                  BoxShadow(
                                    color: PosTheme.primaryGold.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Error Message
                  if (authState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: PosTheme.accentRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: PosTheme.accentRed.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        authState.errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: PosTheme.accentRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Keypad Grid
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.3,
                      children: [
                        _buildKeypadButton('1'),
                        _buildKeypadButton('2'),
                        _buildKeypadButton('3'),
                        _buildKeypadButton('4'),
                        _buildKeypadButton('5'),
                        _buildKeypadButton('6'),
                        _buildKeypadButton('7'),
                        _buildKeypadButton('8'),
                        _buildKeypadButton('9'),
                        _buildKeypadButton('C', onPressed: _onClear),
                        _buildKeypadButton('0'),
                        _buildKeypadButton('', icon: Icons.backspace_outlined, onPressed: _onBackspace),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Switch Device Action
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DevicePairingScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined, size: 16, color: PosTheme.textMuted),
                    label: Text(
                      'Terminal Hardware Settings',
                      style: GoogleFonts.inter(fontSize: 12, color: PosTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

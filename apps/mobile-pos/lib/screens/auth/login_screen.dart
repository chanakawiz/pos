import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../pos/pos_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _pinCode = '';
  final String _email = 'cashier1@smartshop.com';
  final TextEditingController _passwordController = TextEditingController();
  bool _usePassword = false;

  void _onKeyTap(String key) {
    if (_pinCode.length < 6) {
      setState(() {
        _pinCode += key;
      });
      if (_pinCode.length == 4) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_pinCode.isNotEmpty) {
      setState(() {
        _pinCode = _pinCode.substring(0, _pinCode.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _pinCode = '';
    });
  }

  Future<void> _submitPin() async {
    final success = await ref.read(authProvider.notifier).loginWithPin(
          pinCode: _pinCode,
          email: _email,
        );
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const PosScreen()),
      );
    } else {
      setState(() {
        _pinCode = '';
      });
    }
  }

  Future<void> _submitPassword() async {
    final pass = _passwordController.text.trim();
    if (pass.isEmpty) return;

    final success = await ref.read(authProvider.notifier).loginWithPassword(
          email: _email,
          password: pass,
        );
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const PosScreen()),
      );
    }
  }

  void _directDemoLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (ctx) => const PosScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Brand Wordmark
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.point_of_sale, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SMARTSHOP POS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mobile Cashier Terminal',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),

                  // PIN circles display
                  if (!_usePassword) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final filled = index < _pinCode.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: filled ? AppColors.primary : AppColors.border,
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Error message
                    if (authState.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ),

                    // 3x4 Keypad Grid
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(
                          (n) => _KeypadButton(
                            label: n,
                            onTap: () => _onKeyTap(n),
                          ),
                        ),
                        _KeypadButton(
                          label: 'C',
                          color: AppColors.danger.withOpacity(0.2),
                          textColor: AppColors.danger,
                          onTap: _onClear,
                        ),
                        _KeypadButton(
                          label: '0',
                          onTap: () => _onKeyTap('0'),
                        ),
                        _KeypadButton(
                          icon: Icons.backspace_outlined,
                          onTap: _onBackspace,
                        ),
                      ],
                    ),
                  ] else ...[
                    // Password input
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _submitPassword,
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Log In with Password'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Switch between PIN / Password & Quick Demo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _usePassword = !_usePassword;
                          });
                        },
                        child: Text(
                          _usePassword ? 'Use PIN Pad' : 'Use Password',
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                      ),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      TextButton(
                        onPressed: _directDemoLogin,
                        child: const Text(
                          'Quick Demo Access',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
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

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final VoidCallback onTap;

  const _KeypadButton({
    this.label,
    this.icon,
    this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: textColor ?? AppColors.textPrimary, size: 22)
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

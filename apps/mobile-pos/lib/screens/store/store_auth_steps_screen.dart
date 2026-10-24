import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Multi-Step Login & Registration Screen with Guest Mode bypass.
/// Step 1: Contact & Guest Mode choice (Email/Mobile)
/// Step 2: Credentials & VIP Enrollment (Password, Name, VIP Club checkbox)
/// Step 3: VIP Membership Issued Confirmation
class StoreAuthStepsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAuthSuccess;
  final VoidCallback? onContinueAsGuest;

  const StoreAuthStepsScreen({
    super.key,
    this.onAuthSuccess,
    this.onContinueAsGuest,
  });

  @override
  ConsumerState<StoreAuthStepsScreen> createState() => _StoreAuthStepsScreenState();
}

class _StoreAuthStepsScreenState extends ConsumerState<StoreAuthStepsScreen> {
  int _currentStep = 1; // 1: Contact, 2: Security & VIP, 3: Completed
  bool _isRegister = true; // Toggle between Login and Register modes
  bool _joinVipClub = true;

  final _identifierController = TextEditingController(text: 'customer@lifestyle.test');
  final _nameController = TextEditingController(text: 'Kasun Fernando');
  final _phoneController = TextEditingController(text: '077 123 4567');
  final _passwordController = TextEditingController(text: 'password');
  final _confirmPasswordController = TextEditingController(text: 'password');

  @override
  void dispose() {
    _identifierController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      final id = _identifierController.text.trim();
      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email or mobile phone')),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      _executeAuth();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _executeAuth() async {
    final authNotifier = ref.read(authProvider.notifier);
    if (_isRegister) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your full name')),
        );
        return;
      }
      if (_passwordController.text.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters')),
        );
        return;
      }

      final email = _identifierController.text.contains('@')
          ? _identifierController.text.trim()
          : '${_phoneController.text.replaceAll(' ', '')}@guest.omniluxe.test';
      final phone = _phoneController.text.trim();

      final ok = await authNotifier.registerCustomer(
        name: _nameController.text.trim(),
        email: email,
        phone: phone,
        password: _passwordController.text.trim(),
      );

      if (ok && mounted) {
        setState(() => _currentStep = 3);
      }
    } else {
      final ok = await authNotifier.loginWithPassword(
        email: _identifierController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (ok && mounted) {
        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!();
        } else {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _isRegister ? 'JOIN OMNILUXE' : 'SIGN IN',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_currentStep > 1 && _currentStep < 3) {
              _prevStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Visual Step Progress Indicator
            _buildStepIndicator(),
            const SizedBox(height: 24),

            // Step Content
            if (_currentStep == 1) _buildStepOne(authState),
            if (_currentStep == 2) _buildStepTwo(authState),
            if (_currentStep == 3) _buildStepThree(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildStepPill(1, 'Contact', _currentStep >= 1, _currentStep == 1),
          _buildStepDivider(_currentStep >= 2),
          _buildStepPill(2, _isRegister ? 'Security & VIP' : 'Password', _currentStep >= 2, _currentStep == 2),
          _buildStepDivider(_currentStep >= 3),
          _buildStepPill(3, 'VIP Ready', _currentStep == 3, _currentStep == 3),
        ],
      ),
    );
  }

  Widget _buildStepPill(int stepNumber, String label, bool isDoneOrCurrent, bool isCurrent) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? AppColors.primary
                  : isDoneOrCurrent
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surfaceElevated,
              border: Border.all(
                color: isCurrent ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Center(
              child: isDoneOrCurrent && !isCurrent
                  ? const Icon(Icons.check, size: 14, color: AppColors.primary)
                  : Text(
                      '$stepNumber',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Container(
      width: 20,
      height: 1.5,
      color: isActive ? AppColors.primary : AppColors.border,
      margin: const EdgeInsets.only(bottom: 14),
    );
  }

  Widget _buildStepOne(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode Toggle (Register vs Login)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isRegister = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isRegister ? AppColors.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _isRegister
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Register (+100 Pts)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isRegister ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isRegister = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isRegister ? AppColors.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: !_isRegister
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !_isRegister ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            _isRegister ? 'Step 1 of 2: Your Contact Information' : 'Step 1 of 2: Member Identification',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRegister
                ? 'Enter your mobile or email to get started with your digital warranty and e-receipts.'
                : 'Enter your registered email address or mobile number.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address or Mobile Number',
              hintText: 'e.g. customer@lifestyle.test or 0771234567',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 22),

          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue to Step 2',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),

          // Guest Mode Bypass Option
          OutlinedButton.icon(
            onPressed: () {
              if (widget.onContinueAsGuest != null) {
                widget.onContinueAsGuest!();
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.primary),
            label: Text(
              'Continue Exploring as Guest',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guest mode lets you browse the catalog, curate your cart, and place orders with instant SMS verification without an account.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwo(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isRegister ? 'Step 2 of 2: Create Password & VIP Enrollment' : 'Step 2 of 2: Enter Password',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          if (_isRegister) ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Phone (for SMS Bills & OTP)',
                prefixIcon: Icon(Icons.phone_iphone, size: 20),
              ),
            ),
            const SizedBox(height: 14),
          ],

          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              helperText: _isRegister ? 'Minimum 6 characters' : 'Enter your account password',
            ),
          ),
          const SizedBox(height: 16),

          if (_isRegister) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _joinVipClub,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _joinVipClub = val ?? true),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join OmniLuxe Privilege VIP Club',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Instant 100 Welcome Points awarded + invitations to private catalog previews.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          ElevatedButton(
            onPressed: authState.isLoading ? null : _executeAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _isRegister ? 'Complete Registration & Mint VIP Card' : 'Sign In Now',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: _prevStep,
            child: Text(
              '← Back to Step 1',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepThree() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(Icons.check, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            'Welcome to OmniLuxe Privilege',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your account is active. 100 Welcome Points have been credited to your digital member card.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (widget.onAuthSuccess != null) {
                widget.onAuthSuccess!();
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'View My Digital VIP Card',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

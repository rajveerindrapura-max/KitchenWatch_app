import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/data/sample_data.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/sample_data_badge.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _emailController = TextEditingController(text: 'owner@kitchenwatch.io');
  final _passwordController = TextEditingController(text: 'password123');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _otpController = TextEditingController(text: '123456');

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      if (_tabController.index == 0) {
        await authRepo.signInWithEmailPassword(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await authRepo.signInWithPhone(
          _phoneController.text,
          _otpController.text,
        );
      }
      HapticUtil.medium();
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid credentials. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _demoLoginAs(UserRole role) async {
    HapticUtil.light();
    final authRepo = ref.read(authRepositoryProvider);
    final user = SampleData.initialUsers.firstWhere((u) => u.role == role);
    await authRepo.switchUser(user);
    if (mounted) {
      if (role == UserRole.employee) {
        context.go('/quick-update');
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimensions.space20),
                  // App Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.space12),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textInverse,
                          size: 28,
                        ),
                      ),
                      const SampleDataBadge(),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space20),
                  Text(
                    AppStrings.appName,
                    style: AppTypography.displayMedium,
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    AppStrings.tagline,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Quick Demo Switcher
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    color: AppColors.surfaceMuted,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick demo access',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.textDark),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  minimumSize: const Size.fromHeight(38),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => _demoLoginAs(UserRole.owner),
                                child: Text('Owner', style: AppTypography.labelSmall),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space6),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  minimumSize: const Size.fromHeight(38),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => _demoLoginAs(UserRole.manager),
                                child: Text('Manager', style: AppTypography.labelSmall),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space6),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  minimumSize: const Size.fromHeight(38),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => _demoLoginAs(UserRole.employee),
                                child: Text('Employee', style: AppTypography.labelSmall),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space20),

                  // Sign in form card
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.space20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.brandBlue,
                          labelColor: AppColors.brandBlue,
                          unselectedLabelColor: AppColors.textMuted,
                          labelStyle: AppTypography.labelMedium,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Email'),
                            Tab(text: 'Phone'),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space16),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.space8),
                            decoration: BoxDecoration(
                              color: AppColors.wastageRoseLight,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.wastageRose),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space12),
                        ],

                        SizedBox(
                          height: 140,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Email Tab
                              Column(
                                children: [
                                  TextField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'name@kitchenwatch.io',
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: AppDimensions.space12),
                                  TextField(
                                    controller: _passwordController,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter password',
                                    ),
                                    obscureText: true,
                                  ),
                                ],
                              ),
                              // Phone Tab
                              Column(
                                children: [
                                  TextField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone number',
                                      hintText: '+91 98765 43210',
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: AppDimensions.space12),
                                  TextField(
                                    controller: _otpController,
                                    decoration: const InputDecoration(
                                      labelText: 'Verification code',
                                      hintText: '6-digit code',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppDimensions.space16),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignIn,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textInverse,
                                  ),
                                )
                              : const Text('Sign in'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space16),

                  // First-time owner onboarding link
                  TextButton(
                    onPressed: () {
                      HapticUtil.light();
                      context.go('/onboarding');
                    },
                    child: const Text('First time setup? Start onboarding'),
                  ),
                  const SizedBox(height: AppDimensions.space20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

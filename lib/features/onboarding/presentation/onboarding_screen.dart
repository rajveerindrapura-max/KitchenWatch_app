import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/success_animation_dialog.dart';
import '../../inventory/domain/item.dart';
import '../../inventory/domain/stock_unit.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;

  // Step 1: Restaurant Name
  final _businessNameController = TextEditingController(text: 'Spice Trail Kitchens');

  // Step 2: Outlets
  final _outlet1Controller = TextEditingController(text: 'Central Kitchen');
  final _outlet2Controller = TextEditingController(text: 'Eastside Cloud Kitchen');

  // Step 3 & 4: Starter items selection
  final List<Map<String, dynamic>> _starterItems = [
    {
      'name': 'Basmati Rice',
      'category': 'Grains',
      'unit': StockUnit.kg,
      'min': 20.0,
      'price': 85.0,
      'selected': true
    },
    {
      'name': 'Sunflower Oil',
      'category': 'Oils',
      'unit': StockUnit.l,
      'min': 30.0,
      'price': 130.0,
      'selected': true
    },
    {
      'name': 'Full Cream Milk',
      'category': 'Dairy',
      'unit': StockUnit.l,
      'min': 20.0,
      'price': 65.0,
      'selected': true
    },
    {
      'name': 'Red Onions',
      'category': 'Produce',
      'unit': StockUnit.kg,
      'min': 40.0,
      'price': 32.0,
      'selected': true
    },
    {
      'name': 'Fresh Chicken Breast',
      'category': 'Meat',
      'unit': StockUnit.kg,
      'min': 15.0,
      'price': 260.0,
      'selected': false
    },
    {
      'name': '750ml Containers',
      'category': 'Packaging',
      'unit': StockUnit.pieces,
      'min': 200.0,
      'price': 8.0,
      'selected': false
    },
  ];

  // Step 5: Invite team
  final _inviteEmailController = TextEditingController(text: 'manager@spicetrail.com');
  UserRole _inviteRole = UserRole.manager;

  @override
  void dispose() {
    _businessNameController.dispose();
    _outlet1Controller.dispose();
    _outlet2Controller.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticUtil.light();
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  void _skipStep() {
    HapticUtil.light();
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    HapticUtil.medium();
    final user = await ref.read(authRepositoryProvider).getCurrentUser();

    if (user != null) {
      // Add any selected custom items
      final inventoryRepo = ref.read(inventoryRepositoryProvider);
      for (final raw in _starterItems.where((i) => i['selected'] == true)) {
        await inventoryRepo.addItem(
          user,
          Item(
            id: '',
            name: raw['name'] as String,
            category: raw['category'] as String,
            unit: raw['unit'] as StockUnit,
            minLevel: (raw['min'] as num).toDouble(),
            purchasePricePerUnit: (raw['price'] as num).toDouble(),
          ),
        );
      }
    }

    if (mounted) {
      await SuccessAnimationDialog.show(
        context,
        title: 'Setup completed',
        subtitle: 'Your inventory workspace is ready',
      );
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Setup KitchenWatch (${_currentStep + 1} of 5)'),
        actions: [
          TextButton(
            onPressed: _skipStep,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / 5.0,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandBlue),
              minHeight: 3,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.space20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _buildCurrentStepContent(),
                ),
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space20,
                vertical: AppDimensions.space12,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          HapticUtil.light();
                          setState(() => _currentStep--);
                        },
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      child: Text(_currentStep == 4 ? 'Finish setup' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Restaurant();
      case 1:
        return _buildStep2Outlets();
      case 2:
        return _buildStep3Items();
      case 3:
        return _buildStep4Levels();
      case 4:
        return _buildStep5Team();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Restaurant() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Restaurant or kitchen name', style: AppTypography.titleLarge),
        const SizedBox(height: AppDimensions.space4),
        Text('Appears across outlet transfers and reports', style: AppTypography.bodyMedium),
        const SizedBox(height: AppDimensions.space20),
        TextField(
          controller: _businessNameController,
          decoration: const InputDecoration(
            labelText: 'Business name',
            hintText: 'e.g. Spice Trail Kitchens',
          ),
          autofocus: true,
        ),
      ],
    );
  }

  Widget _buildStep2Outlets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your kitchen outlets', style: AppTypography.titleLarge),
        const SizedBox(height: AppDimensions.space4),
        Text('Set up locations to track stock separately', style: AppTypography.bodyMedium),
        const SizedBox(height: AppDimensions.space20),
        TextField(
          controller: _outlet1Controller,
          decoration: const InputDecoration(
            labelText: 'Primary outlet name',
            hintText: 'e.g. Central Kitchen',
          ),
        ),
        const SizedBox(height: AppDimensions.space12),
        TextField(
          controller: _outlet2Controller,
          decoration: const InputDecoration(
            labelText: 'Second outlet name (optional)',
            hintText: 'e.g. Eastside Cloud Kitchen',
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Items() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select starter items', style: AppTypography.titleLarge),
        const SizedBox(height: AppDimensions.space4),
        Text('Tap items to track immediately', style: AppTypography.bodyMedium),
        const SizedBox(height: AppDimensions.space16),
        ..._starterItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = item['selected'] as bool;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              color: isSelected ? AppColors.brandBlueLight : AppColors.surface,
              onTap: () {
                HapticUtil.selection();
                setState(() {
                  _starterItems[index]['selected'] = !isSelected;
                });
              },
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.brandBlue : AppColors.textLight,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'] as String, style: AppTypography.titleSmall),
                        Text(
                          '${item['category']} - Unit: ${(item['unit'] as StockUnit).symbol}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep4Levels() {
    final selected = _starterItems.where((i) => i['selected'] == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set minimum stock thresholds', style: AppTypography.titleLarge),
        const SizedBox(height: AppDimensions.space4),
        Text('Alerts trigger when stock falls to or below this level', style: AppTypography.bodyMedium),
        const SizedBox(height: AppDimensions.space16),
        if (selected.isEmpty)
          Text('No items selected in previous step', style: AppTypography.bodyMedium)
        else
          ...selected.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space12),
              child: AppCard(
                padding: const EdgeInsets.all(AppDimensions.space12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item['name'] as String, style: AppTypography.titleSmall),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () {
                            HapticUtil.light();
                            setState(() {
                              if (item['min'] > 5) item['min'] -= 5;
                            });
                          },
                        ),
                        Text(
                          '${item['min']} ${(item['unit'] as StockUnit).symbol}',
                          style: AppTypography.monoMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () {
                            HapticUtil.light();
                            setState(() {
                              item['min'] += 5;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStep5Team() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invite team members', style: AppTypography.titleLarge),
        const SizedBox(height: AppDimensions.space4),
        Text('Managers supervise stock, employees update counts', style: AppTypography.bodyMedium),
        const SizedBox(height: AppDimensions.space20),
        TextField(
          controller: _inviteEmailController,
          decoration: const InputDecoration(
            labelText: 'Team member email',
            hintText: 'colleague@kitchenwatch.io',
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        SegmentedButton<UserRole>(
          segments: const [
            ButtonSegment(value: UserRole.manager, label: Text('Manager')),
            ButtonSegment(value: UserRole.employee, label: Text('Employee')),
          ],
          selected: {_inviteRole},
          onSelectionChanged: (set) {
            HapticUtil.light();
            setState(() {
              _inviteRole = set.first;
            });
          },
        ),
      ],
    );
  }
}

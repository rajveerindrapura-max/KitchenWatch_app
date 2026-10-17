import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/success_animation_dialog.dart';
import '../../activity/domain/movement.dart';
import '../domain/item_stock.dart';
import '../domain/stock_unit.dart';

enum RecordMode { received, used, wasted, adjustment }

class RecordStockScreen extends ConsumerStatefulWidget {
  final String? initialItemId;

  const RecordStockScreen({super.key, this.initialItemId});

  @override
  ConsumerState<RecordStockScreen> createState() => _RecordStockScreenState();
}

class _RecordStockScreenState extends ConsumerState<RecordStockScreen> {
  RecordMode _mode = RecordMode.used;
  String? _selectedOutletId;
  String? _selectedItemId;
  final _quantityController = TextEditingController(text: '1.0');
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  WasteReason _wasteReason = WasteReason.spoilage;
  DateTime? _expiryDate;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _selectedItemId = widget.initialItemId;
      final selectedOutlet = ref.read(selectedOutletIdProvider);
      final outlets = ref.read(outletsProvider).value ?? [];
      final user = ref.read(currentUserProvider).value;

      if (user != null) {
        if (selectedOutlet != null && user.canAccessOutlet(selectedOutlet)) {
          _selectedOutletId = selectedOutlet;
        } else if (user.assignedOutletIds.isNotEmpty) {
          _selectedOutletId = user.assignedOutletIds.first;
        } else if (outlets.isNotEmpty) {
          _selectedOutletId = outlets.first.id;
        }

        // If employee, default mode to Used
        if (user.isEmployee && (_mode == RecordMode.received || _mode == RecordMode.adjustment)) {
          _mode = RecordMode.used;
        }
      }

      final items = ref.read(itemStocksProvider).value ?? [];
      if (_selectedItemId == null && items.isNotEmpty) {
        _selectedItemId = items.first.item.id;
        _priceController.text = items.first.item.purchasePricePerUnit.toString();
      } else if (_selectedItemId != null) {
        final match = items.where((s) => s.item.id == _selectedItemId);
        if (match.isNotEmpty) {
          _priceController.text = match.first.item.purchasePricePerUnit.toString();
        }
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _stepQuantity(double delta) {
    HapticUtil.light();
    final current = double.tryParse(_quantityController.text) ?? 0.0;
    final next = (current + delta).clamp(0.5, 9999.0);
    _quantityController.text = next.toStringAsFixed(1);
  }

  Future<void> _handleSubmit() async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user == null || _selectedItemId == null || _selectedOutletId == null) return;

    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    if (quantity <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity greater than zero')),
      );
      return;
    }

    final inventoryRepo = ref.read(inventoryRepositoryProvider);

    try {
      String successTitle = 'Stock updated';
      if (_mode == RecordMode.received) {
        final price = double.tryParse(_priceController.text) ?? 0.0;
        await inventoryRepo.recordIncoming(
          user,
          itemId: _selectedItemId!,
          outletId: _selectedOutletId!,
          quantity: quantity,
          purchasePrice: price,
          expiryDate: _expiryDate,
        );
        successTitle = 'Received stock recorded';
      } else if (_mode == RecordMode.used) {
        await inventoryRepo.recordUsage(
          user,
          itemId: _selectedItemId!,
          outletId: _selectedOutletId!,
          quantity: quantity,
        );
        successTitle = 'Usage recorded';
      } else if (_mode == RecordMode.wasted) {
        await inventoryRepo.recordWastage(
          user,
          itemId: _selectedItemId!,
          outletId: _selectedOutletId!,
          quantity: quantity,
          reason: _wasteReason,
        );
        successTitle = 'Wastage recorded';
      } else if (_mode == RecordMode.adjustment) {
        if (_noteController.text.trim().isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adjustment note is mandatory')),
          );
          return;
        }
        await inventoryRepo.recordAdjustment(
          user,
          itemId: _selectedItemId!,
          outletId: _selectedOutletId!,
          newQuantity: quantity,
          note: _noteController.text.trim(),
        );
        successTitle = 'Adjustment recorded';
      }

      if (mounted) {
        await SuccessAnimationDialog.show(
          context,
          title: successTitle,
          subtitle: '${quantity.toStringAsFixed(1)} units processed',
        );
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final outletsAsync = ref.watch(outletsProvider);
    final itemsAsync = ref.watch(itemStocksProvider);

    final user = userAsync.value;
    final outlets = outletsAsync.value ?? [];
    final itemStocks = itemsAsync.value ?? [];

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final availableOutlets = user.isOwner
        ? outlets
        : outlets.where((o) => user.assignedOutletIds.contains(o.id)).toList();

    ItemStock? selectedStock;
    if (_selectedItemId != null) {
      final match = itemStocks.where((s) => s.item.id == _selectedItemId);
      if (match.isNotEmpty) selectedStock = match.first;
    }
    final unit = selectedStock?.item.unit ?? StockUnit.kg;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Stock'),
        actions: [
          if (PermissionGuard.canTransfer(user.role))
            TextButton.icon(
              onPressed: () {
                HapticUtil.light();
                context.push('/transfers/new?itemId=${_selectedItemId ?? ''}');
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Transfer'),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space20,
          vertical: AppDimensions.space12,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: ElevatedButton(
          onPressed: _handleSubmit,
          child: Text('Confirm ${_getModeVerb()}'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Mode Selector
              SegmentedButton<RecordMode>(
                segments: [
                  ButtonSegment(
                    value: RecordMode.received,
                    label: const Text('Received'),
                    enabled: !user.isEmployee,
                  ),
                  const ButtonSegment(value: RecordMode.used, label: Text('Used')),
                  const ButtonSegment(value: RecordMode.wasted, label: Text('Wasted')),
                  ButtonSegment(
                    value: RecordMode.adjustment,
                    label: const Text('Adjust'),
                    enabled: !user.isEmployee,
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (set) {
                  HapticUtil.selection();
                  setState(() => _mode = set.first);
                },
              ),
              if (user.isEmployee) ...[
                const SizedBox(height: AppDimensions.space6),
                Center(
                  child: Text(
                    'Employee permissions: Used and Wasted updates only',
                    style: AppTypography.labelSmall,
                  ),
                ),
              ],
              const SizedBox(height: AppDimensions.space16),

              // Outlet & Item Selector Card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outlet dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedOutletId,
                      decoration: const InputDecoration(labelText: 'Outlet location'),
                      items: availableOutlets
                          .map((o) => DropdownMenuItem(value: o.id, child: Text(o.name)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedOutletId = val);
                      },
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // Item dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedItemId,
                      decoration: const InputDecoration(labelText: 'Item'),
                      items: itemStocks
                          .map((s) => DropdownMenuItem(
                                value: s.item.id,
                                child: Text(s.item.effectiveDisplayName),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedItemId = val;
                            final item = itemStocks.firstWhere((s) => s.item.id == val).item;
                            _priceController.text = item.purchasePricePerUnit.toString();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Quantity Input with Steppers Card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mode == RecordMode.adjustment ? 'New physical count' : 'Quantity change',
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => _stepQuantity(-1.0),
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            textAlign: TextAlign.center,
                            style: AppTypography.monoDisplay,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              suffixText: unit.symbol,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        IconButton.filledTonal(
                          onPressed: () => _stepQuantity(1.0),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    // Quick add pill increments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _QuickIncrementPill(
                          label: '+5',
                          onTap: () => _stepQuantity(5.0),
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        _QuickIncrementPill(
                          label: '+10',
                          onTap: () => _stepQuantity(10.0),
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        _QuickIncrementPill(
                          label: '+25',
                          onTap: () => _stepQuantity(25.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Conditional Section: Received details (Price & Expiry)
              if (_mode == RecordMode.received)
                AppCard(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Batch details', style: AppTypography.titleSmall),
                      const SizedBox(height: AppDimensions.space12),
                      TextField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Actual purchase price per unit',
                          prefixText: '\u20B9 ',
                          suffixText: '/ ${unit.symbol}',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined, color: AppColors.brandBlue),
                        title: Text(
                          _expiryDate == null
                              ? 'Set expiry date (optional)'
                              : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                          style: AppTypography.bodyMedium,
                        ),
                        trailing: _expiryDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => setState(() => _expiryDate = null),
                              )
                            : const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _expiryDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),

              // Conditional Section: Wasted Reason
              if (_mode == RecordMode.wasted)
                AppCard(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wastage reason', style: AppTypography.titleSmall),
                      const SizedBox(height: AppDimensions.space12),
                      DropdownButtonFormField<WasteReason>(
                        initialValue: _wasteReason,
                        decoration: const InputDecoration(labelText: 'Select reason'),
                        items: WasteReason.values
                            .map((r) => DropdownMenuItem(value: r, child: Text(r.displayName)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _wasteReason = val);
                        },
                      ),
                    ],
                  ),
                ),

              // Conditional Section: Adjustment note (mandatory)
              if (_mode == RecordMode.adjustment)
                AppCard(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audit Note (Mandatory)', style: AppTypography.titleSmall),
                      const SizedBox(height: AppDimensions.space12),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Reason for adjustment',
                          hintText: 'e.g. Physical stock count discrepancy',
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppDimensions.space32),
            ],
          ),
        ),
      ),
    );
  }

  String _getModeVerb() {
    switch (_mode) {
      case RecordMode.received:
        return 'receipt';
      case RecordMode.used:
        return 'usage';
      case RecordMode.wasted:
        return 'wastage';
      case RecordMode.adjustment:
        return 'adjustment';
    }
  }
}

class _QuickIncrementPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickIncrementPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: AppTypography.labelSmall),
      onPressed: onTap,
      backgroundColor: AppColors.surfaceMuted,
      side: const BorderSide(color: AppColors.border, width: 1),
    );
  }
}

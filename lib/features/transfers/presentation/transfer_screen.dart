import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/sample_data_badge.dart';
import '../../../core/widgets/staggered_list.dart';
import '../../../core/widgets/success_animation_dialog.dart';
import '../../inventory/domain/item_stock.dart';
import '../domain/transfer.dart';

class TransferScreen extends ConsumerStatefulWidget {
  final String? initialItemId;
  final String? initialQuantity;
  final String? initialFromOutletId;

  const TransferScreen({
    super.key,
    this.initialItemId,
    this.initialQuantity,
    this.initialFromOutletId,
  });

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // New transfer form state
  String? _fromOutletId;
  String? _toOutletId;
  final _notesController = TextEditingController();

  final List<TransferItem> _selectedItems = [];
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final outlets = ref.read(outletsProvider).value ?? [];
      final stocks = ref.read(itemStocksProvider).value ?? [];

      if (outlets.length >= 2) {
        _fromOutletId = widget.initialFromOutletId ?? outlets[0].id;
        _toOutletId = outlets.firstWhere((o) => o.id != _fromOutletId, orElse: () => outlets[1]).id;
      }

      if (widget.initialItemId != null && stocks.isNotEmpty) {
        final match = stocks.where((s) => s.item.id == widget.initialItemId);
        if (match.isNotEmpty) {
          final stock = match.first;
          final qty = double.tryParse(widget.initialQuantity ?? '5.0') ?? 5.0;
          _selectedItems.add(
            TransferItem(
              itemId: stock.item.id,
              itemName: stock.item.effectiveDisplayName,
              quantity: qty,
              unit: stock.item.unit,
              estimatedValue: qty * stock.item.purchasePricePerUnit,
            ),
          );
          // Switch tab to "New Transfer" if prefilled
          _tabController.index = 1;
        }
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItemToTransfer(ItemStock stock, double qty) {
    HapticUtil.light();
    final existingIndex = _selectedItems.indexWhere((i) => i.itemId == stock.item.id);
    final estValue = qty * stock.item.purchasePricePerUnit;

    setState(() {
      if (existingIndex != -1) {
        _selectedItems[existingIndex] = TransferItem(
          itemId: stock.item.id,
          itemName: stock.item.effectiveDisplayName,
          quantity: qty,
          unit: stock.item.unit,
          estimatedValue: estValue,
        );
      } else {
        _selectedItems.add(
          TransferItem(
            itemId: stock.item.id,
            itemName: stock.item.effectiveDisplayName,
            quantity: qty,
            unit: stock.item.unit,
            estimatedValue: estValue,
          ),
        );
      }
    });
  }

  void _removeItem(int index) {
    HapticUtil.light();
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  Future<void> _handleConfirmTransfer() async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user == null || !mounted) return;

    if (_fromOutletId == null || _toOutletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both origin and destination outlets')),
      );
      return;
    }

    if (_fromOutletId == _toOutletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Origin and destination outlets cannot be identical')),
      );
      return;
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to transfer')),
      );
      return;
    }

    final transferRepo = ref.read(transferRepositoryProvider);
    try {
      await transferRepo.createTransfer(
        user,
        fromOutletId: _fromOutletId!,
        toOutletId: _toOutletId!,
        items: _selectedItems,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        await SuccessAnimationDialog.show(
          context,
          title: 'Stock transfer initiated',
          subtitle: '${_selectedItems.length} items moved successfully',
        );
        setState(() {
          _selectedItems.clear();
          _notesController.clear();
          _tabController.index = 0; // Return to history list
        });
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
    final transfersAsync = ref.watch(transfersProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    final user = userAsync.value;
    final outlets = outletsAsync.value ?? [];
    final transfers = transfersAsync.value ?? [];

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canTransfer = PermissionGuard.canTransfer(user.role);
    if (!canTransfer) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transfers')),
        body: const Center(
          child: Text('Only owners and managers can transfer stock'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('Stock Transfers', style: AppTypography.titleLarge),
            const SizedBox(width: AppDimensions.space8),
            if (isDemoMode) const SampleDataBadge(),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.transferViolet,
          labelColor: AppColors.transferViolet,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Transfer Ledger'),
            Tab(text: 'New Transfer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Transfers History
          _buildTransfersLedger(transfers),

          // Tab 2: New Transfer Form
          _buildNewTransferForm(outlets),
        ],
      ),
    );
  }

  Widget _buildTransfersLedger(List<TransferRecord> transfers) {
    if (transfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz_rounded, size: 48, color: AppColors.textLight),
            const SizedBox(height: AppDimensions.space12),
            Text('No transfers recorded yet', style: AppTypography.titleSmall),
            const SizedBox(height: AppDimensions.space4),
            Text('Move inventory between outlets when required', style: AppTypography.bodySmall),
            const SizedBox(height: AppDimensions.space16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.transferViolet),
              onPressed: () => _tabController.animateTo(1),
              child: const Text('Initiate transfer'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.space16),
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        final tx = transfers[index];

        return StaggeredListItem(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
            child: AppCard(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz_rounded, color: AppColors.transferViolet, size: 20),
                          const SizedBox(width: AppDimensions.space8),
                          Text(
                            DateFormatter.timeAgo(tx.timestamp),
                            style: AppTypography.labelMedium,
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.format(tx.totalValue),
                        style: AppTypography.monoMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.transferViolet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space10),
                  // Outlet Route
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tx.fromOutletName,
                          style: AppTypography.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMuted),
                      ),
                      Expanded(
                        child: Text(
                          tx.toOutletName,
                          style: AppTypography.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space10),
                  const Divider(),
                  const SizedBox(height: AppDimensions.space8),
                  // Transferred items list
                  ...tx.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.space4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.itemName, style: AppTypography.bodyMedium),
                          Text(
                            '${item.quantity.toStringAsFixed(1)} ${item.unit.symbol}',
                            style: AppTypography.monoSmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppDimensions.space6),
                  Text(
                    'Initiated by ${tx.initiatedByUserName}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewTransferForm(List<dynamic> outlets) {
    final stocksAsync = ref.watch(itemStocksProvider);
    final stocks = stocksAsync.value ?? [];

    final isSameOutlet = _fromOutletId == _toOutletId && _fromOutletId != null;
    final totalTransferValue = _selectedItems.fold(0.0, (sum, i) => sum + i.estimatedValue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Outlet Route Selection Card
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transfer Route', style: AppTypography.titleSmall),
                const SizedBox(height: AppDimensions.space12),
                DropdownButtonFormField<String>(
                  initialValue: _fromOutletId,
                  decoration: const InputDecoration(labelText: 'From outlet (Source)'),
                  items: outlets
                      .map((o) => DropdownMenuItem(value: o.id as String, child: Text(o.name as String)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _fromOutletId = val);
                  },
                ),
                const SizedBox(height: AppDimensions.space12),
                DropdownButtonFormField<String>(
                  initialValue: _toOutletId,
                  decoration: InputDecoration(
                    labelText: 'To outlet (Destination)',
                    errorText: isSameOutlet ? 'Destination must be different from source' : null,
                  ),
                  items: outlets
                      .map((o) => DropdownMenuItem(value: o.id as String, child: Text(o.name as String)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _toOutletId = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space16),

          // Items to Transfer Card
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Items to Move', style: AppTypography.titleSmall),
                    TextButton.icon(
                      onPressed: () => _showAddItemPicker(context, stocks),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add item'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space8),
                if (_selectedItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
                    child: Center(
                      child: Text(
                        'Tap "Add item" to select items for this transfer',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  )
                else
                  ..._selectedItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.space12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.itemName, style: AppTypography.titleSmall),
                                  Text(
                                    '${item.quantity.toStringAsFixed(1)} ${item.unit.symbol} (Est. ${CurrencyFormatter.format(item.estimatedValue)})',
                                    style: AppTypography.monoSmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.wastageRose),
                              onPressed: () => _removeItem(idx),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space16),

          // Notes
          AppCard(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Transfer notes (optional)',
                hintText: 'e.g. Near-expiry rebalancing or rush request',
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.space20),

          // Transfer Summary & Confirm
          if (_selectedItems.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.all(AppDimensions.space16),
              color: AppColors.transferVioletLight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimated transfer value', style: AppTypography.labelSmall),
                      Text(
                        CurrencyFormatter.format(totalTransferValue),
                        style: AppTypography.monoLarge.copyWith(color: AppColors.transferViolet),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.transferViolet,
                      minimumSize: const Size(140, 48),
                    ),
                    onPressed: isSameOutlet ? null : _handleConfirmTransfer,
                    child: const Text('Confirm transfer'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppDimensions.space40),
        ],
      ),
    );
  }

  void _showAddItemPicker(BuildContext context, List<ItemStock> stocks) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  child: Text('Select item to transfer', style: AppTypography.titleMedium),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: stocks.length,
                    itemBuilder: (ctx, index) {
                      final stock = stocks[index];
                      return ListTile(
                        title: Text(stock.item.effectiveDisplayName),
                        subtitle: Text(
                          'Stock: ${stock.totalQuantity.toStringAsFixed(1)} ${stock.item.unit.symbol}',
                        ),
                        trailing: const Icon(Icons.add_circle_outline, color: AppColors.transferViolet),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showQuantityDialog(stock);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQuantityDialog(ItemStock stock) {
    final controller = TextEditingController(text: '5.0');
    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          title: Text('Transfer ${stock.item.effectiveDisplayName}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Quantity',
              suffixText: stock.item.unit.symbol,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(controller.text) ?? 1.0;
                Navigator.pop(dlgContext);
                _addItemToTransfer(stock, qty);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

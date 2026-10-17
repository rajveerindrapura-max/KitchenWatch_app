import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/outlet_switcher.dart';
import '../../../core/widgets/sample_data_badge.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/staggered_list.dart';
import '../../auth/domain/user.dart';
import '../domain/item_stock.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _onlyLowStock = false;

  final List<String> _categories = [
    'All',
    'Dairy',
    'Produce',
    'Grains & Flours',
    'Oils & Fats',
    'Meat & Poultry',
    'Spices',
    'Packaging',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleStepStock(
    User user,
    ItemStock stock, {
    required bool isAdd,
  }) async {
    HapticUtil.selection();

    final selectedOutletId = ref.read(selectedOutletIdProvider);
    final outlets = ref.read(outletsProvider).value ?? [];
    final targetOutletId = selectedOutletId ??
        (stock.batches.isNotEmpty
            ? stock.batches.first.outletId
            : (outlets.isNotEmpty ? outlets.first.id : ''));

    if (targetOutletId.isEmpty) return;

    final stepQty = stock.item.mainPacketSize > 0 ? stock.item.mainPacketSize : 1.0;

    if (isAdd) {
      if (user.role == UserRole.employee) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Employees cannot add incoming stock'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      await ref.read(inventoryRepositoryProvider).recordIncoming(
            user,
            itemId: stock.item.id,
            outletId: targetOutletId,
            quantity: stepQty,
            purchasePrice: stock.item.purchasePricePerUnit,
          );
    } else {
      if (stock.totalQuantity <= 0) return;
      final actualDeduct = stepQty > stock.totalQuantity ? stock.totalQuantity : stepQty;

      await ref.read(inventoryRepositoryProvider).recordUsage(
            user,
            itemId: stock.item.id,
            outletId: targetOutletId,
            quantity: actualDeduct,
          );
    }
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (category) {
      case 'Grains & Flours':
        icon = Icons.grain_rounded;
        iconColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'Oils & Fats':
        icon = Icons.water_drop_rounded;
        iconColor = const Color(0xFFCA8A04);
        bgColor = const Color(0xFFFEF9C3);
        break;
      case 'Dairy':
        icon = Icons.egg_alt_rounded;
        iconColor = const Color(0xFF0284C7);
        bgColor = const Color(0xFFE0F2FE);
        break;
      case 'Produce':
        icon = Icons.eco_rounded;
        iconColor = const Color(0xFF16A34A);
        bgColor = const Color(0xFFDCFCE7);
        break;
      case 'Meat & Poultry':
        icon = Icons.restaurant_rounded;
        iconColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case 'Spices':
        icon = Icons.flare_rounded;
        iconColor = const Color(0xFFEA580C);
        bgColor = const Color(0xFFFFEDD5);
        break;
      case 'Packaging':
        icon = Icons.inventory_2_rounded;
        iconColor = const Color(0xFF7C3AED);
        bgColor = const Color(0xFFEDE9FE);
        break;
      default:
        icon = Icons.inventory_2_outlined;
        iconColor = const Color(0xFF475569);
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }

  Widget _buildStatusBadge(bool isLowStock) {
    final bgColor = isLowStock ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final textColor = isLowStock ? const Color(0xFFB91C1C) : const Color(0xFF15803D);
    final label = isLowStock ? 'Low Stock' : 'Healthy';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildCompactProgressBar(double currentStock, double minStock) {
    final ratio = minStock > 0 ? (currentStock / (minStock * 2)).clamp(0.0, 1.0) : 1.0;
    final isLow = currentStock <= minStock;
    final isOut = currentStock <= 0;
    final color = isOut
        ? const Color(0xFFEF4444)
        : (isLow ? const Color(0xFFF59E0B) : const Color(0xFF22C55E));

    return Container(
      width: 60,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: ratio,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required bool isAdd,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isAdd
                ? const Color(0xFF2563EB)
                : (enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC)),
            shape: BoxShape.circle,
            border: isAdd
                ? null
                : Border.all(
                    color: enabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                    width: 1.0,
                  ),
            boxShadow: isAdd
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: isAdd
                  ? Colors.white
                  : (enabled ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final itemStocksAsync = ref.watch(itemStocksProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    final user = userAsync.value;
    final itemStocks = itemStocksAsync.value ?? [];

    if (user == null || itemStocksAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Inventory')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const Padding(
              padding: EdgeInsets.all(AppDimensions.space16),
              child: Column(
                children: [
                  SkeletonLoader(width: double.infinity, height: 48),
                  SizedBox(height: AppDimensions.space16),
                  SkeletonLoader(width: double.infinity, height: 300),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final canAddItem = PermissionGuard.canAddItem(user.role);
    final canViewValuation = PermissionGuard.canViewStockValue(user.role);

    // Apply filters
    var filteredStocks = itemStocks.where((s) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty && !s.item.effectiveDisplayName.toLowerCase().contains(query)) {
        return false;
      }
      if (_selectedCategory != 'All' && s.item.category != _selectedCategory) {
        return false;
      }
      if (_onlyLowStock && !s.isLowStock) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('Inventory', style: AppTypography.titleLarge),
            const SizedBox(width: AppDimensions.space8),
            if (isDemoMode) const SampleDataBadge(),
          ],
        ),
        actions: const [
          OutletSwitcher(),
          SizedBox(width: AppDimensions.space12),
        ],
      ),
      floatingActionButton: canAddItem
          ? FloatingActionButton(
              onPressed: () {
                HapticUtil.medium();
                context.push('/inventory/add');
              },
              backgroundColor: AppColors.brandBlue,
              foregroundColor: AppColors.textInverse,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                // Search Input Box
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: AppDimensions.space8,
                  ),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),

                // Category Filter Pills
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    itemCount: _categories.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.space8),
                    itemBuilder: (context, index) {
                      if (index == _categories.length) {
                        // Low Stock Filter Pill
                        final isSelected = _onlyLowStock;
                        return GestureDetector(
                          onTap: () {
                            HapticUtil.selection();
                            setState(() => _onlyLowStock = !_onlyLowStock);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Low Stock',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? const Color(0xFFB91C1C) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        );
                      }

                      final category = _categories[index];
                      final isSelected = _selectedCategory == category && !_onlyLowStock;

                      return GestureDetector(
                        onTap: () {
                          HapticUtil.selection();
                          setState(() {
                            _selectedCategory = category;
                            _onlyLowStock = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),

                // Items Count Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredStocks.length} items',
                        style: AppTypography.bodySmall,
                      ),
                      if (_onlyLowStock)
                        Text(
                          'Filtered: Attention needed',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.lowStockAmber),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),

                // List of items as Centered Modern Cards
                Expanded(
                  child: filteredStocks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textLight),
                              const SizedBox(height: AppDimensions.space8),
                              Text('No items found', style: AppTypography.titleSmall),
                              const SizedBox(height: AppDimensions.space4),
                              Text('Try adjusting your search or category filter', style: AppTypography.bodySmall),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space16,
                            vertical: AppDimensions.space8,
                          ),
                          itemCount: filteredStocks.length,
                          itemBuilder: (context, index) {
                            final stock = filteredStocks[index];
                            final item = stock.item;

                            return StaggeredListItem(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () {
                                        HapticUtil.light();
                                        context.push('/inventory/item/${item.id}');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Left Icon Container
                                            _getCategoryIcon(item.category),
                                            const SizedBox(width: 14),

                                            // Center Info Column
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.effectiveDisplayName,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF0F172A),
                                                      letterSpacing: -0.2,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item.category,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w400,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${stock.totalQuantity.toStringAsFixed(1)} ${item.unit.symbol}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF0F172A),
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Wrap(
                                                    crossAxisAlignment: WrapCrossAlignment.center,
                                                    spacing: 8,
                                                    runSpacing: 4,
                                                    children: [
                                                      Text(
                                                        'Min: ${item.minLevel.toStringAsFixed(1)} ${item.unit.symbol}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: Color(0xFF64748B),
                                                        ),
                                                      ),
                                                      _buildStatusBadge(stock.isLowStock),
                                                      _buildCompactProgressBar(
                                                        stock.totalQuantity,
                                                        item.minLevel,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Right Column with Value and Steppers
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                if (canViewValuation && stock.totalValue > 0) ...[
                                                  Text(
                                                    CurrencyFormatter.format(stock.totalValue),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF64748B),
                                                      fontFamily: 'JetBrainsMono',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                ],
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    _buildStepperButton(
                                                      icon: Icons.remove_rounded,
                                                      isAdd: false,
                                                      enabled: stock.totalQuantity > 0,
                                                      onTap: () => _handleStepStock(
                                                        user,
                                                        stock,
                                                        isAdd: false,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildStepperButton(
                                                      icon: Icons.add_rounded,
                                                      isAdd: true,
                                                      enabled: true,
                                                      onTap: () => _handleStepStock(
                                                        user,
                                                        stock,
                                                        isAdd: true,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

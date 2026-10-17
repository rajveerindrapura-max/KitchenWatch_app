import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/domain/permission_guard.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/outlet_switcher.dart';
import '../../../core/widgets/sample_data_badge.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/staggered_list.dart';
import '../../../core/widgets/stock_level_bar.dart';

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
    'Grains & Flours',
    'Oils & Fats',
    'Dairy',
    'Produce',
    'Meat & Poultry',
    'Spices',
    'Packaging',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        body: const Padding(
          padding: EdgeInsets.all(AppDimensions.space16),
          child: Column(
            children: [
              SkeletonLoader(width: double.infinity, height: 48),
              SizedBox(height: AppDimensions.space16),
              SkeletonLoader(width: double.infinity, height: 300),
            ],
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
        actions: [
          const OutletSwitcher(),
          const SizedBox(width: AppDimensions.space12),
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
        child: Column(
          children: [
            // Search and quick filter
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12,
                    vertical: AppDimensions.space12,
                  ),
                ),
              ),
            ),

            // Category Filter Pills
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                itemCount: _categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.space8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Low Stock toggle pill
                    return FilterChip(
                      selected: _onlyLowStock,
                      showCheckmark: false,
                      label: Text('Low stock only', style: AppTypography.labelSmall),
                      selectedColor: AppColors.lowStockAmberLight,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: _onlyLowStock ? AppColors.lowStockAmber : AppColors.border,
                      ),
                      onSelected: (val) {
                        HapticUtil.selection();
                        setState(() => _onlyLowStock = val);
                      },
                    );
                  }

                  final category = _categories[index - 1];
                  final isSelected = _selectedCategory == category;

                  return FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    label: Text(category, style: AppTypography.labelSmall),
                    selectedColor: AppColors.brandBlueLight,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected ? AppColors.brandBlue : AppColors.border,
                    ),
                    onSelected: (val) {
                      HapticUtil.selection();
                      setState(() => _selectedCategory = category);
                    },
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

            // List of items
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
                            padding: const EdgeInsets.only(bottom: AppDimensions.space10),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppDimensions.space14),
                              onTap: () {
                                HapticUtil.light();
                                context.push('/inventory/item/${item.id}');
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Item icon placeholder
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceMuted,
                                          borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                                        ),
                                        child: const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 20,
                                          color: AppColors.brandBlue,
                                        ),
                                      ),
                                      const SizedBox(width: AppDimensions.space12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.effectiveDisplayName,
                                              style: AppTypography.titleSmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              item.category,
                                              style: AppTypography.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${stock.totalQuantity.toStringAsFixed(1)} ${item.unit.symbol}',
                                            style: AppTypography.monoMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: stock.isLowStock
                                                  ? AppColors.lowStockAmber
                                                  : AppColors.textDark,
                                            ),
                                          ),
                                          if (canViewValuation)
                                            Text(
                                              CurrencyFormatter.format(stock.totalValue),
                                              style: AppTypography.monoSmall,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppDimensions.space10),
                                  StockLevelBar(
                                    currentStock: stock.totalQuantity,
                                    minStock: item.minLevel,
                                  ),
                                  const SizedBox(height: AppDimensions.space4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Min: ${item.minLevel.toStringAsFixed(1)} ${item.unit.symbol}',
                                        style: AppTypography.bodySmall,
                                      ),
                                      if (stock.isLowStock)
                                        Text(
                                          'Low stock',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.lowStockAmber,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
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
    );
  }
}

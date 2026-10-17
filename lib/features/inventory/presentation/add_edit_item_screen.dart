import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/success_animation_dialog.dart';
import '../domain/item.dart';
import '../domain/stock_unit.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  final String? itemId;

  const AddEditItemScreen({super.key, this.itemId});

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _nameController = TextEditingController();
  final _mainPacketSizeController = TextEditingController(text: '1.0');
  final _minLevelController = TextEditingController(text: '10.0');
  final _priceController = TextEditingController(text: '100.0');
  final _vendorController = TextEditingController();

  String _category = 'Grains & Flours';
  StockUnit _unit = StockUnit.kg;
  bool _trackExpiry = false;
  String? _selectedImageKey;
  bool _isInit = false;

  final List<String> _categories = [
    'Grains & Flours',
    'Oils & Fats',
    'Dairy',
    'Produce',
    'Meat & Poultry',
    'Spices',
    'Packaging',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && widget.itemId != null) {
      final stocks = ref.read(itemStocksProvider).value ?? [];
      final match = stocks.where((s) => s.item.id == widget.itemId);
      if (match.isNotEmpty) {
        final item = match.first.item;
        _nameController.text = item.name;
        _category = item.category;
        _unit = item.unit;
        _mainPacketSizeController.text = item.mainPacketSize.toString();
        _minLevelController.text = item.minLevel.toString();
        _priceController.text = item.purchasePricePerUnit.toString();
        _trackExpiry = item.trackExpiry;
        _vendorController.text = item.preferredVendor ?? '';
        _selectedImageKey = item.imageUrl;
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mainPacketSizeController.dispose();
    _minLevelController.dispose();
    _priceController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty && (_selectedImageKey == null || _selectedImageKey!.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provide an item name or select an image')),
      );
      return;
    }

    final mainPacketSize = double.tryParse(_mainPacketSizeController.text) ?? 1.0;
    final minLevel = double.tryParse(_minLevelController.text) ?? 5.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final vendor = _vendorController.text.trim().isNotEmpty ? _vendorController.text.trim() : null;

    final item = Item(
      id: widget.itemId ?? '',
      name: name,
      category: _category,
      unit: _unit,
      mainPacketSize: mainPacketSize,
      minLevel: minLevel,
      purchasePricePerUnit: price,
      trackExpiry: _trackExpiry,
      preferredVendor: vendor,
      imageUrl: _selectedImageKey,
    );

    final repo = ref.read(inventoryRepositoryProvider);
    try {
      if (widget.itemId == null) {
        await repo.addItem(user, item);
      } else {
        await repo.updateItem(user, item);
      }

      if (mounted) {
        await SuccessAnimationDialog.show(
          context,
          title: widget.itemId == null ? 'Item added' : 'Item updated',
          subtitle: item.effectiveDisplayName,
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
    final isEditing = widget.itemId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add Item'),
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
          onPressed: _handleSave,
          child: Text(isEditing ? 'Save changes' : 'Add to inventory'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo attachment / preview card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _selectedImageKey != null ? AppColors.brandBlueLight : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Icon(
                        _selectedImageKey != null ? Icons.image_rounded : Icons.camera_alt_outlined,
                        color: _selectedImageKey != null ? AppColors.brandBlue : AppColors.textMuted,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Photo (optional)', style: AppTypography.titleSmall),
                          const SizedBox(height: AppDimensions.space2),
                          Text('Name is optional if photo attached', style: AppTypography.bodySmall),
                          const SizedBox(height: AppDimensions.space6),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(110, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            onPressed: () {
                              HapticUtil.selection();
                              setState(() {
                                _selectedImageKey = _selectedImageKey == null ? 'photo_attached' : null;
                              });
                            },
                            child: Text(
                              _selectedImageKey == null ? 'Attach photo' : 'Remove photo',
                              style: AppTypography.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Item details form card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: _selectedImageKey != null ? 'Item name (optional)' : 'Item name',
                        hintText: 'e.g. Basmati Rice',
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    DropdownButtonFormField<StockUnit>(
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Primary unit'),
                      items: StockUnit.values
                          .map((u) => DropdownMenuItem(value: u, child: Text(u.symbol)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _unit = val);
                      },
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _mainPacketSizeController,
                            decoration: InputDecoration(
                              labelText: 'Main packet size',
                              suffixText: _unit.symbol,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: TextField(
                            controller: _minLevelController,
                            decoration: InputDecoration(
                              labelText: 'Minimum level',
                              suffixText: _unit.symbol,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Standard purchase price',
                        prefixText: '\u20B9 ',
                        suffixText: '/ ${_unit.symbol}',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Track expiry dates', style: AppTypography.titleSmall),
                      subtitle: Text('Alerts when batches near shelf life', style: AppTypography.bodySmall),
                      value: _trackExpiry,
                      activeTrackColor: AppColors.brandBlue,
                      onChanged: (val) {
                        HapticUtil.selection();
                        setState(() => _trackExpiry = val);
                      },
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    TextField(
                      controller: _vendorController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred vendor (stored only)',
                        hintText: 'e.g. Apex Agro Supplies',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space40),
            ],
          ),
        ),
      ),
    );
  }
}

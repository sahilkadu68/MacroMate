import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/food_item.dart';
import '../../data/models/meal_entry.dart';
import '../../providers/food_provider.dart';
import '../../providers/meal_provider.dart';
import '../../services/dietary_service.dart';
import '../../shared/widgets/metric_badge.dart';

class StagedMealItem {
  final FoodItem food;
  double quantity;

  StagedMealItem({required this.food, required this.quantity});

  double get calories => food.caloriesForQuantity(quantity);
  double get protein => food.proteinForQuantity(quantity);
  double get carbs => food.carbsForQuantity(quantity);
  double get fat => food.fatForQuantity(quantity);
  double get cost => food.costForQuantity(quantity);
}

class LogMealScreen extends StatefulWidget {
  final String initialMealType;
  final DateTime entryDate;
  final MealEntry? existingEntry; // If editing an existing meal entry

  const LogMealScreen({
    super.key,
    this.initialMealType = AppConstants.mealBreakfast,
    required this.entryDate,
    this.existingEntry,
  });

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  late String _selectedMealType;
  final List<StagedMealItem> _stagedItems = [];
  final TextEditingController _searchController = TextEditingController();
  int _activeSourceTab = 0; // 0: All Foods, 1: Recent, 2: Favourites
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.existingEntry?.mealType ?? widget.initialMealType;

    if (widget.existingEntry != null) {
      // Editing existing single entry: stage it immediately
      final entry = widget.existingEntry!;
      final placeholderFood = FoodItem(
        id: entry.foodId,
        name: entry.foodNameSnapshot,
        category: AppConstants.catOther,
        dietaryClassification: AppConstants.dietVeg,
        caloriesPer100: (entry.caloriesSnapshot / entry.quantity) * 100,
        proteinPer100: (entry.proteinSnapshot / entry.quantity) * 100,
        carbsPer100: (entry.carbsSnapshot / entry.quantity) * 100,
        fatPer100: (entry.fatSnapshot / entry.quantity) * 100,
        measurementUnit: entry.measurementUnit,
        preparationBasis: entry.preparationBasis,
        estimatedUnitPrice: entry.unitPriceSnapshot,
        priceQuantityBasis: 100.0,
      );
      _stagedItems.add(StagedMealItem(food: placeholderFood, quantity: entry.quantity));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _totalCalories => _stagedItems.fold(0.0, (sum, i) => sum + i.calories);
  double get _totalProtein => _stagedItems.fold(0.0, (sum, i) => sum + i.protein);
  double get _totalCarbs => _stagedItems.fold(0.0, (sum, i) => sum + i.carbs);
  double get _totalFat => _stagedItems.fold(0.0, (sum, i) => sum + i.fat);
  double get _totalCost => _stagedItems.fold(0.0, (sum, i) => sum + i.cost);

  void _addFoodToStaged(FoodItem food) {
    // If food already staged, increase quantity by 100 or default unit
    final existingIdx = _stagedItems.indexWhere((i) => i.food.id == food.id && food.id != null);
    if (existingIdx != -1) {
      setState(() {
        _stagedItems[existingIdx].quantity += (food.measurementUnit == 'piece' ? 1.0 : 50.0);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated ${food.name} portion to ${_stagedItems[existingIdx].quantity.toInt()}${food.measurementUnit}'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    _showPortionDialog(food);
  }

  void _showPortionDialog(FoodItem food, {int? editIndex}) {
    final isEditing = editIndex != null;
    final initialQty = isEditing ? _stagedItems[editIndex].quantity : (food.measurementUnit == 'piece' ? 2.0 : 100.0);
    final controller = TextEditingController(text: initialQty.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final parsedQty = double.tryParse(controller.text.trim()) ?? 0.0;
            final cal = food.caloriesForQuantity(parsedQty);
            final prot = food.proteinForQuantity(parsedQty);
            final cost = food.costForQuantity(parsedQty);

            return AlertDialog(
              title: Text(food.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: DietaryService.getClassificationColor(food.dietaryClassification).withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          food.dietaryClassification,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: DietaryService.getClassificationColor(food.dietaryClassification),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Basis: ${food.preparationBasis}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Serving Quantity (${food.measurementUnit})',
                      suffixText: food.measurementUnit,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDialogStat('Protein', '${prot.toStringAsFixed(1)}g', AppColors.protein),
                        _buildDialogStat('Calories', '${cal.round()} kcal', AppColors.calories),
                        _buildDialogStat('Est. Cost', Formatters.currency(cost), AppColors.secondary),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(controller.text.trim());
                    if (qty == null || qty <= 0) return;
                    setState(() {
                      if (isEditing) {
                        _stagedItems[editIndex].quantity = qty;
                      } else {
                        _stagedItems.add(StagedMealItem(food: food, quantity: qty));
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(isEditing ? 'Update Portion' : 'Add to Meal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }

  Future<void> _handleSaveMeal() async {
    if (_stagedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one food item.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final mealProvider = Provider.of<MealProvider>(context, listen: false);

    try {
      if (widget.existingEntry != null && _stagedItems.length == 1) {
        // Update single existing entry
        final staged = _stagedItems.first;
        final updated = widget.existingEntry!.copyWith(
          mealType: _selectedMealType,
          quantity: staged.quantity,
          caloriesSnapshot: staged.calories,
          proteinSnapshot: staged.protein,
          carbsSnapshot: staged.carbs,
          fatSnapshot: staged.fat,
          costSnapshot: staged.cost,
        );
        await mealProvider.updateMeal(updated);
      } else {
        // Save new or multi-item entries atomically
        final newEntries = _stagedItems.map((staged) {
          return MealEntry.fromFoodItem(
            food: staged.food,
            entryDate: widget.entryDate,
            mealType: _selectedMealType,
            quantity: staged.quantity,
          );
        }).toList();

        await mealProvider.addMultipleMeals(newEntries);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Saved ${_stagedItems.length} item(s) to $_selectedMealType!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error saving meal: $e')),
        );
      }
    }
  }

  Future<void> _handleRepeatYesterday() async {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final count = await mealProvider.repeatYesterdayMeal(_selectedMealType);
    if (mounted) {
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Repeated $count item(s) from yesterday\'s $_selectedMealType!'),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No $_selectedMealType was recorded yesterday.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foodProvider = Provider.of<FoodProvider>(context);
    final mealProvider = Provider.of<MealProvider>(context);

    // Filter candidate list based on active tab
    List<FoodItem> sourceFoods;
    if (_activeSourceTab == 1) {
      final recentIds = mealProvider.recentFoodIds;
      sourceFoods = foodProvider.allFoods.where((f) => f.id != null && recentIds.contains(f.id)).toList();
    } else if (_activeSourceTab == 2) {
      sourceFoods = foodProvider.allFoods.where((f) => foodProvider.isFavorite(f.id)).toList();
    } else {
      sourceFoods = foodProvider.allFoods;
    }

    if (_searchController.text.trim().isNotEmpty) {
      final q = _searchController.text.trim().toLowerCase();
      sourceFoods = sourceFoods.where((f) => f.name.toLowerCase().contains(q) || f.category.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry != null ? 'Edit Meal Entry' : 'Log Meal'),
        actions: [
          if (widget.existingEntry == null)
            TextButton.icon(
              icon: const Icon(Icons.history, size: 18),
              label: const Text('Repeat Yesterday', style: TextStyle(fontSize: 12)),
              onPressed: _handleRepeatYesterday,
            ),
        ],
      ),
      body: Column(
        children: [
          // Meal Slot Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.mealTypes.map((type) {
                  final isSelected = _selectedMealType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      onSelected: (val) {
                        if (val) setState(() => _selectedMealType = type);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Staged Items Section (if any foods added)
          if (_stagedItems.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              color: AppColors.surfaceVariantLight.withAlpha(50),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items in this Meal (${_stagedItems.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '${_totalProtein.toStringAsFixed(1)}g P · ${Formatters.currency(_totalCost)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _stagedItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final item = _stagedItems[idx];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.food.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${item.quantity.toInt()}${item.food.measurementUnit} · ${item.protein.toStringAsFixed(1)}g P · ${item.calories.round()} kcal · ${Formatters.currency(item.cost)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                onPressed: () => _showPortionDialog(item.food, editIndex: idx),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.red),
                                onPressed: () => setState(() => _stagedItems.removeAt(idx)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Food Source Selector & Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search foods...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter Sources',
                  initialValue: _activeSourceTab,
                  onSelected: (val) => setState(() => _activeSourceTab = val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 0, child: Text('All Foods')),
                    const PopupMenuItem(value: 1, child: Text('Recently Logged')),
                    const PopupMenuItem(value: 2, child: Text('Favourites')),
                  ],
                ),
              ],
            ),
          ),

          // Category Chips for fast tapping
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSourceFilterChip('All Foods', 0),
                const SizedBox(width: 6),
                _buildSourceFilterChip('Recently Logged', 1),
                const SizedBox(width: 6),
                _buildSourceFilterChip('Favourites', 2),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Food List Tiles
          Expanded(
            child: sourceFoods.isEmpty
                ? Center(
                    child: Text(
                      _activeSourceTab == 1
                          ? 'No recent foods logged yet.'
                          : _activeSourceTab == 2
                              ? 'No favourite foods marked yet.'
                              : 'No matching foods found.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: sourceFoods.length,
                    itemBuilder: (ctx, index) {
                      final food = sourceFoods[index];
                      final isFav = foodProvider.isFavorite(food.id);

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: DietaryService.getClassificationColor(food.dietaryClassification).withAlpha(30),
                          child: Text(
                            DietaryService.getClassificationLabel(food.dietaryClassification)[0],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: DietaryService.getClassificationColor(food.dietaryClassification),
                            ),
                          ),
                        ),
                        title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          '${food.proteinPer100}g P per 100${food.measurementUnit} · ${food.caloriesPer100.round()} kcal · ${Formatters.currency(food.costPer100)}/100${food.measurementUnit}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (food.proteinPerRupee != null)
                              EfficiencyBadge(efficiency: food.proteinPerRupee),
                            IconButton(
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                                  size: 18, color: isFav ? Colors.red : Colors.grey),
                              onPressed: () {
                                if (food.id != null) foodProvider.toggleFavorite(food.id!);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              onPressed: () => _addFoodToStaged(food),
                            ),
                          ],
                        ),
                        onTap: () => _addFoodToStaged(food),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar: Live Meal Totals + Save Meal Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Meal: ${_totalProtein.toStringAsFixed(1)}g Protein',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.protein),
                        ),
                        Text(
                          '${_totalCalories.round()} kcal (${_totalCarbs.round()}g C, ${_totalFat.round()}g F) · ${Formatters.currency(_totalCost)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _isSaving ? null : _handleSaveMeal,
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            widget.existingEntry != null
                                ? 'Update Entry'
                                : 'Save Meal (${_stagedItems.length})',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceFilterChip(String label, int tabIdx) {
    final isSelected = _activeSourceTab == tabIdx;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppColors.primaryContainer,
      onSelected: (val) {
        if (val) setState(() => _activeSourceTab = tabIdx);
      },
    );
  }
}

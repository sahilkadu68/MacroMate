import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/food_item.dart';
import '../../data/models/meal_entry.dart';
import '../../providers/food_provider.dart';
import '../../providers/meal_provider.dart';
import '../../shared/widgets/metric_badge.dart';

class LogMealScreen extends StatefulWidget {
  final String initialMealType;
  final DateTime entryDate;
  final MealEntry? existingEntry; // If editing an existing meal

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
  FoodItem? _selectedFood;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  double _quantity = 100.0;

  @override
  void initState() {
    super.initState();
    _selectedMealType =
        widget.existingEntry?.mealType ?? widget.initialMealType;

    if (widget.existingEntry != null) {
      _quantity = widget.existingEntry!.quantity;
      _quantityController.text = _quantity.toInt().toString();
    } else {
      _quantityController.text = '100';
    }

    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.existingEntry != null && _selectedFood == null) {
      final foodProvider = Provider.of<FoodProvider>(context, listen: false);
      if (widget.existingEntry!.foodId != null) {
        final matches = foodProvider.allFoods.where(
          (f) => f.id == widget.existingEntry!.foodId,
        );
        if (matches.isNotEmpty) {
          setState(() {
            _selectedFood = matches.first;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    final parsed = double.tryParse(_quantityController.text.trim());
    if (parsed != null && parsed > 0) {
      setState(() {
        _quantity = parsed;
      });
    }
  }

  void _saveEntry() {
    if (_selectedFood == null && widget.existingEntry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a food item first.')),
      );
      return;
    }

    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity greater than zero.'),
        ),
      );
      return;
    }

    final mealProvider = Provider.of<MealProvider>(context, listen: false);

    if (widget.existingEntry != null) {
      // Editing existing entry
      final updated = widget.existingEntry!.copyWith(
        mealType: _selectedMealType,
        quantity: _quantity,
        caloriesSnapshot: _selectedFood != null
            ? _selectedFood!.caloriesForQuantity(_quantity)
            : (_quantity *
                  widget.existingEntry!.caloriesSnapshot /
                  widget.existingEntry!.quantity),
        proteinSnapshot: _selectedFood != null
            ? _selectedFood!.proteinForQuantity(_quantity)
            : (_quantity *
                  widget.existingEntry!.proteinSnapshot /
                  widget.existingEntry!.quantity),
        carbsSnapshot: _selectedFood != null
            ? _selectedFood!.carbsForQuantity(_quantity)
            : (_quantity *
                  widget.existingEntry!.carbsSnapshot /
                  widget.existingEntry!.quantity),
        fatSnapshot: _selectedFood != null
            ? _selectedFood!.fatForQuantity(_quantity)
            : (_quantity *
                  widget.existingEntry!.fatSnapshot /
                  widget.existingEntry!.quantity),
        costSnapshot: _selectedFood != null
            ? _selectedFood!.costForQuantity(_quantity)
            : (_quantity *
                  widget.existingEntry!.costSnapshot /
                  widget.existingEntry!.quantity),
      );
      mealProvider.updateMeal(updated);
    } else {
      // Adding new entry
      final entry = MealEntry.fromFoodItem(
        food: _selectedFood!,
        entryDate: widget.entryDate,
        mealType: _selectedMealType,
        quantity: _quantity,
      );
      mealProvider.addMeal(entry);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foodProvider = Provider.of<FoodProvider>(context);

    final List<FoodItem> searchResults;
    if (_searchController.text.trim().isEmpty) {
      searchResults = foodProvider.allFoods.take(15).toList();
    } else {
      final q = _searchController.text.trim().toLowerCase();
      searchResults = foodProvider.allFoods
          .where(
            (f) =>
                f.name.toLowerCase().contains(q) ||
                f.category.toLowerCase().contains(q),
          )
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingEntry != null ? 'Edit Meal Entry' : 'Log Food',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal Slot Selector Chips
            Text(
              'Meal Slot',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.mealTypes.map((type) {
                final selected = _selectedMealType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  selectedColor: AppColors.primary.withAlpha(40),
                  onSelected: (val) {
                    if (val) setState(() => _selectedMealType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Food Selection Section
            if (widget.existingEntry == null) ...[
              Text(
                'Search Food',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Indian foods (e.g., Soya, Paneer, Egg)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Search results list
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withAlpha(80),
                  ),
                ),
                child: searchResults.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No matching foods found.'),
                        ),
                      )
                    : ListView.separated(
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final food = searchResults[index];
                          final isSelected = _selectedFood?.id == food.id;
                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: AppColors.primary.withAlpha(20),
                            title: Text(
                              food.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${food.caloriesPer100.round()} kcal • ${food.proteinPer100}g P • ${Formatters.currency(food.costPer100)} /100${food.measurementUnit}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: EfficiencyBadge(
                              efficiency: food.proteinPerRupee,
                              compact: true,
                            ),
                            onTap: () {
                              setState(() {
                                _selectedFood = food;
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
            ],

            // Selected Food Card & Live Portion Calculator
            if (_selectedFood != null || widget.existingEntry != null) ...[
              Card(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedFood?.name ??
                                  widget.existingEntry!.foodNameSnapshot,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_selectedFood != null)
                            DietaryBadge(
                              classification:
                                  _selectedFood!.dietaryClassification,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quantity Input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText:
                                    'Quantity (${_selectedFood?.measurementUnit ?? widget.existingEntry!.measurementUnit})',
                                suffixText:
                                    _selectedFood?.measurementUnit ??
                                    widget.existingEntry!.measurementUnit,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Quick Portion Chips
                      Wrap(
                        spacing: 8,
                        children: [50, 100, 150, 200].map((amount) {
                          return ActionChip(
                            label: Text(
                              '$amount${_selectedFood?.measurementUnit ?? "g"}',
                            ),
                            onPressed: () {
                              _quantityController.text = amount.toString();
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Live Nutrition & Cost Summary
                      Text(
                        'Serving Nutrition & Cost Estimate',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLiveStat(
                            'Calories',
                            '${_calculateLiveCalories().round()} kcal',
                            AppColors.calories,
                          ),
                          _buildLiveStat(
                            'Protein',
                            '${_calculateLiveProtein().toStringAsFixed(1)}g',
                            AppColors.protein,
                          ),
                          _buildLiveStat(
                            'Carbs',
                            '${_calculateLiveCarbs().toStringAsFixed(1)}g',
                            AppColors.carbs,
                          ),
                          _buildLiveStat(
                            'Fat',
                            '${_calculateLiveFat().toStringAsFixed(1)}g',
                            AppColors.fat,
                          ),
                          _buildLiveStat(
                            'Cost',
                            Formatters.currency(_calculateLiveCost()),
                            AppColors.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Save Button
            ElevatedButton(
              onPressed: _saveEntry,
              child: Text(
                widget.existingEntry != null
                    ? 'Update Meal Entry'
                    : 'Log Food to Diary',
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateLiveCalories() {
    if (_selectedFood != null) {
      return _selectedFood!.caloriesForQuantity(_quantity);
    }
    if (widget.existingEntry != null && widget.existingEntry!.quantity > 0) {
      return (_quantity * widget.existingEntry!.caloriesSnapshot) /
          widget.existingEntry!.quantity;
    }
    return 0.0;
  }

  double _calculateLiveProtein() {
    if (_selectedFood != null) {
      return _selectedFood!.proteinForQuantity(_quantity);
    }
    if (widget.existingEntry != null && widget.existingEntry!.quantity > 0) {
      return (_quantity * widget.existingEntry!.proteinSnapshot) /
          widget.existingEntry!.quantity;
    }
    return 0.0;
  }

  double _calculateLiveCarbs() {
    if (_selectedFood != null) {
      return _selectedFood!.carbsForQuantity(_quantity);
    }
    if (widget.existingEntry != null && widget.existingEntry!.quantity > 0) {
      return (_quantity * widget.existingEntry!.carbsSnapshot) /
          widget.existingEntry!.quantity;
    }
    return 0.0;
  }

  double _calculateLiveFat() {
    if (_selectedFood != null) {
      return _selectedFood!.fatForQuantity(_quantity);
    }
    if (widget.existingEntry != null && widget.existingEntry!.quantity > 0) {
      return (_quantity * widget.existingEntry!.fatSnapshot) /
          widget.existingEntry!.quantity;
    }
    return 0.0;
  }

  double _calculateLiveCost() {
    if (_selectedFood != null) {
      return _selectedFood!.costForQuantity(_quantity);
    }
    if (widget.existingEntry != null && widget.existingEntry!.quantity > 0) {
      return (_quantity * widget.existingEntry!.costSnapshot) /
          widget.existingEntry!.quantity;
    }
    return 0.0;
  }

  Widget _buildLiveStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

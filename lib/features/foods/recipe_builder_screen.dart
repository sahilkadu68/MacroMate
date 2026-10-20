import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/food_item.dart';
import '../../data/models/recipe.dart';
import '../../providers/food_provider.dart';
import '../../providers/plan_provider.dart';

class RecipeBuilderScreen extends StatefulWidget {
  const RecipeBuilderScreen({super.key});

  @override
  State<RecipeBuilderScreen> createState() => _RecipeBuilderScreenState();
}

class _RecipeBuilderScreenState extends State<RecipeBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _servings = 2;
  final List<RecipeIngredient> _ingredients = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  double get _totalCalories => _ingredients.fold(0.0, (sum, i) => sum + i.calories);
  double get _totalProtein => _ingredients.fold(0.0, (sum, i) => sum + i.protein);
  double get _totalCarbs => _ingredients.fold(0.0, (sum, i) => sum + i.carbs);
  double get _totalFat => _ingredients.fold(0.0, (sum, i) => sum + i.fat);
  double get _totalCost => _ingredients.fold(0.0, (sum, i) => sum + i.cost);

  void _showAddIngredientDialog() {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final foods = foodProvider.allFoods;
    FoodItem? selectedFood = foods.isNotEmpty ? foods.first : null;
    final qtyController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final qty = double.tryParse(qtyController.text.trim()) ?? 0.0;
            final cal = selectedFood?.caloriesForQuantity(qty) ?? 0.0;
            final prot = selectedFood?.proteinForQuantity(qty) ?? 0.0;
            final cost = selectedFood?.costForQuantity(qty) ?? 0.0;

            return AlertDialog(
              title: const Text('Add Ingredient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<FoodItem>(
                    initialValue: selectedFood,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Select Food'),
                    items: foods.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Text(f.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedFood = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity (${selectedFood?.measurementUnit ?? 'g'})',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${prot.toStringAsFixed(1)}g Protein · ${cal.round()} kcal · ${Formatters.currency(cost)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
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
                    if (selectedFood != null && qty > 0) {
                      setState(() {
                        _ingredients.add(
                          RecipeIngredient.fromFood(food: selectedFood!, quantity: qty),
                        );
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient.')),
      );
      return;
    }

    final recipe = Recipe(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      servings: _servings,
      ingredients: _ingredients,
    );

    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    await planProvider.addRecipe(recipe);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.primary, content: Text('Saved recipe "${recipe.name}"!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perServingCal = _servings > 0 ? _totalCalories / _servings : 0.0;
    final perServingProt = _servings > 0 ? _totalProtein / _servings : 0.0;
    final perServingCost = _servings > 0 ? _totalCost / _servings : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Recipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            onPressed: _handleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Recipe Name (e.g., Soya Egg Bhurji)',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter recipe name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Preparation Basis (Optional)',
                ),
              ),
              const SizedBox(height: 14),

              // Servings Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Number of Servings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('$_servings Servings', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              Slider(
                value: _servings.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _servings = val.toInt()),
              ),
              const SizedBox(height: 12),

              // Macro & Cost Preview Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Per Serving Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Total: ${Formatters.currency(_totalCost)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Protein', '${perServingProt.toStringAsFixed(1)}g', AppColors.protein),
                        _buildStat('Carbs', '${(_totalCarbs / (_servings > 0 ? _servings : 1)).toStringAsFixed(1)}g', AppColors.carbs),
                        _buildStat('Fat', '${(_totalFat / (_servings > 0 ? _servings : 1)).toStringAsFixed(1)}g', AppColors.fat),
                        _buildStat('Calories', '${perServingCal.round()} kcal', AppColors.calories),
                        _buildStat('Cost / Serve', Formatters.currency(perServingCost), AppColors.secondary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ingredients Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ingredients (${_ingredients.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Food'),
                    onPressed: _showAddIngredientDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_ingredients.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: const Text('No ingredients added yet. Tap "+ Add Food" to build recipe.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ingredients.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final ing = _ingredients[idx];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(ing.foodName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                        '${ing.quantity.toInt()}${ing.measurementUnit} · ${ing.protein.toStringAsFixed(1)}g P · ${ing.calories.round()} kcal · ${Formatters.currency(ing.cost)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                        onPressed: () => setState(() => _ingredients.removeAt(idx)),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Recipe'),
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}

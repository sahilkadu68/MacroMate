import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators/input_validators.dart';
import '../../data/models/food_item.dart';
import '../../providers/food_provider.dart';
import '../../shared/widgets/metric_badge.dart';

class AddEditFoodScreen extends StatefulWidget {
  final FoodItem? existingFood;

  const AddEditFoodScreen({super.key, this.existingFood});

  @override
  State<AddEditFoodScreen> createState() => _AddEditFoodScreenState();
}

class _AddEditFoodScreenState extends State<AddEditFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _priceController;
  late TextEditingController _basisController;
  late TextEditingController _sourceController;

  late String _selectedCategory;
  late String _selectedDiet;
  late String _selectedUnit;
  late String _selectedPrep;

  @override
  void initState() {
    super.initState();
    final f = widget.existingFood;

    _nameController = TextEditingController(text: f?.name ?? '');
    _caloriesController = TextEditingController(
      text: f != null ? f.caloriesPer100.toString() : '',
    );
    _proteinController = TextEditingController(
      text: f != null ? f.proteinPer100.toString() : '',
    );
    _carbsController = TextEditingController(
      text: f != null ? f.carbsPer100.toString() : '',
    );
    _fatController = TextEditingController(
      text: f != null ? f.fatPer100.toString() : '',
    );
    _priceController = TextEditingController(
      text: f != null ? f.estimatedUnitPrice.toString() : '',
    );
    _basisController = TextEditingController(
      text: f != null ? f.priceQuantityBasis.toInt().toString() : '1000',
    );
    _sourceController = TextEditingController(text: f?.sourceNote ?? '');

    _selectedCategory = f?.category ?? AppConstants.catPlantProtein;
    _selectedDiet = f?.dietaryClassification ?? AppConstants.dietVeg;
    _selectedUnit = f?.measurementUnit ?? AppConstants.unitGrams;
    _selectedPrep = f?.preparationBasis ?? AppConstants.prepCooked;

    _proteinController.addListener(_recalc);
    _priceController.addListener(_recalc);
    _basisController.addListener(_recalc);
  }

  void _recalc() {
    setState(() {});
  }

  @override
  void dispose() {
    _proteinController.removeListener(_recalc);
    _priceController.removeListener(_recalc);
    _basisController.removeListener(_recalc);

    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _priceController.dispose();
    _basisController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  double? _calculateLiveEfficiency() {
    final p = double.tryParse(_proteinController.text.trim()) ?? 0.0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final basis = double.tryParse(_basisController.text.trim()) ?? 100.0;

    if (p <= 0 || price <= 0 || basis <= 0) return null;
    final cost100 = (price / basis) * 100.0;
    if (cost100 <= 0) return null;
    return p / cost100;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final food = FoodItem(
      id: widget.existingFood?.id,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      dietaryClassification: _selectedDiet,
      caloriesPer100: double.parse(_caloriesController.text.trim()),
      proteinPer100: double.parse(_proteinController.text.trim()),
      carbsPer100: double.parse(_carbsController.text.trim()),
      fatPer100: double.parse(_fatController.text.trim()),
      measurementUnit: _selectedUnit,
      preparationBasis: _selectedPrep,
      estimatedUnitPrice: double.parse(_priceController.text.trim()),
      priceQuantityBasis: double.parse(_basisController.text.trim()),
      sourceNote: _sourceController.text.trim().isNotEmpty
          ? _sourceController.text.trim()
          : 'User added custom food',
      isCustom: true,
    );

    final provider = Provider.of<FoodProvider>(context, listen: false);

    if (widget.existingFood != null) {
      await provider.updateFood(food);
    } else {
      await provider.addCustomFood(food);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eff = _calculateLiveEfficiency();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingFood != null ? 'Edit Food Item' : 'Add Custom Food',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            onPressed: _submit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Food Name *',
                  hintText: 'e.g. Besan Chilla, Soya Pulao',
                ),
                validator: (val) =>
                    InputValidators.requiredField(val, 'Food name'),
              ),
              const SizedBox(height: 14),

              // Category & Dietary classification
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: AppConstants.foodCategories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDiet,
                      decoration: const InputDecoration(labelText: 'Diet Type'),
                      items: AppConstants.dietaryPreferences.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(d, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDiet = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Unit & Preparation basis
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [
                        DropdownMenuItem(
                          value: AppConstants.unitGrams,
                          child: Text('Grams (g)'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.unitMl,
                          child: Text('Millilitres (ml)'),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.unitPiece,
                          child: Text('Piece (pc)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUnit = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPrep,
                      decoration: const InputDecoration(
                        labelText: 'Preparation',
                      ),
                      items: AppConstants.prepBases.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPrep = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Nutritional Values (per 100$_selectedUnit)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Calories & Protein
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Calories (kcal) *',
                        suffixText: 'kcal',
                      ),
                      validator: (val) =>
                          InputValidators.realisticCalories(val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Protein (g) *',
                        suffixText: 'g',
                      ),
                      validator: (val) =>
                          InputValidators.realisticMacro(val, 'Protein'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Carbs & Fat
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Carbohydrates (g) *',
                        suffixText: 'g',
                      ),
                      validator: (val) =>
                          InputValidators.realisticMacro(val, 'Carbohydrates'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Fat (g) *',
                        suffixText: 'g',
                      ),
                      validator: (val) =>
                          InputValidators.realisticMacro(val, 'Fat'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Price & Rupee Basis',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Price & Quantity Basis
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price (₹) *',
                        prefixText: '₹ ',
                      ),
                      validator: (val) => InputValidators.positiveNumber(
                        val,
                        'Price',
                        allowZero: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _basisController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'For Quantity *',
                        suffixText: _selectedUnit,
                      ),
                      validator: (val) => InputValidators.positiveNumber(
                        val,
                        'Quantity basis',
                        allowZero: false,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live Protein Efficiency Indicator Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                    80,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calculated Protein Efficiency:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    EfficiencyBadge(efficiency: eff),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Source note
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source / Vendor Note (Optional)',
                  hintText: 'e.g. Local Kirana Store / Amul Parlour',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(
                    widget.existingFood != null
                        ? 'Update Food Item'
                        : 'Add Food to Catalogue',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

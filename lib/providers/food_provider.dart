import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../data/models/food_item.dart';
import '../data/repositories/food_repository.dart';

enum FoodSortOption {
  proteinPerRupee,
  protein,
  caloriesAsc,
  caloriesDesc,
  costAsc,
  name,
}

class FoodProvider with ChangeNotifier {
  final FoodRepository _repository;

  List<FoodItem> _allFoods = [];
  List<FoodItem> _filteredFoods = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedDietaryPreference;
  FoodSortOption _sortOption = FoodSortOption.proteinPerRupee;

  FoodProvider({FoodRepository? repository})
    : _repository = repository ?? FoodRepository() {
    loadFoods();
  }

  List<FoodItem> get foods => _filteredFoods;
  List<FoodItem> get allFoods => _allFoods;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedDietaryPreference => _selectedDietaryPreference;
  FoodSortOption get sortOption => _sortOption;

  Future<void> loadFoods() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allFoods = await _repository.getAllFoods();
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to load food catalogue: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setDietaryFilter(String? dietaryPreference) {
    _selectedDietaryPreference = dietaryPreference;
    _applyFilters();
    notifyListeners();
  }

  void setSortOption(FoodSortOption option) {
    _sortOption = option;
    _applyFilters();
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedDietaryPreference = null;
    _sortOption = FoodSortOption.proteinPerRupee;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<FoodItem> results = List.from(_allFoods);

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      results = results.where((f) {
        return f.name.toLowerCase().contains(q) ||
            f.category.toLowerCase().contains(q) ||
            f.preparationBasis.toLowerCase().contains(q);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      results = results.where((f) => f.category == _selectedCategory).toList();
    }

    // Dietary classification filter
    if (_selectedDietaryPreference != null &&
        _selectedDietaryPreference!.isNotEmpty) {
      results = results.where((f) {
        if (_selectedDietaryPreference == AppConstants.dietVeg) {
          return f.dietaryClassification == AppConstants.dietVeg;
        } else if (_selectedDietaryPreference == AppConstants.dietEgg) {
          return f.dietaryClassification == AppConstants.dietEgg;
        } else if (_selectedDietaryPreference == AppConstants.dietNonVeg) {
          return f.dietaryClassification == AppConstants.dietNonVeg;
        }
        return true;
      }).toList();
    }

    // Sorting
    switch (_sortOption) {
      case FoodSortOption.proteinPerRupee:
        results.sort((a, b) {
          final effA = a.proteinPerRupee ?? -1.0;
          final effB = b.proteinPerRupee ?? -1.0;
          return effB.compareTo(effA);
        });
        break;
      case FoodSortOption.protein:
        results.sort((a, b) => b.proteinPer100.compareTo(a.proteinPer100));
        break;
      case FoodSortOption.caloriesAsc:
        results.sort((a, b) => a.caloriesPer100.compareTo(b.caloriesPer100));
        break;
      case FoodSortOption.caloriesDesc:
        results.sort((a, b) => b.caloriesPer100.compareTo(a.caloriesPer100));
        break;
      case FoodSortOption.costAsc:
        results.sort((a, b) => a.costPer100.compareTo(b.costPer100));
        break;
      case FoodSortOption.name:
        results.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    _filteredFoods = results;
  }

  Future<void> addCustomFood(FoodItem food) async {
    try {
      final id = await _repository.addFood(food.copyWith(isCustom: true));
      _allFoods.add(food.copyWith(id: id, isCustom: true));
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add custom food: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateFood(FoodItem food) async {
    try {
      await _repository.updateFood(food);
      final idx = _allFoods.indexWhere((f) => f.id == food.id);
      if (idx != -1) {
        _allFoods[idx] = food;
      }
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update food: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteFood(int id) async {
    try {
      await _repository.deleteFood(id);
      _allFoods.removeWhere((f) => f.id == id);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete food: $e';
      notifyListeners();
      rethrow;
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}

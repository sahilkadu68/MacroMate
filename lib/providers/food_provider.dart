import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../data/models/food_item.dart';
import '../data/repositories/food_repository.dart';
import '../data/repositories/plan_repository.dart';
import '../services/dietary_service.dart';

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
  final PlanRepository _planRepository;

  List<FoodItem> _allFoods = [];
  List<FoodItem> _filteredFoods = [];
  Set<int> _favoriteFoodIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCuisine;
  String _selectedCatalogueFilter = DietaryService.filterAll;
  bool _showFavoritesOnly = false;
  FoodSortOption _sortOption = FoodSortOption.proteinPerRupee;

  FoodProvider({FoodRepository? repository, PlanRepository? planRepository})
    : _repository = repository ?? FoodRepository(),
      _planRepository = planRepository ?? PlanRepository() {
    loadFoods();
  }

  List<FoodItem> get foods => _filteredFoods;
  List<FoodItem> get allFoods => _allFoods;
  Set<int> get favoriteFoodIds => _favoriteFoodIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedCuisine => _selectedCuisine;
  List<String> get cuisines =>
      _allFoods
          .map((food) => food.cuisine)
          .where((cuisine) => cuisine.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  String get selectedCatalogueFilter => _selectedCatalogueFilter;
  String? get selectedDietaryPreference =>
      _selectedCatalogueFilter == DietaryService.filterVeg ||
          _selectedCatalogueFilter == 'Veg Only'
      ? AppConstants.dietVeg
      : _selectedCatalogueFilter == DietaryService.filterEgg ||
            _selectedCatalogueFilter == 'Eggs Only'
      ? AppConstants.dietEgg
      : _selectedCatalogueFilter == DietaryService.filterNonVeg ||
            _selectedCatalogueFilter == 'Meat & Fish'
      ? AppConstants.dietNonVeg
      : null;
  bool get showFavoritesOnly => _showFavoritesOnly;
  FoodSortOption get sortOption => _sortOption;

  bool isFavorite(int? foodId) =>
      foodId != null && _favoriteFoodIds.contains(foodId);

  Future<void> loadFoods() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allFoods = await _repository.getAllFoods();
      _favoriteFoodIds = await _planRepository.getFavoriteFoodIds();
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

  void setCuisineFilter(String? cuisine) {
    _selectedCuisine = cuisine;
    _applyFilters();
    notifyListeners();
  }

  void setCatalogueFilter(String filter) {
    _selectedCatalogueFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setDietaryFilter(String? dietaryPreference) {
    if (dietaryPreference == AppConstants.dietVeg ||
        dietaryPreference == 'Veg') {
      _selectedCatalogueFilter = DietaryService.filterVeg;
    } else if (dietaryPreference == AppConstants.dietEgg ||
        dietaryPreference == 'Egg') {
      _selectedCatalogueFilter = DietaryService.filterEgg;
    } else if (dietaryPreference == AppConstants.dietNonVeg ||
        dietaryPreference == 'Non-Veg') {
      _selectedCatalogueFilter = DietaryService.filterNonVeg;
    } else {
      _selectedCatalogueFilter = DietaryService.filterAll;
    }
    _applyFilters();
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    _applyFilters();
    notifyListeners();
  }

  Future<void> toggleFavorite(int foodId) async {
    try {
      final isNowFav = await _planRepository.toggleFavoriteFood(foodId);
      if (isNowFav) {
        _favoriteFoodIds.add(foodId);
      } else {
        _favoriteFoodIds.remove(foodId);
      }
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update favorite: $e';
      notifyListeners();
    }
  }

  void setSortOption(FoodSortOption option) {
    _sortOption = option;
    _applyFilters();
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedCuisine = null;
    _selectedCatalogueFilter = DietaryService.filterAll;
    _showFavoritesOnly = false;
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
            f.preparationBasis.toLowerCase().contains(q) ||
            f.cuisine.toLowerCase().contains(q) ||
            f.ingredients.toLowerCase().contains(q);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      results = results.where((f) => f.category == _selectedCategory).toList();
    }
    if (_selectedCuisine != null) {
      results = results.where((f) => f.cuisine == _selectedCuisine).toList();
    }

    // Dietary classification / tag filter
    results = DietaryService.applyCatalogueFilter(
      foods: results,
      selectedFilter: _selectedCatalogueFilter,
    );

    // Favorites only filter
    if (_showFavoritesOnly) {
      results = results
          .where((f) => f.id != null && _favoriteFoodIds.contains(f.id!))
          .toList();
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

  Future<void> updateFoodPrice(int foodId, double newPrice) async {
    if (!newPrice.isFinite || newPrice <= 0) {
      throw ArgumentError.value(
        newPrice,
        'newPrice',
        'Must be finite and positive.',
      );
    }
    try {
      final idx = _allFoods.indexWhere((f) => f.id == foodId);
      if (idx != -1) {
        final updated = _allFoods[idx].copyWith(
          estimatedUnitPrice: newPrice,
          packagePrice: newPrice,
          priceSource: 'User-entered local price',
          priceConfidence: 'User entered; not independently verified',
          isUserPrice: true,
          isPriceEstimate: true,
          lastPriceUpdate: DateTime.now(),
          sourceNote: 'This price was entered by the user for this device.',
        );
        await _repository.updateFood(updated);
        _allFoods[idx] = updated;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update food price: $e';
      notifyListeners();
      rethrow;
    }
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
      _favoriteFoodIds.remove(id);
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

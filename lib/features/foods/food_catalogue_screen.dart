import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/food_provider.dart';
import '../../services/dietary_service.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../providers/plan_provider.dart';
import 'add_edit_food_screen.dart';
import 'food_detail_sheet.dart';
import 'recipe_builder_screen.dart';
import 'recipe_detail_sheet.dart';
import 'shopping_list_screen.dart';
import 'widgets/food_list_tile.dart';

class FoodCatalogueScreen extends StatefulWidget {
  const FoodCatalogueScreen({super.key});

  @override
  State<FoodCatalogueScreen> createState() => _FoodCatalogueScreenState();
}

class _FoodCatalogueScreenState extends State<FoodCatalogueScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortSheet(BuildContext context, FoodProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Sort Foods By',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bolt, color: AppColors.secondary),
                  title: const Text('Highest Protein per Rupee (Best Value)'),
                  trailing: provider.sortOption == FoodSortOption.proteinPerRupee
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    provider.setSortOption(FoodSortOption.proteinPerRupee);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.fitness_center, color: AppColors.protein),
                  title: const Text('Highest Protein Content'),
                  trailing: provider.sortOption == FoodSortOption.protein
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    provider.setSortOption(FoodSortOption.protein);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.currency_rupee, color: AppColors.secondary),
                  title: const Text('Lowest Cost per 100g'),
                  trailing: provider.sortOption == FoodSortOption.costAsc
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    provider.setSortOption(FoodSortOption.costAsc);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_fire_department, color: AppColors.calories),
                  title: const Text('Lowest Calories'),
                  trailing: provider.sortOption == FoodSortOption.caloriesAsc
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    provider.setSortOption(FoodSortOption.caloriesAsc);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sort_by_alpha),
                  title: const Text('Food Name (A-Z)'),
                  trailing: provider.sortOption == FoodSortOption.name
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    provider.setSortOption(FoodSortOption.name);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategorySheet(BuildContext context, FoodProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Filter by Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ListTile(
                  title: const Text('All Categories'),
                  trailing: provider.selectedCategory == null
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    provider.setCategoryFilter(null);
                    Navigator.pop(ctx);
                  },
                ),
                ...AppConstants.foodCategories.map((cat) {
                  return ListTile(
                    title: Text(cat),
                    trailing: provider.selectedCategory == cat
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      provider.setCategoryFilter(cat);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecipesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final planProvider = Provider.of<PlanProvider>(context);
        final recipes = planProvider.recipes;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Recipes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Recipe', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RecipeBuilderScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (recipes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No recipes created yet. Tap "+ New Recipe" to build one!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: recipes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, idx) {
                        final r = recipes[idx];
                        return ListTile(
                          title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${r.servings} serves · ${r.perServingProtein.toStringAsFixed(1)}g P/serve · ${r.perServingCalories.round()} kcal · ${Formatters.currency(r.perServingCost)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                            Navigator.pop(ctx);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (_) => RecipeDetailSheet(recipe: r),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indian Food Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Recipes',
            onPressed: () => _showRecipesSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Grocery List',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Foods',
            onPressed: () => _showSortSheet(context, foodProvider),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Categories',
            onPressed: () => _showCategorySheet(context, foodProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search foods (e.g. Soya, Paneer, Egg, Rice)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          foodProvider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (q) => foodProvider.setSearchQuery(q),
            ),
          ),

          // Dietary Filter Row with Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Favourites Filter Chip
                FilterChip(
                  avatar: Icon(
                    foodProvider.showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                    size: 14,
                    color: Colors.red,
                  ),
                  label: const Text('Favourites'),
                  selected: foodProvider.showFavoritesOnly,
                  onSelected: (_) => foodProvider.toggleFavoritesOnly(),
                ),
                const SizedBox(width: 8),

                // Catalogue Filter Options
                ...DietaryService.catalogueFilterOptions.map((opt) {
                  final isSelected = foodProvider.selectedCatalogueFilter == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(opt),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          foodProvider.setCatalogueFilter(opt);
                        } else {
                          foodProvider.setCatalogueFilter(DietaryService.filterAll);
                        }
                      },
                    ),
                  );
                }),

                if (foodProvider.selectedCategory != null) ...[
                  Chip(
                    label: Text(foodProvider.selectedCategory!),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => foodProvider.setCategoryFilter(null),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Catalogue list
          Expanded(
            child: foodProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : foodProvider.foods.isEmpty
                ? EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No Foods Found',
                    message:
                        'No foods match your search or filter criteria. Try clearing filters or adding a custom food.',
                    actionLabel: 'Reset Filters',
                    onAction: () {
                      _searchController.clear();
                      foodProvider.resetFilters();
                    },
                  )
                : ListView.separated(
                    itemCount: foodProvider.foods.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 48),
                    itemBuilder: (context, index) {
                      final food = foodProvider.foods[index];
                      return FoodListTile(
                        food: food,
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) => FoodDetailSheet(
                              food: food,
                              onDeleted: () {
                                if (food.id != null) {
                                  foodProvider.deleteFood(food.id!);
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Custom Food',
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddEditFoodScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

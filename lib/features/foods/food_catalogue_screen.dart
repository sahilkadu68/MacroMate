import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/food_provider.dart';
import '../../shared/widgets/empty_state_view.dart';
import 'add_edit_food_screen.dart';
import 'food_detail_sheet.dart';
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
                  trailing:
                      provider.sortOption == FoodSortOption.proteinPerRupee
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    provider.setSortOption(FoodSortOption.proteinPerRupee);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.fitness_center,
                    color: AppColors.protein,
                  ),
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
                  leading: const Icon(
                    Icons.currency_rupee,
                    color: AppColors.secondary,
                  ),
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
                  leading: const Icon(
                    Icons.local_fire_department,
                    color: AppColors.calories,
                  ),
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
                  title: const Text('Alphabetical Name'),
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

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indian Food Catalogue'),
        actions: [
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

          // Dietary Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Diets'),
                  selected: foodProvider.selectedDietaryPreference == null,
                  onSelected: (val) {
                    if (val) foodProvider.setDietaryFilter(null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(
                    Icons.eco,
                    size: 14,
                    color: AppColors.vegGreen,
                  ),
                  label: const Text('Veg Only'),
                  selected:
                      foodProvider.selectedDietaryPreference ==
                      AppConstants.dietVeg,
                  onSelected: (val) {
                    foodProvider.setDietaryFilter(
                      val ? AppConstants.dietVeg : null,
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(
                    Icons.egg_outlined,
                    size: 14,
                    color: AppColors.eggYellow,
                  ),
                  label: const Text('Eggetarian'),
                  selected:
                      foodProvider.selectedDietaryPreference ==
                      AppConstants.dietEgg,
                  onSelected: (val) {
                    foodProvider.setDietaryFilter(
                      val ? AppConstants.dietEgg : null,
                    );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(
                    Icons.restaurant,
                    size: 14,
                    color: AppColors.nonVegRed,
                  ),
                  label: const Text('Non-Veg'),
                  selected:
                      foodProvider.selectedDietaryPreference ==
                      AppConstants.dietNonVeg,
                  onSelected: (val) {
                    foodProvider.setDietaryFilter(
                      val ? AppConstants.dietNonVeg : null,
                    );
                  },
                ),
                if (foodProvider.selectedCategory != null) ...[
                  const SizedBox(width: 8),
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

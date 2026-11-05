import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/profile_provider.dart';
import 'daily_meal_planner_screen.dart';
import '../foods/recipe_builder_screen.dart';
import '../foods/shopping_list_screen.dart';
import '../navigation/main_scaffold.dart';
import '../protein_finder/protein_finder_screen.dart';

class PlanHubScreen extends StatelessWidget {
  const PlanHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Make a practical choice for your day.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Suggestions use your saved preferences and prices. Seed prices are estimates; update them to match your local shop.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your daily food budget'),
                        const SizedBox(height: 4),
                        Text(
                          '₹${profile.dailyBudget.toStringAsFixed(0)} · ${profile.dietaryPreference}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit budget and preferences',
                    icon: const Icon(Icons.tune),
                    onPressed: () => MainScaffold.of(context)?.switchTab(5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PlanAction(
            icon: Icons.calendar_month_outlined,
            title: "Plan and adapt today",
            subtitle:
                'Build meals around your budget and goals, then log or swap them.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DailyMealPlannerScreen(),
              ),
            ),
          ),
          _PlanAction(
            icon: Icons.savings_outlined,
            title: 'Find affordable food options',
            subtitle: 'Compare combinations against your remaining budget.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProteinFinderScreen(),
              ),
            ),
          ),
          _PlanAction(
            icon: Icons.menu_book_outlined,
            title: 'Build a recipe',
            subtitle: 'Combine foods and review estimated nutrition and cost.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecipeBuilderScreen(),
              ),
            ),
          ),
          _PlanAction(
            icon: Icons.shopping_cart_outlined,
            title: 'Open shopping list',
            subtitle: 'Review and update items you want to buy.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ShoppingListScreen(),
              ),
            ),
          ),
          _PlanAction(
            icon: Icons.search,
            title: 'Browse foods and prices',
            subtitle: 'Search the catalogue or correct a local price.',
            onTap: () => MainScaffold.of(context)?.switchTab(1),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nutrition targets are estimates for general wellness. Review them in Profile and adjust them to suit your needs.',
            style: TextStyle(color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}

class _PlanAction extends StatelessWidget {
  const _PlanAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

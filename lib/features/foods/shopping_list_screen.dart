import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/plan_provider.dart';
import '../../providers/food_provider.dart';
import '../../data/models/shopping_item.dart';
import '../../services/shopping_cost_service.dart';
import '../../shared/widgets/empty_state_view.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  Future<void> _editQuantity(BuildContext context, ShoppingItem item) async {
    final controller = TextEditingController(text: item.quantity.toString());
    final provider = context.read<PlanProvider>();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String? error;
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, update) => AlertDialog(
            title: Text('Quantity in ${item.unit}'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: item.name,
                errorText: error,
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final quantity = double.tryParse(controller.text);
                        if (quantity == null ||
                            !quantity.isFinite ||
                            quantity <= 0) {
                          update(() => error = 'Enter a positive quantity.');
                          return;
                        }
                        update(() => saving = true);
                        try {
                          await provider.updateShoppingQuantity(item, quantity);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (_) {
                          if (ctx.mounted) {
                            update(() {
                              saving = false;
                              error = 'Could not save. Try again.';
                            });
                          }
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '500');
    String unit = 'g';
    String? error;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Grocery Item',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Item Name (e.g. Soya Chunks, Eggs)',
                    ),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: unit,
                        items: const [
                          DropdownMenuItem(value: 'g', child: Text('g')),
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'ml', child: Text('ml')),
                          DropdownMenuItem(value: 'L', child: Text('L')),
                          DropdownMenuItem(
                            value: 'piece',
                            child: Text('piece'),
                          ),
                          DropdownMenuItem(value: 'pack', child: Text('pack')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => unit = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final qty = double.tryParse(
                            qtyController.text.trim(),
                          );
                          if (name.isEmpty ||
                              qty == null ||
                              !qty.isFinite ||
                              qty <= 0) {
                            setDialogState(
                              () =>
                                  error = 'Enter a name and positive quantity.',
                            );
                            return;
                          }
                          setDialogState(() => saving = true);
                          try {
                            await Provider.of<PlanProvider>(
                              context,
                              listen: false,
                            ).addShoppingItem(name, qty, unit);
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (_) {
                            if (ctx.mounted) {
                              setDialogState(() {
                                saving = false;
                                error = 'Could not save. Try again.';
                              });
                            }
                          }
                        },
                  child: const Text('Add Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = Provider.of<PlanProvider>(context);
    final items = planProvider.shoppingItems;
    final purchasedCount = items.where((i) => i.isPurchased).length;
    final foods = context.watch<FoodProvider>().allFoods;
    final outstanding = items.where((item) => !item.isPurchased);
    final costs = outstanding
        .map((item) => ShoppingCostService.estimate(item, foods))
        .toList();
    final knownTotal = costs.whereType<double>().fold<double>(
      0,
      (sum, cost) => sum + cost,
    );
    final unknown = costs.where((cost) => cost == null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Grocery List'),
        actions: [
          if (purchasedCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.cleaning_services, size: 16),
              label: const Text(
                'Clear Checked',
                style: TextStyle(fontSize: 12),
              ),
              onPressed: () => planProvider.clearPurchasedItems(),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyStateView(
              icon: Icons.shopping_basket_outlined,
              title: 'Shopping List Empty',
              message:
                  'Add items manually or tap "Add to List" from any Recipe to plan your hostel grocery shopping.',
              actionLabel: 'Add First Item',
              onAction: () => _showAddItemDialog(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final item = items[idx];
                final cost = ShoppingCostService.estimate(item, foods);
                return CheckboxListTile(
                  dense: true,
                  activeColor: AppColors.primary,
                  value: item.isPurchased,
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: item.isPurchased
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isPurchased ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(
                    '${item.quantity} ${item.unit} · ${cost != null ? '₹${cost.toStringAsFixed(2)} estimate' : 'Price unavailable'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isPurchased ? Colors.grey : AppColors.primary,
                    ),
                  ),
                  secondary: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit quantity',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editQuantity(context, item),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          if (item.id != null) {
                            planProvider.deleteShoppingItem(item.id!);
                          }
                        },
                      ),
                    ],
                  ),
                  onChanged: (_) => planProvider.toggleShoppingItem(item),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Grocery Item',
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Unchecked items: ₹${knownTotal.toStringAsFixed(2)} estimated${unknown > 0 ? ' + $unknown unpriced items' : ''}\nBased on your local catalogue prices; final shop totals may differ.',
          ),
        ),
      ),
    );
  }
}

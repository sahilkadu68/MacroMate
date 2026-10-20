import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/plan_provider.dart';
import '../../shared/widgets/empty_state_view.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '500');
    String unit = 'g';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Grocery Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Item Name (e.g. Soya Chunks, Eggs)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Quantity'),
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
                          DropdownMenuItem(value: 'piece', child: Text('piece')),
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
                  onPressed: () {
                    final name = nameController.text.trim();
                    final qty = double.tryParse(qtyController.text.trim()) ?? 1.0;
                    if (name.isNotEmpty) {
                      Provider.of<PlanProvider>(context, listen: false).addShoppingItem(name, qty, unit);
                      Navigator.pop(ctx);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Grocery List'),
        actions: [
          if (purchasedCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.cleaning_services, size: 16),
              label: const Text('Clear Checked', style: TextStyle(fontSize: 12)),
              onPressed: () => planProvider.clearPurchasedItems(),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyStateView(
              icon: Icons.shopping_basket_outlined,
              title: 'Shopping List Empty',
              message: 'Add items manually or tap "Add to List" from any Recipe to plan your hostel grocery shopping.',
              actionLabel: 'Add First Item',
              onAction: () => _showAddItemDialog(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final item = items[idx];
                return CheckboxListTile(
                  dense: true,
                  activeColor: AppColors.primary,
                  value: item.isPurchased,
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                      color: item.isPurchased ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(
                    '${item.quantity.toInt()} ${item.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isPurchased ? Colors.grey : AppColors.primary,
                    ),
                  ),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                    onPressed: () {
                      if (item.id != null) planProvider.deleteShoppingItem(item.id!);
                    },
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
    );
  }
}

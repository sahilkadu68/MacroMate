import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/profile_provider.dart';
import '../../providers/tracking_provider.dart';
import '../../services/analytics_service.dart';
import '../../shared/widgets/empty_state_view.dart';
import 'widgets/chart_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  int _selectedDays = 7;
  bool _isLoading = true;
  List<DailyAnalyticsPoint> _points = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _analyticsService.getNutritionHistory(_selectedDays);
      if (!mounted) return;
      setState(() {
        _points = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = Provider.of<ProfileProvider>(context).profile;
    final tracking = Provider.of<TrackingProvider>(context);

    // Summary calculations
    double avgCalories = 0.0;
    double avgProtein = 0.0;
    double avgCost = 0.0;
    int daysWithLogs = 0;
    int targetHitDays = 0;

    for (final p in _points) {
      if (p.calories > 0 || p.protein > 0 || p.cost > 0) {
        daysWithLogs++;
        avgCalories += p.calories;
        avgProtein += p.protein;
        avgCost += p.cost;
        if (p.protein >= profile.proteinTarget * 0.9) {
          targetHitDays++;
        }
      }
    }

    if (daysWithLogs > 0) {
      avgCalories /= daysWithLogs;
      avgProtein /= daysWithLogs;
      avgCost /= daysWithLogs;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Progress & Analytics')),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Timeframe',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 7, label: Text('7 Days')),
                      ButtonSegment(value: 30, label: Text('30 Days')),
                    ],
                    selected: {_selectedDays},
                    onSelectionChanged: (val) {
                      setState(() {
                        _selectedDays = val.first;
                      });
                      _loadHistory();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Stats Card
              Card(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Period Averages ($_selectedDays Days)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAvgStat(
                            'Avg Protein',
                            '${avgProtein.toStringAsFixed(1)}g /day',
                            AppColors.protein,
                          ),
                          _buildAvgStat(
                            'Avg Calories',
                            '${avgCalories.round()} kcal',
                            AppColors.calories,
                          ),
                          _buildAvgStat(
                            'Avg Spend',
                            Formatters.currency(avgCost),
                            AppColors.secondary,
                          ),
                          _buildAvgStat(
                            'Target Hit',
                            '$targetHitDays / $daysWithLogs days',
                            AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (daysWithLogs == 0)
                EmptyStateView(
                  icon: Icons.analytics_outlined,
                  title: 'No Recorded Data Yet',
                  message:
                      'Start logging your daily meals to see your calories, protein, and expenditure trends over time.',
                )
              else ...[
                // Daily Calories Chart
                NutritionBarChart(
                  title: 'Calories Consumed',
                  unit: 'kcal',
                  barColor: AppColors.calories,
                  target: profile.calorieTarget,
                  points: _points,
                  valueSelector: (p) => p.calories,
                ),
                const SizedBox(height: 14),

                // Daily Protein Chart
                NutritionBarChart(
                  title: 'Protein Intake',
                  unit: 'g',
                  barColor: AppColors.protein,
                  target: profile.proteinTarget,
                  points: _points,
                  valueSelector: (p) => p.protein,
                ),
                const SizedBox(height: 14),

                // Food Expenditure Chart
                CostLineChart(
                  points: _points,
                  dailyBudget: profile.dailyBudget,
                ),
                const SizedBox(height: 14),
              ],

              // Weight Progress Section
              _buildWeightSection(context, tracking),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightSection(BuildContext context, TrackingProvider tracking) {
    final theme = Theme.of(context);
    final logs = tracking.weightLogs;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monitor_weight_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Weight Progress',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddWeightDialog(context, tracking),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Log Weight',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No weight logs recorded yet. Track your bodyweight to monitor trends over time.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withAlpha(140),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest: ${Formatters.weight(logs.last.weight)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (logs.length > 1)
                        Builder(
                          builder: (context) {
                            final delta = logs.last.weight - logs.first.weight;
                            return Text(
                              '${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)} kg overall',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: delta.abs() > 0
                                    ? (delta > 0 ? Colors.blue : Colors.orange)
                                    : Colors.grey,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Recent weight entries list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length > 5 ? 5 : logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = logs.reversed.toList()[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.measurementDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  150,
                                ),
                              ),
                            ),
                            Text(
                              Formatters.weight(item.weight),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, TrackingProvider tracking) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Body Weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            suffixText: 'kg',
            hintText: 'e.g. 68.5',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(controller.text.trim());
              if (w != null && w > 20 && w < 300) {
                tracking.addWeight(w);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvgStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

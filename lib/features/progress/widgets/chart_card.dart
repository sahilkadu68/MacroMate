import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/analytics_service.dart';

class NutritionBarChart extends StatelessWidget {
  final String title;
  final String unit;
  final Color barColor;
  final double target;
  final List<DailyAnalyticsPoint> points;
  final double Function(DailyAnalyticsPoint) valueSelector;

  const NutritionBarChart({
    super.key,
    required this.title,
    required this.unit,
    required this.barColor,
    required this.target,
    required this.points,
    required this.valueSelector,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = points.fold(
      target,
      (maxV, p) => max(maxV, valueSelector(p)),
    );
    final maxY = (maxVal * 1.25).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Target: ${target.round()} $unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY > 0 ? maxY : 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 4 : 25,
                    getDrawingHorizontalLine: (val) {
                      return FlLine(
                        color: theme.colorScheme.outline.withAlpha(40),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const SizedBox.shrink();
                          return Text(
                            val.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < points.length) {
                            // Show alternate days if more than 10 points
                            if (points.length > 10 && idx % 4 != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                Formatters.formatDayOfWeek(points[idx].date),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: points.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final pt = entry.value;
                    final val = valueSelector(pt);
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          color: val >= target ? AppColors.primary : barColor,
                          width: points.length > 14 ? 6 : 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: target,
                        color: Colors.red.withAlpha(150),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          labelResolver: (_) => 'Target',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CostLineChart extends StatelessWidget {
  final List<DailyAnalyticsPoint> points;
  final double dailyBudget;

  const CostLineChart({
    super.key,
    required this.points,
    required this.dailyBudget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCost = points.fold(dailyBudget, (maxV, p) => max(maxV, p.cost));
    final maxY = (maxCost * 1.3).ceilToDouble();

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.cost);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Food Expenditure (₹)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Budget: ${Formatters.currency(dailyBudget)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  maxY: maxY > 0 ? maxY : 200,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outline.withAlpha(40),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const SizedBox.shrink();
                          return Text(
                            '₹${val.toInt()}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < points.length) {
                            if (points.length > 10 && idx % 4 != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                Formatters.formatDayOfWeek(points[idx].date),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: dailyBudget,
                        color: AppColors.secondary.withAlpha(180),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                          labelResolver: (_) => 'Budget',
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.secondary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.secondary.withAlpha(25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

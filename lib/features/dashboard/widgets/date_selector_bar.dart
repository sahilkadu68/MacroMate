import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';

class DateSelectorBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DateSelectorBar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Day',
            onPressed: () {
              onDateChanged(selectedDate.subtract(const Duration(days: 1)));
            },
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                onDateChanged(picked);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.formatDate(selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (!isToday) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Past',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Day',
            onPressed: () {
              onDateChanged(selectedDate.add(const Duration(days: 1)));
            },
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

import 'package:flutter/material.dart';
import '../models/period_models.dart';
import 'prediction_panel.dart';

class DailyDetails extends StatelessWidget {
  const DailyDetails({
    super.key,
    required this.date,
    required this.marked,
    required this.onMarkedChanged,
    required this.lastRange,
    required this.avgCycleDays,
    required this.avgPeriodDays,
    required this.nextStart,
    required this.nextEnd,
  });

  final DateTime? date;
  final bool marked;
  final ValueChanged<bool> onMarkedChanged;
  final PeriodRange? lastRange;
  final int avgCycleDays;
  final int avgPeriodDays;
  final DateTime? nextStart;
  final DateTime? nextEnd;

  @override
  Widget build(BuildContext context) {
    final d = date ?? DateTime.now();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${d.year}-${_two(d.month)}-${_two(d.day)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bleeding day'),
            subtitle: const Text('Long-press a date to toggle, or use this switch.'),
            value: marked,
            onChanged: onMarkedChanged,
          ),
          const SizedBox(height: 12),
          PredictionPanel(
            lastRange: lastRange,
            avgCycleDays: avgCycleDays,
            avgPeriodDays: avgPeriodDays,
            nextStart: nextStart,
            nextEnd: nextEnd,
          ),
        ],
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
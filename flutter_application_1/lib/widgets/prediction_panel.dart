import 'package:flutter/material.dart';
import '../models/period_models.dart';
import 'info_chip.dart';

class PredictionPanel extends StatelessWidget {
  const PredictionPanel({
    super.key,
    required this.lastRange,
    required this.avgCycleDays,
    required this.avgPeriodDays,
    required this.nextStart,
    required this.nextEnd,
  });

  final PeriodRange? lastRange;
  final int avgCycleDays;
  final int avgPeriodDays;
  final DateTime? nextStart;
  final DateTime? nextEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Cycle insights',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lastRange == null) ...[
              Text('No bleeding days marked yet.', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                'Mark bleeding days on the calendar to see your last period and predictions.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ] else ...[
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  InfoChip(
                    icon: Icons.event,
                    label: 'Last period',
                    value: '${_fmt(lastRange!.start)} – ${_fmt(lastRange!.end)} (${lastRange!.lengthDays}d)',
                  ),
                  InfoChip(icon: Icons.sync, label: 'Avg cycle', value: '${avgCycleDays}d'),
                  InfoChip(icon: Icons.timer, label: 'Avg period', value: '${avgPeriodDays}d'),
                ],
              ),
              const SizedBox(height: 12),
              if (nextStart != null && nextEnd != null)
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Predicted next period: ${_fmt(nextStart!)} – ${_fmt(nextEnd!)}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
  String _two(int n) => n.toString().padLeft(2, '0');
}

extension ColorExtension on Color {
  Color withValues({
    double? red,
    double? green,
    double? blue,
    double? alpha,
  }) {
    return Color.fromARGB(
      (alpha != null ? (alpha * 255).round() : this.alpha),
      (red != null ? (red * 255).round() : this.red),
      (green != null ? (green * 255).round() : this.green),
      (blue != null ? (blue * 255).round() : this.blue),
    );
  }
}
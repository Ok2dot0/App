import 'package:flutter/material.dart';
import '../utils/app_utils.dart';
import 'day_cell.dart';

class MiniMonthCalendar extends StatelessWidget {
  const MiniMonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onJumpToMonth,
    required this.isMarked,
    required this.isPredicted,
    required this.onToggleMarked,
  });

  final DateTime month; // Any day within the month, we use year+month
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onJumpToMonth;
  // Returns whether a given day is marked true.
  final bool Function(DateTime) isMarked;
  // Returns whether a given day is predicted next bleeding.
  final bool Function(DateTime) isPredicted;
  // Toggle handler (used on long-press of a day cell).
  final ValueChanged<DateTime> onToggleMarked;

  static const _weekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  DateTime _gridStart(DateTime m) {
    // First day of month
    final first = DateTime(m.year, m.month, 1);
    // We want the grid to start on Sunday. DateTime.weekday: Mon=1 ... Sun=7
    final daysToSubtract =
        first.weekday % 7; // 0 when Sunday, 1 when Monday, ...
    return first.subtract(Duration(days: daysToSubtract));
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<DateTime?> _showMonthYearPicker(
    BuildContext context, {
    required DateTime initial,
  }) async {
    final theme = Theme.of(context);
    int tempYear = initial.year.clamp(kMinYear, kMaxYear);
    int tempMonth = initial.month;
    return showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select month and year'),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous year',
                        onPressed: tempYear > kMinYear
                            ? () => setLocal(() => tempYear -= 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '$tempYear',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next year',
                        onPressed: tempYear < kMaxYear
                            ? () => setLocal(() => tempYear += 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int m = 1; m <= 12; m++)
                        ChoiceChip(
                          label: Text(_monthName(m).substring(0, 3)),
                          selected: m == tempMonth,
                          onSelected: (_) => setLocal(() => tempMonth = m),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(DateTime(tempYear, tempMonth, 1)),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = _gridStart(month);
    final today = DateTime.now();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with left Today button and centered arrows+label cluster.
            // The center cluster fits available space and won't overlap Today.
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: onToday,
                    child: const Text('Today'),
                  ),
                  Expanded(
                    child: Builder(builder: (context) {
                      final prevAllowed =
                          DateTime(month.year, month.month - 1).year >=
                              kMinYear;
                      final nextAllowed =
                          DateTime(month.year, month.month + 1).year <=
                              kMaxYear;
                      return LayoutBuilder(
                        builder: (context, cons) {
                          // Keep a stable center width across months; shrink on very small screens.
                          final double centerWidth = cons.maxWidth < 320
                              ? cons.maxWidth
                              : 320;
                          return Center(
                            child: SizedBox(
                              width: centerWidth,
                              height: 48,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      tooltip: 'Previous month',
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: prevAllowed ? onPrev : null,
                                    ),
                                  ),
                                  // Centered, tappable month/year label with padding to avoid arrow overlap.
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 48),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () async {
                                          final picked = await _showMonthYearPicker(
                                            context,
                                            initial: month,
                                          );
                                          if (picked != null) {
                                            onJumpToMonth(
                                              DateTime(picked.year, picked.month),
                                            );
                                          }
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${_monthName(month.month)} ${month.year}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      tooltip: 'Next month',
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: nextAllowed ? onNext : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Weekday labels (no week numbers)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final w in _weekdayLabels)
                  Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellWidth = constraints.maxWidth / 7;
                  final cellHeight = constraints.maxHeight / 6; // 6 weeks grid
                  return Column(
                    children: [
                      for (int week = 0; week < 6; week++)
                        SizedBox(
                          height: cellHeight,
                          child: Row(
                            children: [
                              for (int dow = 0; dow < 7; dow++)
                                DayCell(
                                  date: start.add(
                                    Duration(days: week * 7 + dow),
                                  ),
                                  isInMonth:
                                      start
                                          .add(Duration(days: week * 7 + dow))
                                          .month ==
                                      month.month,
                                  isToday: _isSameDate(
                                    start.add(Duration(days: week * 7 + dow)),
                                    today,
                                  ),
                                  isSelected:
                                      selected != null &&
                                      _isSameDate(
                                        start.add(
                                          Duration(days: week * 7 + dow),
                                        ),
                                        selected!,
                                      ),
                                  isMarked: isMarked(
                                    start.add(Duration(days: week * 7 + dow)),
                                  ),
                                  isPredicted: isPredicted(
                                    start.add(Duration(days: week * 7 + dow)),
                                  ),
                                  width: cellWidth,
                                  height: cellHeight,
                                  onTap: () => onSelect(
                                    start.add(Duration(days: week * 7 + dow)),
                                  ),
                                  onLongPress: () => onToggleMarked(
                                    start.add(Duration(days: week * 7 + dow)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
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
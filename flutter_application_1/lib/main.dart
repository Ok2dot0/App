import 'package:flutter/material.dart';

// Year bounds (4-digit)
const int kMinYear = 1000;
const int kMaxYear = 9999;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Calendar',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedMonth; // First day of the visible month
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = now;
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month);
      _selectedDate = now;
    });
  }

  void _prevMonth() {
    final prev = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    if (prev.year < kMinYear) return;
    setState(() => _focusedMonth = DateTime(prev.year, prev.month));
  }

  void _nextMonth() {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    if (next.year > kMaxYear) return;
    setState(() => _focusedMonth = DateTime(next.year, next.month));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top half: the mini calendar
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _MiniMonthCalendar(
                  month: _focusedMonth,
                  selected: _selectedDate,
                  onSelect: (date) => setState(() => _selectedDate = date),
                  onPrev: _prevMonth,
                  onNext: _nextMonth,
                  onToday: _goToToday,
                  onJumpToMonth: (d) => setState(() {
                    final yr = d.year.clamp(kMinYear, kMaxYear);
                    _focusedMonth = DateTime(yr, d.month);
                  }),
                ),
              ),
            ),
            const Divider(height: 1),
            // Bottom half: placeholder for daily specific stuff
            Expanded(flex: 1, child: _DailyDetails(date: _selectedDate)),
          ],
        ),
      ),
    );
  }
}

class _MiniMonthCalendar extends StatelessWidget {
  const _MiniMonthCalendar({
    required this.month,
    required this.selected,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onJumpToMonth,
  });

  final DateTime month; // Any day within the month, we use year+month
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onJumpToMonth;

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
                                _DayCell(
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
                                  width: cellWidth,
                                  height: cellHeight,
                                  onTap: () => onSelect(
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

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isInMonth,
    required this.isToday,
    required this.isSelected,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final DateTime date;
  final bool isInMonth;
  final bool isToday;
  final bool isSelected;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = isInMonth
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.45);
    final bg = isSelected ? theme.colorScheme.primary : Colors.transparent;
    final fg = isSelected ? theme.colorScheme.onPrimary : baseColor;

    return SizedBox(
      width: width,
      height: height,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyDetails extends StatelessWidget {
  const _DailyDetails({required this.date});

  final DateTime? date;

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
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.event_note),
                  title: Text('Your daily content goes here'),
                  subtitle: Text(
                    'Add tasks, notes, or events for the selected date.',
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Tap + to add more'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

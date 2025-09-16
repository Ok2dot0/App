import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // Persisted set of dates that are marked true. Default for all others is false.
  final Set<String> _markedDays = <String>{};
  SharedPreferences? _prefs;


  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = now;
    _initPrefsAndLoad();
  }

  Future<void> _initPrefsAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('markedDays') ?? const <String>[];
    setState(() {
      _prefs = prefs;
      _markedDays
        ..clear()
        ..addAll(saved);
    });
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isMarked(DateTime d) => _markedDays.contains(_dateKey(d));

  Future<void> _persistMarkedDays() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    // Only save days that are marked true
    final list = _markedDays.toList()..sort();
    await prefs.setStringList('markedDays', list);
  }

  void _setMarked(DateTime d, bool marked) {
    final key = _dateKey(d);
    setState(() {
      if (marked) {
        _markedDays.add(key);
      } else {
        _markedDays.remove(key);
      }
    });
    _persistMarkedDays();
  }

  void _toggleMarked(DateTime d) => _setMarked(d, !_isMarked(d));
  
  // --- Period detection & prediction helpers ---
  DateTime _parseKey(String k) {
    final parts = k.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? DateTime.now().month,
      int.tryParse(parts[2]) ?? DateTime.now().day,
    );
  }

  List<DateTime> get _markedDateTimes {
    final list = _markedDays.map(_parseKey).toList()
      ..sort((a, b) => a.compareTo(b));
    return list;
  }

  List<_PeriodRange> get _periodRanges {
    final dates = _markedDateTimes;
    if (dates.isEmpty) return const [];
    final List<_PeriodRange> ranges = [];
    DateTime start = dates.first;
    DateTime last = dates.first;
    for (int i = 1; i < dates.length; i++) {
      final d = dates[i];
      if (d.difference(last).inDays == 1) {
        last = d;
      } else {
        ranges.add(_PeriodRange(start: start, end: last));
        start = d;
        last = d;
      }
    }
    ranges.add(_PeriodRange(start: start, end: last));
    return ranges;
  }

  _Prediction get _prediction {
    final ranges = _periodRanges;
    if (ranges.isEmpty) {
      return const _Prediction(
        avgCycleDays: 28,
        avgPeriodDays: 5,
        lastRange: null,
        nextStart: null,
        nextEnd: null,
      );
    }

    final periods = ranges.map((r) => r.lengthDays).toList();
    final avgPeriod =
        (periods.reduce((a, b) => a + b) / periods.length).round().clamp(2, 10);

    final starts = ranges.map((r) => r.start).toList();
    int avgCycle;
    if (starts.length >= 2) {
      final List<int> gaps = [];
      for (int i = 1; i < starts.length; i++) {
        gaps.add(starts[i].difference(starts[i - 1]).inDays);
      }
      avgCycle =
          (gaps.reduce((a, b) => a + b) / gaps.length).round().clamp(21, 60);
    } else {
      avgCycle = 28;
    }

    final last = ranges.last;
    final predictedStart = last.start.add(Duration(days: avgCycle));
    final predictedEnd = predictedStart.add(Duration(days: avgPeriod - 1));

    return _Prediction(
      avgCycleDays: avgCycle,
      avgPeriodDays: avgPeriod,
      lastRange: last,
      nextStart: predictedStart,
      nextEnd: predictedEnd,
    );
  }

  // (Settings/Account sheets removed for simplified app)

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
      appBar: AppBar(
        title: const Text('Cycle Calendar'),
        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
          ),
        ],
      ),
      body: _buildCalendarContent(),
    );
  }

  // (Multi-tab content removed)

  Widget _buildCalendarContent() {
    final pred = _prediction;
    // Build a set of predicted bleeding day keys for quick lookup
    final Set<String> predictedKeys = <String>{};
    if (pred.nextStart != null && pred.nextEnd != null) {
      DateTime d = DateTime(pred.nextStart!.year, pred.nextStart!.month, pred.nextStart!.day);
      final DateTime end = DateTime(pred.nextEnd!.year, pred.nextEnd!.month, pred.nextEnd!.day);
      while (!d.isAfter(end)) {
        predictedKeys.add(_dateKey(d));
        d = d.add(const Duration(days: 1));
      }
    }
    return Column(
      children: [
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
              isMarked: _isMarked,
              isPredicted: (d) => predictedKeys.contains(_dateKey(d)),
              onToggleMarked: _toggleMarked,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 1,
          child: _DailyDetails(
            date: _selectedDate,
            marked: _selectedDate == null ? false : _isMarked(_selectedDate!),
            onMarkedChanged: (v) {
              final d = _selectedDate;
              if (d != null) _setMarked(d, v);
            },
            lastRange: pred.lastRange,
            avgCycleDays: pred.avgCycleDays,
            avgPeriodDays: pred.avgPeriodDays,
            nextStart: pred.nextStart,
            nextEnd: pred.nextEnd,
          ),
        ),
      ],
    );
  }
}

// (Placeholder pane removed)

class _MiniMonthCalendar extends StatelessWidget {
  const _MiniMonthCalendar({
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

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isInMonth,
    required this.isToday,
    required this.isSelected,
    required this.isMarked,
    required this.isPredicted,
    required this.width,
    required this.height,
    required this.onTap,
    required this.onLongPress,
  });

  final DateTime date;
  final bool isInMonth;
  final bool isToday;
  final bool isSelected;
  final bool isMarked;
  final bool isPredicted;
  final double width;
  final double height;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine future vs past to slightly change text tone
    final DateTime today = DateTime.now();
    final DateTime t0 = DateTime(today.year, today.month, today.day);
    final DateTime d0 = DateTime(date.year, date.month, date.day);
    final bool isPastDay = d0.isBefore(t0);
    Color baseColor;
    if (!isInMonth) {
      baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.45);
    } else if (isPastDay && !isSelected && !isMarked && !isPredicted) {
      // Slightly gray out past days
      baseColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    } else {
      baseColor = theme.colorScheme.onSurface;
    }
    // Background:
    // - Selected day: primary
    // - Bleeding day actual (not selected): errorContainer tint
    // - Predicted bleeding (not selected and not marked): tertiaryContainer tint
    // - Otherwise: transparent
    final Color bg = isSelected
        ? theme.colorScheme.primary
        : (isMarked
            ? theme.colorScheme.errorContainer
            : (isPredicted ? theme.colorScheme.tertiaryContainer : Colors.transparent));
    // Foreground color adapts for contrast
    final Color fg = isSelected
        ? theme.colorScheme.onPrimary
        : (isMarked
            ? theme.colorScheme.onErrorContainer
            : (isPredicted ? theme.colorScheme.onTertiaryContainer : baseColor));

    return SizedBox(
      width: width,
      height: height,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
  const _DailyDetails({
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
  final _PeriodRange? lastRange;
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
          _PredictionPanel(
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

class _PredictionPanel extends StatelessWidget {
  const _PredictionPanel({
    required this.lastRange,
    required this.avgCycleDays,
    required this.avgPeriodDays,
    required this.nextStart,
    required this.nextEnd,
  });

  final _PeriodRange? lastRange;
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
                  _InfoChip(
                    icon: Icons.event,
                    label: 'Last period',
                    value: '${_fmt(lastRange!.start)} – ${_fmt(lastRange!.end)} (${lastRange!.lengthDays}d)',
                  ),
                  _InfoChip(icon: Icons.sync, label: 'Avg cycle', value: '${avgCycleDays}d'),
                  _InfoChip(icon: Icons.timer, label: 'Avg period', value: '${avgPeriodDays}d'),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PeriodRange {
  const _PeriodRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
  int get lengthDays => end.difference(start).inDays + 1;
}

class _Prediction {
  const _Prediction({
    required this.avgCycleDays,
    required this.avgPeriodDays,
    required this.lastRange,
    required this.nextStart,
    required this.nextEnd,
  });

  final int avgCycleDays;
  final int avgPeriodDays;
  final _PeriodRange? lastRange;
  final DateTime? nextStart;
  final DateTime? nextEnd;
}

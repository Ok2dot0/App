import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/period_models.dart';
import 'utils/app_utils.dart';
import 'widgets/daily_details.dart';
import 'widgets/mini_month_calendar.dart';

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

  List<PeriodRange> get _periodRanges {
    final dates = _markedDateTimes;
    if (dates.isEmpty) return const [];
    final List<PeriodRange> ranges = [];
    DateTime start = dates.first;
    DateTime last = dates.first;
    for (int i = 1; i < dates.length; i++) {
      final d = dates[i];
      if (d.difference(last).inDays == 1) {
        last = d;
      } else {
        ranges.add(PeriodRange(start: start, end: last));
        start = d;
        last = d;
      }
    }
    ranges.add(PeriodRange(start: start, end: last));
    return ranges;
  }

  Prediction get _prediction {
    final ranges = _periodRanges;
    if (ranges.isEmpty) {
      return const Prediction(
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

    return Prediction(
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
            child: MiniMonthCalendar(
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
          child: DailyDetails(
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

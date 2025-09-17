class PeriodRange {
  const PeriodRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
  int get lengthDays => end.difference(start).inDays + 1;
}

class Prediction {
  const Prediction({
    required this.avgCycleDays,
    required this.avgPeriodDays,
    required this.lastRange,
    required this.nextStart,
    required this.nextEnd,
  });

  final int avgCycleDays;
  final int avgPeriodDays;
  final PeriodRange? lastRange;
  final DateTime? nextStart;
  final DateTime? nextEnd;
}
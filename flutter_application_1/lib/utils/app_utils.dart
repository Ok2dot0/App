import 'package:flutter/material.dart';

// Year bounds (4-digit)
const int kMinYear = 1000;
const int kMaxYear = 9999;

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

extension DateTimeFormatting on DateTime {
  String toFormattedDate() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String toMonthYear() {
    return '${monthName()} $year';
  }

  String monthName() {
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

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
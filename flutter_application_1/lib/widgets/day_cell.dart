import 'package:flutter/material.dart';

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
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
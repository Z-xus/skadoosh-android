import 'package:flutter/material.dart';
import 'package:skadoosh_app/models/habit.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';

class MinimalHabitCalendar extends StatefulWidget {
  final List<Habit> habits;
  final Function(DateTime)? onDateTap;

  const MinimalHabitCalendar({super.key, required this.habits, this.onDateTap});

  @override
  State<MinimalHabitCalendar> createState() => _MinimalHabitCalendarState();
}

class _MinimalHabitCalendarState extends State<MinimalHabitCalendar> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        SizedBox(height: DesignTokens.spaceM.top),
        _buildCalendarGrid(colorScheme),
        SizedBox(height: DesignTokens.spaceM.top),
        _buildLegend(colorScheme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: Icon(
                    Icons.chevron_left,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  iconSize: 20,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                Text(
                  '${monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  iconSize: 20,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () => widget.onDateTap?.call(DateTime.now()),
          icon: Icon(
            Icons.add_circle_outline,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  Widget _buildCalendarGrid(ColorScheme colorScheme) {
    final startOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );

    // Get first day of calendar view (might be previous month)
    final startOfCalendar = startOfMonth.subtract(
      Duration(days: startOfMonth.weekday % 7),
    );

    // Build 6 weeks of calendar
    final weeks = <Widget>[];

    // Day headers
    weeks.add(_buildDayHeaders(colorScheme));
    weeks.add(SizedBox(height: DesignTokens.spaceXS.top));

    for (int week = 0; week < 6; week++) {
      final weekDays = <Widget>[];

      for (int day = 0; day < 7; day++) {
        final date = startOfCalendar.add(Duration(days: week * 7 + day));
        final isCurrentMonth = date.month == _displayedMonth.month;
        final isToday = _isSameDay(date, DateTime.now());

        weekDays.add(
          Expanded(
            child: _buildDayCell(
              date: date,
              isCurrentMonth: isCurrentMonth,
              isToday: isToday,
              colorScheme: colorScheme,
            ),
          ),
        );
      }

      weeks.add(SizedBox(height: 48, child: Row(children: weekDays)));
      weeks.add(SizedBox(height: DesignTokens.spaceXS.top));
    }

    return Column(children: weeks);
  }

  Widget _buildDayHeaders(ColorScheme colorScheme) {
    const dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return Row(
      children: dayNames
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required bool isCurrentMonth,
    required bool isToday,
    required ColorScheme colorScheme,
  }) {
    final completionLevel = _getCompletionLevel(date);
    final hasCompletions = completionLevel > 0;
    final totalHabits = widget.habits.length;

    return GestureDetector(
      onTap: () => widget.onDateTap?.call(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _getCellColor(
            completionLevel: completionLevel,
            totalHabits: totalHabits,
            isCurrentMonth: isCurrentMonth,
            isToday: isToday,
            colorScheme: colorScheme,
          ),
          border: isToday
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: _getTextColor(
                    hasCompletions: hasCompletions,
                    isCurrentMonth: isCurrentMonth,
                    isToday: isToday,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
              if (hasCompletions && totalHabits > 1)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.onPrimary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        SizedBox(width: DesignTokens.spaceS.left),
        ...List.generate(5, (index) {
          final alpha = (index + 1) * 0.2;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: index == 0
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : colorScheme.primary.withValues(alpha: alpha),
            ),
          );
        }),
        SizedBox(width: DesignTokens.spaceS.left),
        Text(
          'More',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Color _getCellColor({
    required int completionLevel,
    required int totalHabits,
    required bool isCurrentMonth,
    required bool isToday,
    required ColorScheme colorScheme,
  }) {
    if (!isCurrentMonth) {
      return colorScheme.surface;
    }

    if (completionLevel == 0) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    }

    // Calculate completion percentage
    final percentage = totalHabits > 0 ? completionLevel / totalHabits : 0.0;

    if (percentage >= 1.0) {
      // All habits completed
      return colorScheme.primary;
    } else if (percentage >= 0.75) {
      // 75%+ completed
      return colorScheme.primary.withValues(alpha: 0.8);
    } else if (percentage >= 0.5) {
      // 50%+ completed
      return colorScheme.primary.withValues(alpha: 0.6);
    } else if (percentage >= 0.25) {
      // 25%+ completed
      return colorScheme.primary.withValues(alpha: 0.4);
    } else {
      // Some completion
      return colorScheme.primary.withValues(alpha: 0.2);
    }
  }

  Color _getTextColor({
    required bool hasCompletions,
    required bool isCurrentMonth,
    required bool isToday,
    required ColorScheme colorScheme,
  }) {
    if (!isCurrentMonth) {
      return colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
    }

    if (hasCompletions) {
      return colorScheme.onPrimary;
    }

    if (isToday) {
      return colorScheme.primary;
    }

    return colorScheme.onSurface;
  }

  int _getCompletionLevel(DateTime date) {
    int completions = 0;

    for (final habit in widget.habits) {
      final hasCompletion = habit.completionDates.any(
        (completionDate) => _isSameDay(completionDate, date),
      );
      if (hasCompletion) {
        completions++;
      }
    }

    return completions;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

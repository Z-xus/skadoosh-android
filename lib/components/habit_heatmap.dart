import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:skadoosh_app/models/habit.dart';

class MinimalHeatMap extends StatelessWidget {
  final List<Habit> habits;
  final DateTime? startDate;

  const MinimalHeatMap({
    super.key, 
    required this.habits, 
    this.startDate
  });

  @override
  Widget build(BuildContext context) {
    // 1. Generate the dataset for the heatmap
    Map<DateTime, int> dataset = {};

    for (var habit in habits) {
      // FIX: Iterate over completionDatesTimestamps (int) instead of completionDates (DateTime)
      for (var timestamp in habit.completionDatesTimestamps) {
        // Convert timestamp (int) back to DateTime
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        
        // Normalize date to remove time (hours/mins) so keys match perfectly
        final normalizedDate = DateTime(date.year, date.month, date.day);

        // Increment the count for this day (darker color = more habits done)
        if (dataset.containsKey(normalizedDate)) {
          dataset[normalizedDate] = dataset[normalizedDate]! + 1;
        } else {
          dataset[normalizedDate] = 1;
        }
      }
    }

    // 2. Define colors based on your app theme
    // Using shades of Green for "Success"
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: HeatMap(
        startDate: startDate ?? DateTime.now(),
        endDate: DateTime.now(), // Don't show future empty days
        datasets: dataset,
        colorMode: ColorMode.opacity, // Opacity makes it look cleaner/minimal
        showColorTip: false, // Hide the "Less -> More" legend
        showText: false, // Hide day numbers for a purely visual "dot" look
        scrollable: true,
        size: 30, // Size of each square
        colorsets: const {
          1: Colors.green, // Base color, opacity will scale automatically
        },
        defaultColor: Theme.of(context).colorScheme.surfaceContainerHighest, // Color of empty days
        onClick: (value) {
          // Optional: Handle tap
        },
      ),
    );
  }
}

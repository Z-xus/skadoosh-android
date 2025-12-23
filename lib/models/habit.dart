import 'package:isar/isar.dart';

part 'habit.g.dart';

@Collection()
class Habit {
  Id id = Isar.autoIncrement;

  late String title;

  // Stores timestamps (milliseconds since epoch) for every day completed
  List<int> completionDatesTimestamps = [];

  @Enumerated(EnumType.ordinal)
  HabitCategory category = HabitCategory.other;

  // --- CYCLIC LOGIC FIELDS ---
  int goalDays = 7; 
  int currentProgress = 0;
  int totalLifetimeCompletions = 0;
  bool isCycleFinished = false; 

  // --- HELPERS ---
  bool get isCompletedToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); 
    
    return completionDatesTimestamps.any((ts) {
      final date = DateTime.fromMillisecondsSinceEpoch(ts);
      return date.year == today.year && 
             date.month == today.month && 
             date.day == today.day;
    });
  }

  double get progressPercentage {
    if (goalDays == 0) return 0;
    double pct = currentProgress / goalDays;
    return pct > 1.0 ? 1.0 : pct;
  }
}

enum HabitCategory {
  health,
  work,
  learning,
  mindfulness,
  other,
}

// --- NEW TODO MODEL ---
@Collection()
class Todo {
  Id id = Isar.autoIncrement;

  late String title;
  bool isCompleted = false;
  
  DateTime? createdAt;
}

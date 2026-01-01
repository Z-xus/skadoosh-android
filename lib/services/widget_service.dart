import 'package:home_widget/home_widget.dart';
import 'package:skadoosh_app/models/note_database.dart';

class WidgetService {
  static const String _noteWidgetName = 'NoteWidget';
  static const String _habitWidgetName = 'HabitWidget';
  static const String _quickNoteWidgetName = 'QuickNoteWidget';
  static const String _taskWidgetName = 'TaskWidget';

  // Initialize widget service
  static Future<void> initialize() async {
    // Set up widget update callback
    HomeWidget.setAppGroupId('group.skadoosh.widget');
  }

  // Update note widget with the latest note
  static Future<void> updateNoteWidget() async {
    try {
      // Ensure database is initialized
      await NoteDatabase.initialize();

      final noteDb = NoteDatabase();

      // Get all active notes using the NoteDatabase method
      final allNotes = await noteDb.getAllNotes();

      // Filter and sort
      final activeNotes =
          allNotes.where((note) => !note.isDeleted && !note.isArchived).toList()
            ..sort(
              (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
                a.updatedAt ?? DateTime(1970),
              ),
            );

      final note = activeNotes.isNotEmpty ? activeNotes.first : null;

      if (note != null) {
        final content = await note.getContent();

        // Extract first 500 characters for preview
        final preview = content.length > 500
            ? '${content.substring(0, 500)}...'
            : content;

        await HomeWidget.saveWidgetData<String>('note_title', note.title);
        await HomeWidget.saveWidgetData<String>('note_content', preview);
        await HomeWidget.saveWidgetData<String>('note_id', note.id.toString());
        await HomeWidget.saveWidgetData<String>(
          'note_updated',
          note.updatedAt?.toIso8601String() ?? '',
        );
      } else {
        // No notes available
        await HomeWidget.saveWidgetData<String>('note_title', 'No Notes');
        await HomeWidget.saveWidgetData<String>(
          'note_content',
          'Create your first note to see it here!',
        );
        await HomeWidget.saveWidgetData<String>('note_id', '');
        await HomeWidget.saveWidgetData<String>('note_updated', '');
      }

      // Update the widget
      await HomeWidget.updateWidget(
        name: _noteWidgetName,
        androidName: 'NoteWidgetProvider',
        iOSName: _noteWidgetName,
      );
    } catch (e) {
      print('Error updating note widget: $e');
    }
  }

  // Update habit widget with today's habits
  static Future<void> updateHabitWidget() async {
    try {
      print('📱 Updating habit widget...');
      // Ensure database is initialized
      await NoteDatabase.initialize();

      final noteDb = NoteDatabase();

      // Fetch habits to populate currentHabits
      await noteDb.fetchHabits();

      // Get all habits from currentHabits
      final habits = noteDb.currentHabits;
      print('📊 Found ${habits.length} habits');

      // Count completed habits today
      final completedToday = habits.where((h) => h.isCompletedToday).length;
      final totalHabits = habits.length;

      print('✅ Completed: $completedToday / $totalHabits');

      await HomeWidget.saveWidgetData<int>('habit_completed', completedToday);
      await HomeWidget.saveWidgetData<int>('habit_total', totalHabits);

      // Calculate progress percentage
      final progress = totalHabits > 0
          ? (completedToday / totalHabits * 100).round()
          : 0;
      await HomeWidget.saveWidgetData<int>('habit_progress', progress);

      // Save individual habit data (up to 5 habits)
      for (int i = 0; i < 5; i++) {
        if (i < habits.length) {
          final habit = habits[i];
          print(
            '💾 Saving habit ${i + 1}: ${habit.title} (ID: ${habit.id}, Done: ${habit.isCompletedToday})',
          );
          await HomeWidget.saveWidgetData<int>('habit_${i + 1}_id', habit.id);
          await HomeWidget.saveWidgetData<String>(
            'habit_${i + 1}_title',
            habit.title,
          );
          await HomeWidget.saveWidgetData<bool>(
            'habit_${i + 1}_done',
            habit.isCompletedToday,
          );
        } else {
          // Clear unused slots
          await HomeWidget.saveWidgetData<int>('habit_${i + 1}_id', -1);
          await HomeWidget.saveWidgetData<String>('habit_${i + 1}_title', '');
          await HomeWidget.saveWidgetData<bool>('habit_${i + 1}_done', false);
        }
      }

      print('🔄 Updating widget UI...');
      // Update the widget
      await HomeWidget.updateWidget(
        name: _habitWidgetName,
        androidName: 'HabitWidgetProvider',
        iOSName: _habitWidgetName,
      );
      print('✅ Habit widget updated successfully!');
    } catch (e) {
      print('❌ Error updating habit widget: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Update task widget with today's tasks
  static Future<void> updateTaskWidget() async {
    try {
      print('📱 Updating task widget...');
      // Ensure database is initialized
      await NoteDatabase.initialize();

      final noteDb = NoteDatabase();

      // Fetch tasks to populate currentTodos
      await noteDb.fetchTodos();

      // Get all tasks from currentTodos
      final tasks = noteDb.currentTodos;
      print('📊 Found ${tasks.length} tasks');

      // Count completed tasks
      final completedTasks = tasks.where((t) => t.isCompleted).length;
      final totalTasks = tasks.length;

      print('✅ Completed: $completedTasks / $totalTasks');

      await HomeWidget.saveWidgetData<int>('task_completed', completedTasks);
      await HomeWidget.saveWidgetData<int>('task_total', totalTasks);

      // Calculate progress percentage
      final progress = totalTasks > 0
          ? (completedTasks / totalTasks * 100).round()
          : 0;
      await HomeWidget.saveWidgetData<int>('task_progress', progress);

      // Save individual task data (up to 5 tasks)
      for (int i = 0; i < 5; i++) {
        if (i < tasks.length) {
          final task = tasks[i];
          print(
            '💾 Saving task ${i + 1}: ${task.title} (ID: ${task.id}, Done: ${task.isCompleted})',
          );
          await HomeWidget.saveWidgetData<int>('task_${i + 1}_id', task.id);
          await HomeWidget.saveWidgetData<String>(
            'task_${i + 1}_title',
            task.title,
          );
          await HomeWidget.saveWidgetData<bool>(
            'task_${i + 1}_done',
            task.isCompleted,
          );
        } else {
          // Clear unused slots
          await HomeWidget.saveWidgetData<int>('task_${i + 1}_id', -1);
          await HomeWidget.saveWidgetData<String>('task_${i + 1}_title', '');
          await HomeWidget.saveWidgetData<bool>('task_${i + 1}_done', false);
        }
      }

      print('🔄 Updating widget UI...');
      // Update the widget
      await HomeWidget.updateWidget(
        name: _taskWidgetName,
        androidName: 'TaskWidgetProvider',
        iOSName: _taskWidgetName,
      );
      print('✅ Task widget updated successfully!');
    } catch (e) {
      print('❌ Error updating task widget: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Update quick note widget (for tapping to open app and create note)
  static Future<void> updateQuickNoteWidget() async {
    try {
      // Ensure database is initialized
      await NoteDatabase.initialize();

      final noteDb = NoteDatabase();

      // Get all notes using the database method
      final allNotes = await noteDb.getAllNotes();
      final activeNotes = allNotes
          .where((note) => !note.isDeleted && !note.isArchived)
          .toList();

      final noteCount = activeNotes.length;

      await HomeWidget.saveWidgetData<int>('total_notes', noteCount);

      // Update the widget
      await HomeWidget.updateWidget(
        name: _quickNoteWidgetName,
        androidName: 'QuickNoteWidgetProvider',
        iOSName: _quickNoteWidgetName,
      );
    } catch (e) {
      print('Error updating quick note widget: $e');
    }
  }

  // Update all widgets
  static Future<void> updateAllWidgets() async {
    await Future.wait([
      updateNoteWidget(),
      updateHabitWidget(),
      updateTaskWidget(),
      updateQuickNoteWidget(),
    ]);
  }

  // Handle widget tap events
  static Future<void> handleWidgetTap(Uri? uri) async {
    if (uri != null) {
      // Parse the action from the URI
      final action = uri.host;

      switch (action) {
        case 'open_note':
          final noteId = uri.queryParameters['id'];
          // Navigate to note (handled by app)
          print('Opening note: $noteId');
          break;
        case 'create_note':
          // Navigate to create note screen
          print('Creating new note');
          break;
        case 'open_habits':
          // Navigate to habits page
          print('Opening habits');
          break;
        default:
          print('Unknown widget action: $action');
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/theme/theme_provider.dart';
import 'package:skadoosh_app/services/device_pairing_service.dart';
import 'package:skadoosh_app/services/storage_service.dart';
import 'package:skadoosh_app/services/file_watcher_service.dart';
import 'package:skadoosh_app/services/widget_service.dart';
import 'pages/notes_page.dart';
import 'pages/user_onboarding_page.dart';
import 'pages/edit_note_page.dart';
import 'components/note_selection_dialog.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Method channel for widget communication
const platform = MethodChannel('com.example.skadoosh_app/widget');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme provider with lightweight default (no SharedPreferences yet)
  final themeProvider = ThemeProvider();

  // Set up widget callback listener for widget interactions
  HomeWidget.setAppGroupId('group.skadoosh.widget');
  HomeWidget.registerInteractivityCallback(backgroundCallback);

  // Set up method channel handler for widget actions
  platform.setMethodCallHandler(_handleMethodCall);

  // Show UI immediately
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NoteDatabase()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );

  // Initialize services in background after UI is shown
  _initializeServices(themeProvider);
}

/// Handle method calls from native Android code
Future<dynamic> _handleMethodCall(MethodCall call) async {
  if (call.method == 'handleWidgetAction') {
    final args = call.arguments as Map;
    final uriString = args['uri'] as String?;

    print('Received widget action: $uriString');

    if (uriString != null) {
      final uri = Uri.parse(uriString);
      _handleWidgetIntentFromChannel(uri);
    }
  }
}

/// Handle widget intent from method channel
void _handleWidgetIntentFromChannel(Uri uri) {
  print('Handling widget intent: $uri');
  print('URI path: ${uri.path}');
  print('URI query parameters: ${uri.queryParameters}');

  final action = uri.queryParameters['action'];
  print('Action: $action');

  // Wait a bit for navigation context to be ready
  Future.delayed(const Duration(milliseconds: 300), () {
    if (navigatorKey.currentContext != null) {
      switch (action) {
        case 'CREATE_NEW_NOTE':
          print('Creating new note...');
          Navigator.of(
            navigatorKey.currentContext!,
          ).push(MaterialPageRoute(builder: (context) => const EditNotePage()));
          break;
        case 'SELECT_NOTE_FOR_WIDGET':
          print('Selecting note for widget...');
          final widgetId = uri.queryParameters['widget_id'];
          showDialog(
            context: navigatorKey.currentContext!,
            builder: (context) => NoteSelectionDialog(widgetId: widgetId),
          );
          break;
        case 'TOGGLE_HABIT':
          print('Toggling habit...');
          final habitId = uri.queryParameters['habit_id'];
          if (habitId != null) {
            _toggleHabitFromWidget(int.parse(habitId));
          }
          break;
        case 'TOGGLE_TASK':
          print('Toggling task...');
          final taskId = uri.queryParameters['task_id'];
          if (taskId != null) {
            _toggleTaskFromWidget(int.parse(taskId));
          }
          break;
        default:
          print('Unknown widget action: $action');
      }
    } else {
      print('Navigator context not ready yet');
    }
  });
}

/// Toggle task from widget
Future<void> _toggleTaskFromWidget(int taskId) async {
  try {
    await NoteDatabase.initialize();

    // Get the NoteDatabase instance from Provider context
    final context = navigatorKey.currentContext;
    NoteDatabase? noteDb;

    if (context != null) {
      try {
        noteDb = context.read<NoteDatabase>();
      } catch (e) {
        print('Could not get NoteDatabase from context: $e');
      }
    }

    // Fallback to creating new instance if context not available
    noteDb ??= NoteDatabase();

    final task = await noteDb.getTodoById(taskId);
    if (task == null) return;

    // Toggle completion using the database method
    await noteDb.toggleTodo(taskId);

    // Update widget
    await WidgetService.updateTaskWidget();
  } catch (e) {
    print('Error toggling task: $e');
  }
}

/// Toggle habit from widget
Future<void> _toggleHabitFromWidget(int habitId) async {
  try {
    await NoteDatabase.initialize();

    // Get the NoteDatabase instance from Provider context
    final context = navigatorKey.currentContext;
    NoteDatabase? noteDb;

    if (context != null) {
      try {
        noteDb = context.read<NoteDatabase>();
      } catch (e) {
        print('Could not get NoteDatabase from context: $e');
      }
    }

    // Fallback to creating new instance if context not available
    noteDb ??= NoteDatabase();

    final habit = await noteDb.getHabitById(habitId);
    if (habit == null) return;

    // Toggle completion using the database method
    await noteDb.checkHabitCompletion(habitId, !habit.isCompletedToday);

    // Update widget
    await WidgetService.updateHabitWidget();
  } catch (e) {
    print('Error toggling habit: $e');
  }
}

/// Background callback for widget interactions
@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  print('🔔 Background callback triggered: $uri');

  if (uri != null) {
    final action = uri.queryParameters['action'];
    print('🎯 Background action: $action');

    if (action == 'TOGGLE_HABIT') {
      final habitId = uri.queryParameters['habit_id'];
      if (habitId != null) {
        print('🔄 Toggling habit $habitId in background');
        await _toggleHabit(int.parse(habitId));
      }
    } else if (action == 'TOGGLE_TASK') {
      final taskId = uri.queryParameters['task_id'];
      if (taskId != null) {
        print('🔄 Toggling task $taskId in background');
        await _toggleTask(int.parse(taskId));
      }
    }
  }
}

/// Toggle habit completion status in background
Future<void> _toggleHabit(int habitId) async {
  try {
    print('📱 Starting habit toggle for ID: $habitId');
    await NoteDatabase.initialize();
    final noteDb = NoteDatabase();

    final habit = await noteDb.getHabitById(habitId);
    if (habit == null) {
      print('❌ Habit not found: $habitId');
      return;
    }

    print(
      '✅ Found habit: ${habit.title}, Current status: ${habit.isCompletedToday}',
    );

    // Toggle completion using the database method
    await noteDb.checkHabitCompletion(habitId, !habit.isCompletedToday);

    print('✅ Habit toggled successfully');
  } catch (e) {
    print('❌ Error toggling habit: $e');
  }
}

/// Toggle task completion status in background
Future<void> _toggleTask(int taskId) async {
  try {
    print('📱 Starting task toggle for ID: $taskId');
    await NoteDatabase.initialize();
    final noteDb = NoteDatabase();

    final task = await noteDb.getTodoById(taskId);
    if (task == null) {
      print('❌ Task not found: $taskId');
      return;
    }

    print('✅ Found task: ${task.title}, Current status: ${task.isCompleted}');

    // Toggle completion using the database method
    await noteDb.toggleTodo(taskId);

    print('✅ Task toggled successfully');
  } catch (e) {
    print('❌ Error toggling task: $e');
  }
}

/// Background service initialization with parallel execution where possible
Future<void> _initializeServices(ThemeProvider themeProvider) async {
  try {
    // Phase 1: Initialize critical services in parallel
    await Future.wait([
      NoteDatabase.initialize(),
      StorageService().init(),
      themeProvider.initialize(), // Load saved preferences
    ]);

    // Phase 2: Initialize services that depend on others
    final storageService = StorageService();
    await Future.wait([
      FileWatcherService().init(storageService.baseDirectoryPath),
      WidgetService.initialize(),
    ]);

    // Phase 3: Update widgets after initialization
    await WidgetService.updateAllWidgets();
  } catch (e) {
    // Handle initialization errors gracefully
    debugPrint('Service initialization error: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DevicePairingService _pairingService = DevicePairingService();
  bool _isLoading = true;
  bool _isUserRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    try {
      final isRegistered = await _pairingService.isUserRegistered();
      setState(() {
        _isUserRegistered = isRegistered;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking registration status: $e');
      // If there's an error, assume not registered to show onboarding
      setState(() {
        _isUserRegistered = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _isUserRegistered
          ? const NotesPage()
          : const UserOnboardingPage(),
      theme: Provider.of<ThemeProvider>(context).currentTheme,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/theme/theme_provider.dart';
import 'package:skadoosh_app/services/device_pairing_service.dart';
import 'package:skadoosh_app/services/storage_service.dart';
import 'package:skadoosh_app/services/file_watcher_service.dart';
import 'pages/notes_page.dart';
import 'pages/user_onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NoteDatabase.initialize();

  // Initialize StorageService
  final storageService = StorageService();
  await storageService.init();

  // Initialize FileWatcherService after StorageService is ready
  await FileWatcherService().init(storageService.baseDirectoryPath);

  // Initialize theme provider and load saved theme
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NoteDatabase()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
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

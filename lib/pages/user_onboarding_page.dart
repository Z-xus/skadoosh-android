import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skadoosh_app/services/device_pairing_service.dart';
import 'package:skadoosh_app/pages/notes_page.dart';
import 'package:skadoosh_app/pages/device_management_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserOnboardingPage extends StatefulWidget {
  const UserOnboardingPage({super.key});

  @override
  State<UserOnboardingPage> createState() => _UserOnboardingPageState();
}

class _UserOnboardingPageState extends State<UserOnboardingPage> {
  final _usernameController = TextEditingController();
  final _syncUrlController = TextEditingController();
  final _devicePairingService = DevicePairingService();

  bool _isLoading = false;
  String? _shareId;
  String? _errorMessage;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _loadSyncUrl();
    _checkExistingRegistration();
  }

  Future<void> _loadSyncUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('sync_server_url');
    if (savedUrl != null) {
      _syncUrlController.text = savedUrl;
    } else {
      // Default development URL
      _syncUrlController.text = 'http://localhost:3233';
    }
  }

  Future<void> _checkExistingRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final existingShareId = prefs.getString('user_share_id');
    final existingUsername = prefs.getString('username');

    if (existingShareId != null && existingUsername != null) {
      setState(() {
        _shareId = existingShareId;
        _usernameController.text = existingUsername;
        _isRegistered = true;
      });
    }
  }

  Future<void> _registerUser() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a username';
      });
      return;
    }

    if (_syncUrlController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a sync server URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize service with URL
      _devicePairingService.initialize(_syncUrlController.text.trim());

      // Register user
      final result = await _devicePairingService.registerUser(
        _usernameController.text.trim(),
      );

      if (result.success) {
        // Save registration details
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_share_id', result.shareId!);
        await prefs.setString('username', _usernameController.text.trim());
        await prefs.setString(
          'sync_server_url',
          _syncUrlController.text.trim(),
        );
        if (result.syncGroupId != null) {
          await prefs.setString('sync_group_id', result.syncGroupId!);
        }

        setState(() {
          _shareId = result.shareId;
          _isRegistered = true;
          _isLoading = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome, ${result.username}! Your Share ID: ${result.shareId}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Registration failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyShareId() {
    if (_shareId != null) {
      Clipboard.setData(ClipboardData(text: _shareId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share ID copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _goToNotes() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const NotesPage()),
    );
  }

  void _goToDeviceManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeviceManagementPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skadoosh Setup'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            const SizedBox(height: 20),
            Text(
              _isRegistered ? 'Welcome back!' : 'Welcome to Skadoosh',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _isRegistered
                  ? 'Your account is set up and ready to sync notes securely across devices.'
                  : 'Secure note synchronization made simple. Create an account to get started.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 30),

            if (!_isRegistered) ...[
              // Registration form
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _syncUrlController,
                decoration: const InputDecoration(
                  labelText: 'Sync Server URL',
                  hintText: 'https://your-server.com',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 20),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 20),

              // Register button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Registered user view
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Share ID',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _shareId ?? '',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontFamily: 'Courier',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyShareId,
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy Share ID',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share this ID with others to sync notes securely.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _goToNotes,
                  icon: const Icon(Icons.note),
                  label: const Text('Start Taking Notes'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _goToDeviceManagement,
                  icon: const Icon(Icons.devices),
                  label: const Text('Manage Devices'),
                ),
              ),
            ],

            const Spacer(),

            // Info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'End-to-End Encrypted',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your notes are encrypted on your device and can only be read by paired devices.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _syncUrlController.dispose();
    super.dispose();
  }
}

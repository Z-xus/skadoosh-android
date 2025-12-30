import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/services/key_based_sync_service.dart';
import 'package:skadoosh_app/pages/device_management_page.dart';

class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  final _urlController = TextEditingController();
  KeyBasedSyncService? _syncService;
  SyncStatus? _syncStatus;
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _initializeSyncService();
  }

  Future<void> _initializeSyncService() async {
    final noteDatabase = Provider.of<NoteDatabase>(context, listen: false);
    _syncService = KeyBasedSyncService(noteDatabase);
    await _syncService!.initialize();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    if (_syncService != null) {
      final status = await _syncService!.getSyncStatus();
      setState(() {
        _syncStatus = status;
        if (status.serverUrl != null) {
          _urlController.text = status.serverUrl!;
        }
      });
    }
  }

  Future<void> _configureSyncServer() async {
    if (_urlController.text.trim().isEmpty) {
      _showMessage('Please enter a server URL', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _syncService!.configureSyncServer(_urlController.text.trim());
      await _loadSyncStatus();
      _showMessage('Sync server configured successfully!');
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Key pair not configured')) {
        errorMsg =
            'Please set up device pairing first. Go to Settings > Device Management.';
      }
      _showMessage('Failed to configure sync server: $errorMsg', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    if (_syncService == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final isConnected = await _syncService!.testConnection();
      if (isConnected) {
        _showMessage('Connection successful!');
      } else {
        _showMessage('Failed to connect to server', isError: true);
      }
    } catch (e) {
      _showMessage('Connection test failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSync() async {
    if (_syncService == null || !_syncStatus!.isConfigured) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final result = await _syncService!.sync();
      if (result.success) {
        _showMessage(
          'Sync completed! Pushed: ${result.pushedNotes}, Pulled: ${result.pulledNotes}',
        );
        await _loadSyncStatus();
      } else {
        _showMessage('Sync failed: ${result.error}', isError: true);
      }
    } catch (e) {
      _showMessage('Sync failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    setState(() {
      _message = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Settings'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Management
            Card(
              color: colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Management',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Before syncing, you need to set up your device pairing. This determines which notes you can sync with other devices.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeviceManagementPage(),
                            ),
                          );
                          // Refresh sync service after returning from device management
                          await _initializeSyncService();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        icon: const Icon(Icons.devices),
                        label: const Text('Manage Devices'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Server Configuration
            Card(
              color: colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Server Configuration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'https://your-server.com',
                        labelStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _configureSyncServer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Configure'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                          ),
                          child: const Text('Test'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sync Status
            if (_syncStatus != null) ...[
              Card(
                color: colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusRow(
                        'Configured',
                        _syncStatus!.isConfigured ? 'Yes' : 'No',
                        _syncStatus!.isConfigured
                            ? Colors.green
                            : Colors.orange,
                      ),
                      if (_syncStatus!.keyFingerprint != null)
                        _buildStatusRow(
                          'Key Fingerprint',
                          _syncStatus!.keyFingerprint!.length > 16
                              ? '${_syncStatus!.keyFingerprint!.substring(0, 16)}...'
                              : _syncStatus!.keyFingerprint!,
                          Colors.blue,
                        ),
                      if (_syncStatus!.groupName != null)
                        _buildStatusRow(
                          'Sync Group',
                          _syncStatus!.groupName!,
                          Colors.blue,
                        ),
                      _buildStatusRow(
                        'Pending Changes',
                        _syncStatus!.pendingChanges.toString(),
                        _syncStatus!.pendingChanges > 0
                            ? Colors.orange
                            : Colors.green,
                      ),
                      if (_syncStatus!.lastSyncTime != null)
                        _buildStatusRow(
                          'Last Sync',
                          _formatDateTime(_syncStatus!.lastSyncTime!),
                          Colors.blue,
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isLoading || !_syncStatus!.isConfigured)
                              ? null
                              : _performSync,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Sync Now'),
                        ),
                      ),
                      if (!_syncStatus!.isConfigured) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sync disabled: ${_getSyncDisabledReason()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Instructions
            Card(
              color: colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Set up device pairing (Settings > Device Management)\n'
                      '2. Set up your sync server on your VPS\n'
                      '3. Enter the server URL above\n'
                      '4. Tap "Configure" to register this device with the server\n'
                      '5. Use "Sync Now" to sync your notes\n\n'
                      'Note: Only notes within the same device group are synced. Pair with other devices to sync with them.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_message != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(_message!, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurface)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _getSyncDisabledReason() {
    if (_syncService == null) return 'Service not initialized';
    if (_syncStatus == null) return 'Status not loaded';

    if (_syncStatus!.serverUrl == null || _syncStatus!.serverUrl!.isEmpty) {
      return 'Server URL not configured';
    }
    if (_syncStatus!.keyFingerprint == null) {
      return 'No sync key available. Go to Device Management to set up pairing.';
    }
    if (_syncStatus!.groupName == null) {
      return 'No sync group configured. Set up device pairing or pair with existing devices.';
    }
    return 'Configuration incomplete - check all settings above';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

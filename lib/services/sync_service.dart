import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/services/image_cache_service.dart';

class SyncService {
  static const String _baseUrlKey = 'sync_server_url';
  static const String _deviceIdKey = 'device_id';
  static const String _lastSyncKey = 'last_sync_time';
  static const String _userIdKey = 'user_id';

  String? _baseUrl;
  String? _deviceId;
  String? _userId;
  final NoteDatabase _noteDatabase;

  SyncService(this._noteDatabase);

  // Initialize sync service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey);
    _deviceId = prefs.getString(_deviceIdKey);
    _userId = prefs.getString(_userIdKey);

    if (_deviceId == null) {
      _deviceId = await _generateDeviceId();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }

    // Initialize image cache service
    await ImageCacheService.instance.initialize();

    print('SyncService initialized:');
    print('- Base URL: $_baseUrl');
    print('- Device ID: $_deviceId');
    print('- User ID: $_userId');
  }

  // Configure sync server URL
  Future<void> configureSyncServer(String baseUrl) async {
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl!);

    print('Configuring sync server: $_baseUrl');

    // Test connection and register device
    await _registerDevice();
  }

  // Generate unique device ID
  Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = 'ios_${iosInfo.identifierForVendor}';
      } else {
        deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      deviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    print('Generated device ID: $deviceId');
    return deviceId;
  }

  // Register device with sync server
  Future<void> _registerDevice() async {
    if (_baseUrl == null || _deviceId == null) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Unknown Device';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} (${iosInfo.model})';
      }

      print('Registering device: $_deviceId with name: $deviceName');
      print('Server URL: $_baseUrl/api/auth/register');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': _deviceId, 'deviceName': deviceName}),
      );

      print('Registration response: ${response.statusCode}');
      print('Registration body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userId = data['userId'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userIdKey, _userId!);

        print('Device registered successfully with userId: $_userId');
      } else {
        print('Registration failed with status: ${response.statusCode}');
        throw Exception(
          'Failed to register device: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Device registration error: $e');
      throw Exception('Device registration failed: $e');
    }
  }

  // Check if sync is configured
  bool get isConfigured =>
      _baseUrl != null && _deviceId != null && _userId != null;

  // Perform full sync
  Future<SyncResult> sync() async {
    print('Starting sync process...');
    print('Is configured: $isConfigured');
    print('Device ID: $_deviceId');
    print('User ID: $_userId');

    if (!isConfigured) {
      throw Exception('Sync not configured. Call configureSyncServer() first.');
    }

    try {
      // Step 1: Push local changes
      final pushResult = await _pushLocalChanges();

      // Step 2: Pull remote changes
      final pullResult = await _pullRemoteChanges();

      // Step 3: Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      print('Sync completed successfully');
      return SyncResult(
        success: true,
        pushedNotes: pushResult.pushedNotes,
        pulledNotes: pullResult.pulledNotes,
        conflicts: [],
      );
    } catch (e) {
      print('Sync failed: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  // Push local changes to server
  Future<PushResult> _pushLocalChanges() async {
    final notesToSync = _noteDatabase.currentNotes
        .where((note) => note.needsSync)
        .toList();

    print('Notes to push: ${notesToSync.length}');

    if (notesToSync.isEmpty) {
      return PushResult(pushedNotes: 0);
    }

    final notesData = notesToSync.map((note) {
      return {
        'localId': note.id,
        'serverId': note.serverId,
        'title': note.title,
        'content': '', // Add content field when you extend the Note model
        'imageUrls': note.imageUrls,
        'hasImages': note.hasImages,
        'eventType': note.serverId == null ? 'create' : 'update',
        'createdAt': note.createdAt?.toIso8601String(),
        'updatedAt': note.updatedAt?.toIso8601String(),
      };
    }).toList();

    print('Pushing notes data: $notesData');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/sync/push'),
      headers: {
        'Content-Type': 'application/json',
        'deviceid': _deviceId!, // Use lowercase header
      },
      body: jsonEncode({'notes': notesData}),
    );

    print('Push response status: ${response.statusCode}');
    print('Push response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;

      // Update local notes with server IDs and sync status
      for (final result in results) {
        final localId = result['localId'] as int;
        final note = notesToSync.firstWhere((n) => n.id == localId);

        if (result['status'] == 'created' || result['status'] == 'updated') {
          await _noteDatabase.updateSyncStatus(
            note.id,
            serverId: result['serverId'],
            lastSyncedAt: DateTime.now(),
            needsSync: false,
          );
        }
      }

      print('Pushed ${results.length} notes successfully');
      return PushResult(pushedNotes: results.length);
    } else {
      throw Exception(
        'Failed to push changes: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Pull remote changes from server
  Future<PullResult> _pullRemoteChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);

    String url = '$_baseUrl/api/sync/changes';
    if (lastSync != null) {
      url += '?since=$lastSync';
    }

    print('Pulling changes from: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {'deviceid': _deviceId!},
    );

    print('Pull response status: ${response.statusCode}');
    print('Pull response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final changes = data['changes'] as List;

      int pulledNotes = 0;

      for (final change in changes) {
        final serverId = change['id'];
        final title = change['title'];
        final eventType = change['event_type'];
        final imageUrls = (change['images'] as List?)?.cast<String>() ?? [];
        final hasImages = change['has_images'] ?? false;

        if (eventType == 'create') {
          // Check if we already have this note
          final existingNote = _noteDatabase.currentNotes
              .where((n) => n.serverId == serverId)
              .firstOrNull;

          if (existingNote == null) {
            await _noteDatabase.addNote(title);
            // Update the created note with server ID and image data
            final newNote = _noteDatabase.currentNotes.last;

            // Cache images locally
            List<String> localImagePaths = [];
            if (imageUrls.isNotEmpty) {
              localImagePaths = await ImageCacheService.instance
                  .cacheImagesForNote(imageUrls);
            }

            await _noteDatabase.updateSyncStatus(
              newNote.id,
              serverId: serverId,
              lastSyncedAt: DateTime.now(),
              needsSync: false,
              imageUrls: imageUrls,
              localImagePaths: localImagePaths,
              hasImages: hasImages,
            );
            pulledNotes++;
          }
        } else if (eventType == 'update') {
          // Find note by server ID and update it
          final existingNote = _noteDatabase.currentNotes
              .where((n) => n.serverId == serverId)
              .firstOrNull;

          if (existingNote != null) {
            await _noteDatabase.updateNote(existingNote.id, title);

            // Cache images locally if there are new ones
            List<String> localImagePaths = [];
            if (imageUrls.isNotEmpty) {
              localImagePaths = await ImageCacheService.instance
                  .cacheImagesForNote(imageUrls);
            }

            await _noteDatabase.updateSyncStatus(
              existingNote.id,
              lastSyncedAt: DateTime.now(),
              needsSync: false,
              imageUrls: imageUrls,
              localImagePaths: localImagePaths,
              hasImages: hasImages,
            );
            pulledNotes++;
          }
        }
      }

      print('Pulled ${pulledNotes} changes successfully');
      return PullResult(pulledNotes: pulledNotes);
    } else {
      throw Exception(
        'Failed to pull changes: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Test connection to sync server
  Future<bool> testConnection() async {
    if (_baseUrl == null) return false;

    try {
      print('Testing connection to: $_baseUrl/health');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      print('Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Get sync status
  Future<SyncStatus> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);
    final pendingChanges = _noteDatabase.currentNotes
        .where((note) => note.needsSync)
        .length;

    return SyncStatus(
      isConfigured: isConfigured,
      lastSyncTime: lastSync != null ? DateTime.parse(lastSync) : null,
      pendingChanges: pendingChanges,
      serverUrl: _baseUrl,
    );
  }
}

// Data classes for sync results
class SyncResult {
  final bool success;
  final String? error;
  final int pushedNotes;
  final int pulledNotes;
  final List<String> conflicts;

  SyncResult({
    required this.success,
    this.error,
    this.pushedNotes = 0,
    this.pulledNotes = 0,
    this.conflicts = const [],
  });
}

class PushResult {
  final int pushedNotes;

  PushResult({required this.pushedNotes});
}

class PullResult {
  final int pulledNotes;

  PullResult({required this.pulledNotes});
}

class SyncStatus {
  final bool isConfigured;
  final DateTime? lastSyncTime;
  final int pendingChanges;
  final String? serverUrl;

  SyncStatus({
    required this.isConfigured,
    this.lastSyncTime,
    required this.pendingChanges,
    this.serverUrl,
  });
}

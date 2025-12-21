import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/services/crypto_utils.dart';

class KeyBasedSyncService {
  static const String _baseUrlKey = 'sync_server_url';
  static const String _keyPairKey = 'user_key_pair';
  static const String _groupNameKey = 'sync_group_name';
  static const String _fingerprintKey = 'key_fingerprint';
  static const String _lastSyncKey = 'last_sync_time';

  String? _baseUrl;
  KeyPairInfo? _keyPair;
  String? _groupName;
  String? _fingerprint;
  String? _deviceId;
  final NoteDatabase _noteDatabase;

  KeyBasedSyncService(this._noteDatabase);

  // Initialize sync service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey);
    _groupName = prefs.getString(_groupNameKey);
    _fingerprint = prefs.getString(_fingerprintKey);

    // Try to load keys from device pairing service first (new format)
    final publicKeyJson = prefs.getString('user_public_key');
    final privateKeyJson = prefs.getString('user_private_key');

    if (publicKeyJson != null && privateKeyJson != null) {
      try {
        print('Loading keys from device pairing service...');

        // Parse private key from JSON
        final privateKey = CryptoUtils.parsePrivateKeyFromJson(privateKeyJson);

        // Generate fingerprint if not stored
        if (_fingerprint == null) {
          _fingerprint = CryptoUtils.getFingerprint(publicKeyJson);
          await prefs.setString(_fingerprintKey, _fingerprint!);
        }

        // Create KeyPairInfo with the JSON keys
        _keyPair = KeyPairInfo(
          publicKeyPem: publicKeyJson,
          privateKeyPem: privateKeyJson,
          fingerprint: _fingerprint!,
          privateKey: privateKey,
        );

        // Generate group name from fingerprint if not stored
        if (_groupName == null) {
          _groupName = 'group_$_fingerprint';
          await prefs.setString(_groupNameKey, _groupName!);
        }

        print('Keys loaded from device pairing service successfully');
        print('Fingerprint: $_fingerprint');
        print('Group name: $_groupName');
      } catch (e, stackTrace) {
        print('Error loading keys from device pairing service: $e');
        print('Stack trace: $stackTrace');
      }
    } else {
      // Fallback to old manual key format
      final keyData = prefs.getString(_keyPairKey);
      if (keyData != null) {
        try {
          print('Loading key data: ${keyData.length} characters');
          final keyMap = jsonDecode(keyData) as Map<String, dynamic>;
          print('Key map keys: ${keyMap.keys.toList()}');
          _keyPair = KeyPairInfo.fromMap(keyMap);
          print('Key pair loaded successfully');
        } catch (e, stackTrace) {
          print('Error loading key pair: $e');
          print('Stack trace: $stackTrace');
        }
      } else {
        print('No key data found in storage');
      }
    }

    _deviceId = await _generateDeviceId();

    print('KeyBasedSyncService initialized:');
    print('- Base URL: $_baseUrl');
    print('- Group Name: $_groupName');
    print('- Fingerprint: $_fingerprint');
    print('- Device ID: $_deviceId');
    print('- Has Key Pair: ${_keyPair != null}');
  }

  // Configure sync server URL
  Future<void> configureSyncServer(String baseUrl) async {
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl!);

    print('Configuring sync server: $_baseUrl');
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

    return deviceId;
  }

  // Get authentication headers with challenge-response
  Future<Map<String, String>> _getAuthHeaders() async {
    if (_keyPair == null || _fingerprint == null) {
      throw Exception(
        'Key pair not configured. Please generate or import a key first.',
      );
    }

    // Get challenge from server
    final challengeResponse = await http.post(
      Uri.parse('$_baseUrl/api/auth/challenge'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fingerprint': _fingerprint, 'deviceId': _deviceId}),
    );

    if (challengeResponse.statusCode != 200) {
      throw Exception(
        'Failed to get challenge: ${challengeResponse.statusCode} - ${challengeResponse.body}',
      );
    }

    final challengeData = jsonDecode(challengeResponse.body);
    final challenge = challengeData['challenge'] as String;

    print('Got challenge: ${challenge.substring(0, 20)}...');

    // Sign the challenge with our private key
    final signature = CryptoUtils.signData(challenge, _keyPair!.privateKey);

    print('Generated signature: ${signature.substring(0, 20)}...');

    return {
      'Content-Type': 'application/json',
      'key-fingerprint': _fingerprint!,
      'device-id': _deviceId!,
      'challenge': challenge,
      'signature': signature,
    };
  }

  // Check if sync is configured
  bool get isConfigured =>
      _baseUrl != null &&
      _keyPair != null &&
      _groupName != null &&
      _fingerprint != null;

  // Perform full sync
  Future<SyncResult> sync() async {
    print('\n=== Starting Key-Based Sync ===');
    print('Is configured: $isConfigured');
    print('Local notes before sync: ${_noteDatabase.currentNotes.length}');

    // Print local notes status
    for (final note in _noteDatabase.currentNotes) {
      print(
        'Local note: ${note.id} | serverId: ${note.serverId} | title: "${note.title}" | needsSync: ${note.needsSync}',
      );
    }

    if (!isConfigured) {
      throw Exception(
        'Sync not configured. Please set up keys and server first.',
      );
    }

    try {
      // Step 1: Push local changes
      print('\n--- Step 1: Pushing local changes ---');
      final pushResult = await _pushLocalChanges();

      // Step 2: Pull remote changes
      print('\n--- Step 2: Pulling remote changes ---');
      final pullResult = await _pullRemoteChanges();

      // Step 3: Update last sync time with server timestamp
      final prefs = await SharedPreferences.getInstance();
      final timestampToStore =
          pullResult.serverTimestamp ?? DateTime.now().toIso8601String();
      await prefs.setString(_lastSyncKey, timestampToStore);

      print('Updated last sync timestamp to: $timestampToStore');

      print('\nLocal notes after sync: ${_noteDatabase.currentNotes.length}');
      print('Key-based sync completed successfully');
      print('=== Sync Complete ===\n');

      return SyncResult(
        success: true,
        pushedNotes: pushResult.pushedNotes,
        pulledNotes: pullResult.pulledNotes,
        conflicts: [],
      );
    } catch (e) {
      print('Key-based sync failed: $e');
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
        'content': note.body, // Use the body field
        'eventType': note.serverId == null ? 'create' : 'update',
        'createdAt': note.createdAt?.toIso8601String(),
        'updatedAt': note.updatedAt?.toIso8601String(),
        'isDeleted': note.isDeleted, // Include delete status for trash sync
      };
    }).toList();

    print('Pushing notes data: $notesData');

    // Get authentication headers with challenge-response
    final headers = await _getAuthHeaders();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/sync/push'),
      headers: headers,
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

    // Get authentication headers with challenge-response
    final headers = await _getAuthHeaders();
    // Remove Content-Type for GET request
    headers.remove('Content-Type');

    final response = await http.get(Uri.parse(url), headers: headers);

    print('Pull response status: ${response.statusCode}');
    print('Pull response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final changes = data['changes'] as List;

      int pulledNotes = 0;

      for (final change in changes) {
        final serverId = change['id'];
        final title = change['title'] ?? '';
        final body = change['content'] ?? '';
        final eventType = change['event_type'];
        final eventTime = DateTime.parse(change['event_time']);

        print(
          'Processing change: $eventType for server ID $serverId, title: "$title"',
        );

        // Only handle create and update events, ignore delete events
        if (eventType == 'create') {
          // Check multiple ways to avoid duplicates:
          // 1. Check by server ID
          // 2. Check by title and approximate time (for notes created locally that might have been pushed)

          var existingNote = _noteDatabase.currentNotes
              .where((n) => n.serverId == serverId)
              .firstOrNull;

          // If not found by server ID, check by title and timing to avoid duplicates
          // from our own local notes that were just pushed
          if (existingNote == null) {
            final recentNotes = _noteDatabase.currentNotes
                .where(
                  (n) =>
                      n.title.trim() == title.trim() && // Match title
                      n.body.trim() == body.trim() && // Also match body content
                      n.serverId == null && // Local note without server ID
                      n.createdAt != null &&
                      eventTime.difference(n.createdAt!).abs().inMinutes <
                          10, // Within 10 minutes for better matching
                )
                .toList();

            if (recentNotes.isNotEmpty) {
              // This is likely our own note that was just pushed, update it with server ID
              existingNote = recentNotes.first;
              await _noteDatabase.updateSyncStatus(
                existingNote.id,
                serverId: serverId,
                lastSyncedAt: DateTime.now(),
                needsSync: false,
              );
              print('Updated local note with server ID: $serverId');
              pulledNotes++;
              continue;
            }
          }

          // If still no match, create a new note (genuine remote note)
          if (existingNote == null) {
            // Create note with explicit needsSync = false since it's from server
            final noteId = await _noteDatabase.addNoteWithId(
              title,
              body: body,
              needsSync: false,
            );
            await _noteDatabase.updateSyncStatus(
              noteId,
              serverId: serverId,
              lastSyncedAt: DateTime.now(),
              needsSync: false,
            );
            print('Created new note from remote: $serverId (ID: $noteId)');
            pulledNotes++;
          }
        } else if (eventType == 'update') {
          // Find note by server ID and update it
          final existingNote = _noteDatabase.currentNotes
              .where((n) => n.serverId == serverId)
              .firstOrNull;

          if (existingNote != null) {
            // Only update if the remote version is newer
            if (existingNote.lastSyncedAt == null ||
                eventTime.isAfter(existingNote.lastSyncedAt!)) {
              await _noteDatabase.updateNoteFromSync(
                existingNote.id,
                title,
                body: body,
              );
              await _noteDatabase.updateSyncStatus(
                existingNote.id,
                lastSyncedAt: DateTime.now(),
                needsSync: false,
              );
              print('Updated existing note: $serverId');
              pulledNotes++;
            } else {
              print('Skipped outdated remote update for: $serverId');
            }
          } else {
            // If we get an update for a note we don't have, treat it as a create
            print(
              'Received update for unknown note $serverId, treating as create',
            );
            await _noteDatabase.addNote(title, body: body);
            final newNote = _noteDatabase.currentNotes.last;
            await _noteDatabase.updateSyncStatus(
              newNote.id,
              serverId: serverId,
              lastSyncedAt: DateTime.now(),
              needsSync: false,
            );
            pulledNotes++;
          }
        } else if (eventType == 'delete') {
          // Handle note deletion
          final existingNote = _noteDatabase.currentNotes
              .where((n) => n.serverId == serverId)
              .firstOrNull;

          if (existingNote != null) {
            await _noteDatabase.moveToTrash(existingNote.id);
            print('Deleted note from remote: $serverId');
            pulledNotes++;
          }
        }
      }

      print('Pulled $pulledNotes changes successfully');

      // Extract server timestamp from response for next sync
      final serverTimestamp = data['timestamp'] as String?;

      return PullResult(
        pulledNotes: pulledNotes,
        serverTimestamp: serverTimestamp,
      );
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

  // Clear sync timestamp for debugging
  Future<void> clearSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    print('Cleared sync timestamp - next sync will fetch all changes');
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
      keyFingerprint: _fingerprint,
      groupName: _groupName,
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
  final String? serverTimestamp;

  PullResult({required this.pulledNotes, this.serverTimestamp});
}

class SyncStatus {
  final bool isConfigured;
  final DateTime? lastSyncTime;
  final int pendingChanges;
  final String? serverUrl;
  final String? keyFingerprint;
  final String? groupName;

  SyncStatus({
    required this.isConfigured,
    this.lastSyncTime,
    required this.pendingChanges,
    this.serverUrl,
    this.keyFingerprint,
    this.groupName,
  });
}

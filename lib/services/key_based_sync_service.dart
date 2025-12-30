import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/services/crypto_utils.dart';
import 'package:skadoosh_app/services/storage_service.dart';
import 'package:skadoosh_app/services/image_sync_service.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

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
  final StorageService _storageService = StorageService();
  final DiffMatchPatch _dmp = DiffMatchPatch();

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

      // Step 3: Process image uploads for newly synced notes
      print('\n--- Step 3: Processing image uploads ---');
      await _processImageUploads();

      // Debug: Print queue status after processing
      final imageSyncService = ImageSyncService.instance;
      await imageSyncService.debugPrintQueueStatus();

      // Step 4: Update last sync time with server timestamp
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

  // Helper method to get effective file path (relativePath or fileName fallback)
  String? _getEffectiveFilePath(Note note) {
    return note.relativePath ?? note.fileName;
  }

  // Helper method to get shadow content from note
  String? _getShadowContent(Note note) {
    return note.getShadowContent();
  }

  // Helper method to update shadow cache for a note
  Future<void> _updateShadowCache(Note note, String content) async {
    note.updateShadowCache(content);
    note.isDirty = false;

    // Save the updated note to database
    await NoteDatabase.isar.writeTxn(() async {
      await NoteDatabase.isar.notes.put(note);
    });
    await _noteDatabase.fetchNotes(); // Refresh the notes list
  }

  // Helper method to force full sync by clearing shadow cache
  Future<void> _clearShadowCache(Note note) async {
    print('Clearing shadow cache for note ${note.id} - forcing full sync');
    note.shadowContentZLib = null;
    note.lastSyncedHash = null;

    // Save the updated note to database
    await NoteDatabase.isar.writeTxn(() async {
      await NoteDatabase.isar.notes.put(note);
    });
    await _noteDatabase.fetchNotes(); // Refresh the notes list
  }

  // Push local changes to server with differential sync
  Future<PushResult> _pushLocalChanges() async {
    final notesToSync = _noteDatabase.currentNotes
        .where((note) => note.needsSync)
        .toList();

    print('Notes to push: ${notesToSync.length}');

    if (notesToSync.isEmpty) {
      return PushResult(pushedNotes: 0);
    }

    final List<Map<String, dynamic>> notesData = [];

    for (final note in notesToSync) {
      try {
        print('🔄 Processing note ${note.id} (${note.title})');

        // Step 1: Read current content from file
        String currentContent = '';
        final effectiveFilePath = _getEffectiveFilePath(note);

        if (effectiveFilePath != null) {
          currentContent = await _storageService.readNote(effectiveFilePath);
          print(
            '📖 Read ${currentContent.length} characters from $effectiveFilePath',
          );

          // If note doesn't have relativePath but has fileName, update it
          if (note.relativePath == null && note.fileName != null) {
            note.relativePath = note.fileName;
            await NoteDatabase.isar.writeTxn(() async {
              await NoteDatabase.isar.notes.put(note);
            });
            print(
              'Updated note ${note.id} with relativePath: ${note.fileName}',
            );
          }
        } else {
          // Fallback to database content for legacy notes
          currentContent = note.body;
          print(
            '⚠️ Using legacy database content (${currentContent.length} chars)',
          );
        }

        // Step 2: Determine sync strategy
        final shadowContent = _getShadowContent(note);
        Map<String, dynamic> noteData = {
          'localId': note.id,
          'serverId': note.serverId,
          'title': note.title,
          'createdAt': note.createdAt?.toIso8601String(),
          'updatedAt': note.updatedAt?.toIso8601String(),
          'isDeleted': note.isDeleted,
          'folderPath': note.folderPath ?? '',
          'fileName': note.fileName ?? '',
          'relativePath': note.relativePath ?? '',
        };

        if (shadowContent == null || shadowContent.isEmpty) {
          // First sync or shadow cache invalid - send full content
          print('📤 Full sync for note ${note.id} (no shadow cache)');
          noteData.addAll({
            'eventType': note.serverId == null ? 'create' : 'update',
            'content': currentContent,
          });
        } else {
          // Shadow cache exists - use differential sync
          print('🔍 Differential sync for note ${note.id}');

          // Generate patches
          final patches = _dmp.patch(shadowContent, currentContent);

          if (patches.isEmpty) {
            print('⚡ No changes detected for note ${note.id} - skipping');
            continue; // No changes, skip this note
          }

          final patchText = patchToText(patches);
          print(
            '📋 Generated patch: ${patchText.substring(0, math.min(patchText.length, 100))}${patchText.length > 100 ? '...' : ''}',
          );

          noteData.addAll({'eventType': 'patch', 'patch': patchText});
        }

        notesData.add(noteData);
      } catch (e, stackTrace) {
        print('❌ Error processing note ${note.id}: $e');
        print('Stack trace: $stackTrace');

        // Force full sync for this note by clearing shadow cache
        await _clearShadowCache(note);

        // Try again with full content
        final fallbackContent = note.relativePath != null
            ? await _storageService.readNote(note.relativePath!)
            : note.body;

        notesData.add({
          'localId': note.id,
          'serverId': note.serverId,
          'title': note.title,
          'content': fallbackContent,
          'eventType': note.serverId == null ? 'create' : 'update',
          'createdAt': note.createdAt?.toIso8601String(),
          'updatedAt': note.updatedAt?.toIso8601String(),
          'isDeleted': note.isDeleted,
        });
      }
    }

    if (notesData.isEmpty) {
      print('📝 No changes to sync after processing');
      return PushResult(pushedNotes: 0);
    }

    print('📤 Pushing ${notesData.length} notes to server');

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
        try {
          final localId = result['localId'] as int;
          final note = notesToSync.firstWhere((n) => n.id == localId);

          if (result['status'] == 'created' || result['status'] == 'updated') {
            // Update shadow cache with current content
            final currentContent = note.relativePath != null
                ? await _storageService.readNote(note.relativePath!)
                : note.body;

            await _updateShadowCache(note, currentContent);

            // Update sync metadata
            await _noteDatabase.updateSyncStatus(
              note.id,
              serverId: result['serverId'],
              lastSyncedAt: DateTime.now(),
              needsSync: false,
            );

            print('✅ Successfully synced note ${note.id}');
          } else if (result['status'] == 'patch_failed' ||
              result['status'] == 'conflict') {
            // Server couldn't apply patch - force full sync next time
            print(
              '⚠️ Patch failed for note ${note.id} - clearing shadow cache',
            );
            await _clearShadowCache(note);
          }
        } catch (e) {
          print('❌ Error updating sync status for result: $result, error: $e');
        }
      }

      print('✅ Pushed ${results.length} notes successfully');
      return PushResult(pushedNotes: results.length);
    } else if (response.statusCode == 409) {
      // Conflict detected - clear shadow caches and retry with full sync
      print('⚠️ Conflict detected - clearing shadow caches for retry');
      for (final note in notesToSync) {
        await _clearShadowCache(note);
      }
      throw Exception(
        'Sync conflict detected. Shadow caches cleared. Please retry sync.',
      );
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
          // 3. Check by relativePath to prevent creating duplicate files

          var existingNote = _noteDatabase.currentNotes
              .where((n) => n.serverId == serverId)
              .firstOrNull;

          // If we already have this server ID, skip it entirely
          if (existingNote != null) {
            print(
              '✓ Note with server ID $serverId already exists (ID: ${existingNote.id}), skipping',
            );
            continue;
          }

          // If not found by server ID, check by title and timing to avoid duplicates
          // from our own local notes that were just pushed
          if (existingNote == null) {
            final recentNotes = _noteDatabase.currentNotes
                .where(
                  (n) =>
                      n.title.trim() == title.trim() && // Match title
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
            // Extract folder information from change
            final remoteFolderPath = change['folder_path'] as String? ?? '';
            final remoteFileName = change['file_name'] as String? ?? '';
            final remoteRelativePath = change['relative_path'] as String? ?? '';

            // Use remote paths if available, otherwise generate new ones
            String fileName;
            String relativePath;
            String folderPath;

            if (remoteFileName.isNotEmpty && remoteRelativePath.isNotEmpty) {
              // Use remote folder structure
              fileName = remoteFileName;
              relativePath = remoteRelativePath;
              folderPath = remoteFolderPath;
              print(
                '📁 Creating note in folder: ${folderPath.isEmpty ? '(root)' : folderPath}',
              );
            } else {
              // Generate new paths (backward compatibility)
              fileName = _storageService.sanitizeFilename(title);
              relativePath = fileName;
              folderPath = '';
            }

            // Check if a note with this relativePath already exists
            final noteWithSamePath = _noteDatabase.currentNotes
                .where((n) => n.relativePath == relativePath)
                .firstOrNull;

            if (noteWithSamePath != null) {
              // Note already exists with this path, just update server ID
              print(
                '📌 Note with path $relativePath already exists (ID: ${noteWithSamePath.id}), updating server ID',
              );
              await _noteDatabase.updateSyncStatus(
                noteWithSamePath.id,
                serverId: serverId,
                lastSyncedAt: DateTime.now(),
                needsSync: false,
              );
              pulledNotes++;
              continue;
            }

            // Create file (this will automatically create folders if needed)
            await _storageService.writeNote(relativePath, body);

            // Create note with explicit needsSync = false since it's from server
            final noteId = await _noteDatabase.addNoteWithId(
              title,
              body: '', // Content is in file, not database
              fileName: fileName,
              relativePath: relativePath,
              needsSync: false,
            );

            // Update folderPath separately since it's not in addNoteWithId params
            final createdNote = await NoteDatabase.isar.notes.get(noteId);
            if (createdNote != null) {
              createdNote.folderPath = folderPath;
              await NoteDatabase.isar.writeTxn(() async {
                await NoteDatabase.isar.notes.put(createdNote);
              });
            }

            await _noteDatabase.updateSyncStatus(
              noteId,
              serverId: serverId,
              lastSyncedAt: DateTime.now(),
              needsSync: false,
            );
            print(
              'Created new note from remote: $serverId (ID: $noteId) with path: $relativePath',
            );
            pulledNotes++;
          }
        } else if (eventType == 'patch') {
          // Handle differential patch from server
          final existingNote = _noteDatabase.currentNotes
              .where((n) => n.serverId == serverId)
              .firstOrNull;

          if (existingNote != null) {
            final effectiveFilePath = _getEffectiveFilePath(existingNote);

            if (effectiveFilePath != null) {
              try {
                print('🔄 Applying patch to note ${existingNote.id}');

                // Read current file content
                final currentContent = await _storageService.readNote(
                  effectiveFilePath,
                );

                // Parse and apply patches
                final patchText = change['patch'] as String;
                final patches = patchFromText(patchText);
                final results = patchApply(
                  patches,
                  currentContent,
                  deleteThreshold: _dmp.patchDeleteThreshold,
                  margin: _dmp.patchMargin,
                  diffTimeout: _dmp.diffTimeout,
                  matchThreshold: _dmp.matchThreshold,
                  matchDistance: _dmp.matchDistance,
                );

                if (results.length >= 2) {
                  final newContent = results[0] as String;
                  final successList = results[1] as List<bool>;

                  if (successList.every((success) => success)) {
                    // All patches applied successfully
                    print(
                      '✅ Patch applied successfully to note ${existingNote.id}',
                    );

                    // Update file with new content using effective file path
                    await _storageService.writeNote(
                      effectiveFilePath,
                      newContent,
                    );

                    // Update shadow cache
                    await _updateShadowCache(existingNote, newContent);

                    // Update sync metadata
                    await _noteDatabase.updateSyncStatus(
                      existingNote.id,
                      lastSyncedAt: DateTime.now(),
                      needsSync: false,
                    );

                    pulledNotes++;
                  } else {
                    // Some patches failed - request full content
                    print(
                      '❌ Patch application failed for note ${existingNote.id} - requesting full sync',
                    );
                    await _clearShadowCache(existingNote);
                    // Note will be re-synced with full content on next sync
                  }
                } else {
                  print('❌ Invalid patch result for note ${existingNote.id}');
                  await _clearShadowCache(existingNote);
                }
              } catch (e) {
                print('❌ Error applying patch to note ${existingNote.id}: $e');
                await _clearShadowCache(existingNote);
                // Fallback: force full content sync
              }
            } else {
              print(
                '⚠️ Received patch for note ${existingNote.id} but no file path available',
              );
              await _clearShadowCache(existingNote);
            }
          } else {
            print('⚠️ Received patch for unknown note $serverId');
            // Can't apply patch to non-existent note
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
              // Extract folder information from change
              final remoteFolderPath = change['folder_path'] as String? ?? '';
              final remoteFileName = change['file_name'] as String? ?? '';
              final remoteRelativePath =
                  change['relative_path'] as String? ?? '';

              // Determine if folder structure changed
              final oldRelativePath = existingNote.relativePath;
              String newRelativePath;

              if (remoteRelativePath.isNotEmpty) {
                newRelativePath = remoteRelativePath;
              } else if (existingNote.relativePath != null) {
                newRelativePath = existingNote.relativePath!;
              } else {
                // Legacy note - generate new path
                newRelativePath = _storageService.sanitizeFilename(title);
              }

              // If path changed, move the file
              if (oldRelativePath != null &&
                  oldRelativePath != newRelativePath) {
                print(
                  '📁 Moving note from $oldRelativePath to $newRelativePath',
                );
                // Read old content
                final oldContent = await _storageService.readNote(
                  oldRelativePath,
                );
                // Write to new location
                await _storageService.writeNote(newRelativePath, body);
                // Delete old file
                await _storageService.deleteNote(oldRelativePath);
              } else {
                // Update in current location
                await _storageService.writeNote(newRelativePath, body);
              }

              // Update note metadata including folder path
              existingNote.relativePath = newRelativePath;
              existingNote.fileName = remoteFileName.isNotEmpty
                  ? remoteFileName
                  : existingNote.fileName;
              existingNote.folderPath = remoteFolderPath;

              await _noteDatabase.updateNoteFromSync(
                existingNote.id,
                title,
                body: '', // Content is in file, not database
              );

              // Save folder path change
              await NoteDatabase.isar.writeTxn(() async {
                await NoteDatabase.isar.notes.put(existingNote);
              });

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

            // Create file for the note content
            final fileName = _storageService.sanitizeFilename(title);
            await _storageService.writeNote(fileName, body);

            await _noteDatabase.addNote(
              title,
              body: '', // Content is in file, not database
              fileName: fileName,
              relativePath: fileName, // CRITICAL FIX: Set relativePath!
            );
            final newNote = _noteDatabase.currentNotes.last;
            await _noteDatabase.updateSyncStatus(
              newNote.id,
              serverId: serverId,
              lastSyncedAt: DateTime.now(),
              needsSync: false,
            );
            print(
              'Created note from unknown update: $serverId with file: $fileName',
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

  // Process image uploads after sync
  Future<void> _processImageUploads() async {
    try {
      // Initialize and process image uploads
      final imageSyncService = ImageSyncService.instance;
      await imageSyncService.initialize();

      // First, scan all notes for any local images that might not be queued yet
      // autoProcess=false to prevent background processing during sync
      print('🔍 Scanning all notes for local images...');
      for (final note in _noteDatabase.currentNotes) {
        await imageSyncService.scanAndQueueLocalImagesInNote(
          note,
          autoProcess: false,
        );
      }

      // Update server IDs for pending uploads
      await imageSyncService.updateServerIdsForPendingUploads();

      // Process ALL uploads and wait for completion
      // This ensures all images are uploaded before sync completes
      final processedCount = await imageSyncService.processAllUploads();

      print('📸 Processed $processedCount image uploads after sync');

      // Clean up old completed uploads
      await imageSyncService.cleanupCompletedUploads();
    } catch (e) {
      print('❌ Error processing image uploads: $e');
      // Don't fail the entire sync if image processing fails
    }
  }

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

  // Clear all shadow caches to force full sync (recovery method)
  Future<void> clearAllShadowCaches() async {
    print('🧹 Clearing all shadow caches to force full sync...');

    for (final note in _noteDatabase.currentNotes) {
      if (note.shadowContentZLib != null || note.lastSyncedHash != null) {
        await _clearShadowCache(note);
        print('Cleared shadow cache for note ${note.id} (${note.title})');
      }
    }

    print('✅ All shadow caches cleared. Next sync will send full content.');
  }

  // Validate and repair sync state (diagnostic method)
  Future<Map<String, dynamic>> validateSyncState() async {
    print('🔍 Validating sync state...');

    int notesWithFiles = 0;
    int notesWithShadowCache = 0;
    int notesNeedingSync = 0;
    int orphanedFiles = 0;
    List<String> issues = [];

    for (final note in _noteDatabase.currentNotes) {
      // Check if note has a file path
      if (note.relativePath != null) {
        notesWithFiles++;

        // Check if file actually exists
        final fileExists = await _storageService.fileExists(note.relativePath!);
        if (!fileExists) {
          issues.add(
            'Note ${note.id} (${note.title}) references missing file: ${note.relativePath}',
          );
        }
      }

      // Check shadow cache state
      if (note.shadowContentZLib != null || note.lastSyncedHash != null) {
        notesWithShadowCache++;
      }

      // Check sync status
      if (note.needsSync || note.isDirty) {
        notesNeedingSync++;
      }
    }

    final result = {
      'totalNotes': _noteDatabase.currentNotes.length,
      'notesWithFiles': notesWithFiles,
      'notesWithShadowCache': notesWithShadowCache,
      'notesNeedingSync': notesNeedingSync,
      'orphanedFiles': orphanedFiles,
      'issues': issues,
      'isHealthy': issues.isEmpty,
    };

    print('📊 Sync state validation complete: $result');
    return result;
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

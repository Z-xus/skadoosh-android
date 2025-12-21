import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

// TODO: make the data into app storage.
class NoteDatabase extends ChangeNotifier {
  // init
  static late Isar isar;
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    print('📂 Isar database initialized at: ${dir.path}');
    isar = await Isar.open([NoteSchema], directory: dir.path);
  }

  final List<Note> currentNotes = [];

  // Get device ID for sync
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'ios_${iosInfo.identifierForVendor}';
      }
    } catch (e) {
      // Fallback
    }
    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }

  // create note with title and body
  Future<void> addNote(
    String title, {
    String body = '',
    String? fileName,
    String? relativePath,
  }) async {
    final deviceId = await _getDeviceId();
    final now = DateTime.now();

    final newNote = Note()
      ..title = title.isNotEmpty ? title : 'Untitled'
      ..body = body
      ..fileName = fileName
      ..relativePath =
          relativePath ??
          fileName // Set relativePath, fallback to fileName
      ..deviceId = deviceId
      ..createdAt = now
      ..updatedAt = now
      ..needsSync = true
      ..isDeleted = false;

    await isar.writeTxn(() async {
      await isar.notes.put(newNote);
    });

    print(
      '💾 Note stored - Title: "${newNote.title}", Database ID: ${newNote.id}, RelativePath: "${newNote.relativePath}"',
    );
    fetchNotes();
  }

  // Add note and return its ID for sync purposes
  Future<int> addNoteWithId(
    String title, {
    String body = '',
    String? fileName,
    String? relativePath,
    bool needsSync = true,
  }) async {
    final deviceId = await _getDeviceId();
    final now = DateTime.now();

    final newNote = Note()
      ..title = title.isNotEmpty ? title : 'Untitled'
      ..body = body
      ..fileName = fileName
      ..relativePath =
          relativePath ??
          fileName // Set relativePath, fallback to fileName
      ..deviceId = deviceId
      ..createdAt = now
      ..updatedAt = now
      ..needsSync = needsSync
      ..isDeleted = false;

    await isar.writeTxn(() async {
      await isar.notes.put(newNote);
    });

    print(
      '💾 Note stored - Title: "${newNote.title}", Database ID: ${newNote.id}, RelativePath: "${newNote.relativePath}"',
    );
    fetchNotes();
    return newNote.id;
  }

  // read - fetch all notes for now, will filter in UI
  Future<void> fetchNotes() async {
    List<Note> fetchNotes = await isar.notes.where().findAll();
    currentNotes.clear();
    // Filter out deleted notes in the app logic for now
    currentNotes.addAll(fetchNotes.where((note) => !note.isDeleted));
    notifyListeners();
  }

  // get all notes including deleted
  Future<List<Note>> getAllNotes() async {
    return await isar.notes.where().findAll();
  }

  // get trash notes (deleted but not permanently)
  Future<List<Note>> getTrashNotes() async {
    final allNotes = await isar.notes.where().findAll();
    return allNotes
        .where((note) => note.isDeleted && !note.shouldPermanentlyDelete)
        .toList();
  }

  // update note with title and body
  Future<void> updateNote(
    int id,
    String title, {
    String? body,
    String? fileName,
    String? relativePath,
  }) async {
    final existingNote = await isar.notes.get(id);
    if (existingNote != null && !existingNote.isDeleted) {
      existingNote.title = title.isNotEmpty ? title : 'Untitled';
      if (body != null) existingNote.body = body;
      if (fileName != null) existingNote.fileName = fileName;
      if (relativePath != null) existingNote.relativePath = relativePath;
      // If relativePath is not provided but fileName is, update relativePath too
      if (relativePath == null && fileName != null) {
        existingNote.relativePath = fileName;
      }
      existingNote.updatedAt = DateTime.now();
      existingNote.needsSync = true;

      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      await fetchNotes();
    }
  }

  // Update note from sync without marking as needing sync again
  Future<void> updateNoteFromSync(int id, String title, {String? body}) async {
    final existingNote = await isar.notes.get(id);
    if (existingNote != null && !existingNote.isDeleted) {
      existingNote.title = title.isNotEmpty ? title : 'Untitled';
      if (body != null) existingNote.body = body;
      existingNote.updatedAt = DateTime.now();
      existingNote.needsSync = true;

      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      print(
        '🔄 Note updated - Title: "${existingNote.title}", Database ID: ${existingNote.id}',
      );
      await fetchNotes();
    }
  }

  // move to trash (soft delete)
  Future<void> moveToTrash(int id) async {
    final existingNote = await isar.notes.get(id);
    if (existingNote != null) {
      existingNote.isDeleted = true;
      existingNote.deletedAt = DateTime.now();
      existingNote.updatedAt = DateTime.now();
      existingNote.needsSync = true;

      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      await fetchNotes();
    }
  }

  // restore from trash
  Future<void> restoreFromTrash(int id) async {
    final existingNote = await isar.notes.get(id);
    if (existingNote != null && existingNote.isDeleted) {
      existingNote.isDeleted = false;
      existingNote.deletedAt = null;
      existingNote.updatedAt = DateTime.now();
      existingNote.needsSync = true;

      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      await fetchNotes();
    }
  }

  // permanently delete note (hard delete)
  Future<void> permanentlyDeleteNote(int id) async {
    await isar.writeTxn(() async {
      await isar.notes.delete(id);
    });
    await fetchNotes();
  }

  // clean up old trash (30+ days)
  Future<void> cleanUpOldTrash() async {
    final trashNotes = await getTrashNotes();
    final notesToDelete = trashNotes
        .where((note) => note.shouldPermanentlyDelete)
        .toList();

    for (final note in notesToDelete) {
      await permanentlyDeleteNote(note.id);
    }
  }

  // update sync status
  Future<void> updateSyncStatus(
    int id, {
    String? serverId,
    DateTime? lastSyncedAt,
    bool? needsSync,
  }) async {
    final existingNote = await isar.notes.get(id);
    if (existingNote != null) {
      if (serverId != null) existingNote.serverId = serverId;
      if (lastSyncedAt != null) existingNote.lastSyncedAt = lastSyncedAt;
      if (needsSync != null) existingNote.needsSync = needsSync;

      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      await fetchNotes();
    }
  }

  // delete
  Future<void> deleteNote(int id) async {
    await isar.writeTxn(() async {
      await isar.notes.delete(id);
    });
    await fetchNotes();
  }

  // Get notes that need syncing
  List<Note> get notesNeedingSync {
    return currentNotes.where((note) => note.needsSync).toList();
  }

  // Mark all notes as synced
  Future<void> markAllSynced() async {
    await isar.writeTxn(() async {
      for (final note in currentNotes) {
        if (note.needsSync) {
          note.needsSync = false;
          note.lastSyncedAt = DateTime.now();
          await isar.notes.put(note);
        }
      }
    });
    await fetchNotes();
  }
}

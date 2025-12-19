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

  // create
  Future<void> addNote(String text) async {
    final deviceId = await _getDeviceId();
    final now = DateTime.now();

    final newNote = Note()
      ..title = text
      ..deviceId = deviceId
      ..createdAt = now
      ..updatedAt = now
      ..needsSync = true;

    await isar.writeTxn(() async {
      await isar.notes.put(newNote);
    });

    fetchNotes();
  }

  // read
  Future<void> fetchNotes() async {
    List<Note> fetchNotes = await isar.notes.where().findAll();
    currentNotes.clear();
    currentNotes.addAll(fetchNotes);
    notifyListeners();
  }

  // update
  Future<void> updateNote(int id, String newText) async {
    final existingNote = await isar.notes.get(id);
    if (existingNote != null) {
      existingNote.title = newText;
      existingNote.updatedAt = DateTime.now();
      existingNote.needsSync = true;

      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      await fetchNotes();
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

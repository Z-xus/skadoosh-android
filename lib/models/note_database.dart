import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skadoosh_app/services/widget_service.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/models/habit.dart';
import 'package:skadoosh_app/models/pending_image_upload.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class NoteDatabase extends ChangeNotifier {
  static late Isar isar;
  static bool _isInitialized = false;
  static Future<void>? _initializationFuture;

  // I. INITIALIZE DATABASE
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // If initialization is already in progress, wait for it
    if (_initializationFuture != null) {
      await _initializationFuture;
      return;
    }

    _initializationFuture = _doInitialize();
    await _initializationFuture;
  }

  static Future<void> _doInitialize() async {
    final dir = await getApplicationDocumentsDirectory();
    print('📂 Isar database initialized at: ${dir.path}');
    // ADDED TodoSchema HERE
    isar = await Isar.open([
      NoteSchema,
      HabitSchema,
      TodoSchema,
      PendingImageUploadSchema,
    ], directory: dir.path);
    _isInitialized = true;
    print('✅ Isar database ready');
  }

  final List<Note> currentNotes = [];
  final List<Habit> currentHabits = [];
  final List<Todo> currentTodos = []; // New List for UI

  // ===========================================================================
  // EXISTING NOTE & SYNC LOGIC (KEPT EXACTLY AS IS)
  // ===========================================================================

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
    } catch (e) {}
    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }

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
      ..relativePath = relativePath ?? fileName
      ..folderPath =
          '' // Explicitly set to empty string for root folder
      ..deviceId = deviceId
      ..createdAt = now
      ..updatedAt = now
      ..needsSync = true
      ..isDeleted = false
      ..isArchived = false;
    await isar.writeTxn(() async {
      await isar.notes.put(newNote);
    });
    fetchNotes();
  }

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
      ..relativePath = relativePath ?? fileName
      ..deviceId = deviceId
      ..createdAt = now
      ..updatedAt = now
      ..needsSync = needsSync
      ..isDeleted = false
      ..isArchived = false;
    await isar.writeTxn(() async {
      await isar.notes.put(newNote);
    });
    fetchNotes();
    return newNote.id;
  }

  Future<void> fetchNotes() async {
    // Wait for database initialization if not ready
    if (!_isInitialized) {
      print('⏳ Waiting for database initialization...');
      await initialize();
    }

    List<Note> fetchNotes = await isar.notes.where().findAll();
    currentNotes.clear();
    currentNotes.addAll(
      fetchNotes.where((note) => !note.isDeleted && !note.isArchived),
    );
    print('📚 Loaded ${currentNotes.length} notes from database');
    notifyListeners();
  }

  Future<List<Note>> getAllNotes() async {
    if (!_isInitialized) await initialize();
    return await isar.notes.where().findAll();
  }

  Future<List<Note>> getTrashNotes() async {
    if (!_isInitialized) await initialize();
    final allNotes = await isar.notes.where().findAll();
    return allNotes
        .where((note) => note.isDeleted && !note.shouldPermanentlyDelete)
        .toList();
  }

  Future<List<Note>> getArchivedNotes() async {
    if (!_isInitialized) await initialize();
    final allNotes = await isar.notes.where().findAll();
    return allNotes
        .where((note) => note.isArchived && !note.isDeleted)
        .toList();
  }

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
      if (relativePath == null && fileName != null)
        existingNote.relativePath = fileName;
      existingNote.updatedAt = DateTime.now();
      existingNote.needsSync = true;
      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      await fetchNotes();
    }
  }

  Future<void> archiveNote(int id) async {
    final existingNote = await isar.notes.get(id);
    if (existingNote != null &&
        !existingNote.isDeleted &&
        !existingNote.isArchived) {
      existingNote.isArchived = true;
      existingNote.archivedAt = DateTime.now();
      existingNote.updatedAt = DateTime.now();
      existingNote.needsSync = true;
      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      await fetchNotes();
    }
  }

  Future<void> unarchiveNote(int id) async {
    final existingNote = await isar.notes.get(id);
    if (existingNote != null &&
        existingNote.isArchived &&
        !existingNote.isDeleted) {
      existingNote.isArchived = false;
      existingNote.archivedAt = null;
      existingNote.updatedAt = DateTime.now();
      existingNote.needsSync = true;
      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      await fetchNotes();
    }
  }

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
      await fetchNotes();
    }
  }

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

  Future<void> permanentlyDeleteNote(int id) async {
    await isar.writeTxn(() async {
      await isar.notes.delete(id);
    });
    await fetchNotes();
  }

  Future<void> cleanUpOldTrash() async {
    final trashNotes = await getTrashNotes();
    final notesToDelete = trashNotes
        .where((note) => note.shouldPermanentlyDelete)
        .toList();
    for (final note in notesToDelete) {
      await permanentlyDeleteNote(note.id);
    }
  }

  Future<void> updateSyncStatus(
    int id, {
    String? serverId,
    DateTime? lastSyncedAt,
    bool? needsSync,
    List<String>? imageUrls,
    List<String>? localImagePaths,
    bool? hasImages,
  }) async {
    final existingNote = await isar.notes.get(id);
    if (existingNote != null) {
      if (serverId != null) existingNote.serverId = serverId;
      if (lastSyncedAt != null) existingNote.lastSyncedAt = lastSyncedAt;
      if (needsSync != null) existingNote.needsSync = needsSync;
      if (imageUrls != null) existingNote.imageUrls = imageUrls;
      if (localImagePaths != null)
        existingNote.localImagePaths = localImagePaths;
      if (hasImages != null) existingNote.hasImages = hasImages;
      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      await fetchNotes();
    }
  }

  Future<void> deleteNote(int id) async {
    await isar.writeTxn(() async {
      await isar.notes.delete(id);
    });
    await fetchNotes();
  }

  List<Note> get notesNeedingSync =>
      currentNotes.where((note) => note.needsSync).toList();

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

  // ===========================================================================
  // FOLDER SUPPORT METHODS
  // ===========================================================================

  Future<void> addNoteToFolder(
    String title,
    String folderPath, {
    String body = '',
    String? fileName,
  }) async {
    final deviceId = await _getDeviceId();
    final now = DateTime.now();

    // Create filename if not provided
    final noteFileName =
        fileName ?? '${title.isNotEmpty ? title : 'Untitled'}.md';
    final fullPath = folderPath.isEmpty
        ? noteFileName
        : '$folderPath/$noteFileName';

    final newNote = Note()
      ..title = title.isNotEmpty ? title : 'Untitled'
      ..body = body
      ..fileName = noteFileName
      ..relativePath = fullPath
      ..folderPath = folderPath
      ..deviceId = deviceId
      ..createdAt = now
      ..updatedAt = now
      ..needsSync = true
      ..isDeleted = false
      ..isArchived = false;

    await isar.writeTxn(() async {
      await isar.notes.put(newNote);
    });
    fetchNotes();
  }

  Future<void> moveNoteToFolder(int noteId, String newFolderPath) async {
    final existingNote = await isar.notes.get(noteId);
    if (existingNote != null && !existingNote.isDeleted) {
      final fileName = existingNote.fileName ?? '${existingNote.title}.md';
      final newFullPath = newFolderPath.isEmpty
          ? fileName
          : '$newFolderPath/$fileName';

      existingNote.folderPath = newFolderPath;
      existingNote.relativePath = newFullPath;
      existingNote.updatedAt = DateTime.now();
      existingNote.needsSync = true;

      await isar.writeTxn(() async {
        await isar.notes.put(existingNote);
      });
      await fetchNotes();
    }
  }

  Future<List<Note>> getNotesInFolder(String folderPath) async {
    final allNotes = await isar.notes.where().findAll();
    return allNotes
        .where(
          (note) =>
              !note.isDeleted &&
              !note.isArchived &&
              (note.folderPath ?? '') == folderPath,
        )
        .toList();
  }

  Future<List<String>> getAllFolderPaths() async {
    final allNotes = await isar.notes.where().findAll();
    final folderPaths = allNotes
        .where((note) => !note.isDeleted && !note.isArchived)
        .map((note) => note.folderPath ?? '')
        .toSet()
        .toList();
    return folderPaths..sort();
  }

  Future<bool> isFolderEmpty(String folderPath) async {
    final notesInFolder = await getNotesInFolder(folderPath);
    return notesInFolder.isEmpty;
  }

  // ===========================================================================
  // HABIT LOGIC (CYCLIC)
  // ===========================================================================

  Future<void> addHabit(String title, {int initialGoal = 7}) async {
    final newHabit = Habit()
      ..title = title.isNotEmpty ? title : 'Untitled'
      ..goalDays = initialGoal
      ..currentProgress = 0
      ..totalLifetimeCompletions = 0
      ..category = HabitCategory.other;
    await isar.writeTxn(() => isar.habits.put(newHabit));
    await fetchHabits();
    // Update widgets after adding habit
    await WidgetService.updateHabitWidget();
  }

  Future<void> fetchHabits() async {
    // Wait for database initialization if not ready
    if (!_isInitialized) {
      await initialize();
    }

    List<Habit> fetchedHabits = await isar.habits.where().findAll();
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);
    notifyListeners();
  }

  Future<Habit?> getHabitById(int id) async => await isar.habits.get(id);

  Future<void> checkHabitCompletion(int id, bool isCompleted) async {
    final habit = await isar.habits.get(id);
    if (habit != null) {
      final today = DateTime.now();
      final normalizedToday = DateTime(
        today.year,
        today.month,
        today.day,
      ).millisecondsSinceEpoch;

      await isar.writeTxn(() async {
        if (isCompleted) {
          final currentList = List<int>.from(habit.completionDatesTimestamps);
          if (!currentList.contains(normalizedToday)) {
            currentList.add(normalizedToday);
            habit.completionDatesTimestamps = currentList;
            habit.currentProgress++;
            habit.totalLifetimeCompletions++;
            if (habit.currentProgress >= habit.goalDays)
              habit.isCycleFinished = true;
          }
        } else {
          final currentList = List<int>.from(habit.completionDatesTimestamps);
          if (currentList.remove(normalizedToday)) {
            habit.completionDatesTimestamps = currentList;
            if (habit.currentProgress > 0) habit.currentProgress--;
            if (habit.totalLifetimeCompletions > 0)
              habit.totalLifetimeCompletions--;
            habit.isCycleFinished = false;
          }
        }
        await isar.habits.put(habit);
      });
      await fetchHabits();
      // Update widgets after checking habit completion
      await WidgetService.updateHabitWidget();
    }
  }

  Future<void> evolveHabit(int id) async {
    final habit = await isar.habits.get(id);
    if (habit != null) {
      await isar.writeTxn(() async {
        habit.currentProgress = 0;
        habit.isCycleFinished = false;
        if (habit.goalDays < 21)
          habit.goalDays += 7;
        else
          habit.goalDays += 10;
        await isar.habits.put(habit);
      });
      await fetchHabits();
    }
  }

  Future<void> deleteHabit(int id) async {
    await isar.writeTxn(() => isar.habits.delete(id));
    await fetchHabits();
  }

  // ===========================================================================
  // TODO LOGIC (NEW)
  // ===========================================================================

  Future<void> fetchTodos() async {
    // Fetch all, sort by incomplete first
    List<Todo> fetched = await isar.todos
        .where()
        .sortByCreatedAtDesc()
        .findAll();

    // Sort logic: Incomplete on top, completed at bottom
    fetched.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      return a.isCompleted ? 1 : -1;
    });

    currentTodos.clear();
    currentTodos.addAll(fetched);
    notifyListeners();
  }

  Future<void> addTodo(String title) async {
    final newTodo = Todo()
      ..title = title
      ..isCompleted = false
      ..createdAt = DateTime.now();

    await isar.writeTxn(() => isar.todos.put(newTodo));
    await fetchTodos();
    // Update widgets after adding task
    await WidgetService.updateTaskWidget();
  }

  Future<void> toggleTodo(int id) async {
    final todo = await isar.todos.get(id);
    if (todo != null) {
      await isar.writeTxn(() async {
        todo.isCompleted = !todo.isCompleted;
        await isar.todos.put(todo);
      });
      await fetchTodos();
      // Update widgets after toggling task
      await WidgetService.updateTaskWidget();
    }
  }

  Future<Todo?> getTodoById(int id) async => await isar.todos.get(id);

  Future<void> deleteTodo(int id) async {
    await isar.writeTxn(() => isar.todos.delete(id));
    await fetchTodos();
  }
}

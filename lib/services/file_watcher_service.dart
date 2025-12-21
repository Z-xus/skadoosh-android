import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/models/note_database.dart';

class FileWatcherService {
  static final FileWatcherService _instance = FileWatcherService._internal();
  factory FileWatcherService() => _instance;
  FileWatcherService._internal();

  DirectoryWatcher? _watcher;
  StreamSubscription? _subscription;
  String? _watchedDirectory;
  bool _isInitialized = false;
  Timer? _debounceTimer;

  /// Initialize the file watcher service for the given directory
  Future<void> init(String directoryPath) async {
    if (_isInitialized) {
      print('📁 FileWatcherService already initialized');
      return;
    }

    try {
      _watchedDirectory = directoryPath;

      // Ensure directory exists
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        print('⚠️ Directory does not exist: $directoryPath');
        return;
      }

      _watcher = DirectoryWatcher(directoryPath);
      _subscription = _watcher!.events.listen(
        _onFileEvent,
        onError: (error) {
          print('❌ FileWatcher error: $error');
        },
        onDone: () {
          print('📁 FileWatcher stream closed');
        },
      );

      _isInitialized = true;
      print('👀 FileWatcherService initialized for: $directoryPath');
    } catch (e) {
      print('❌ Failed to initialize FileWatcherService: $e');
      _isInitialized = false;
    }
  }

  /// Handle file system events
  void _onFileEvent(WatchEvent event) {
    // Only process .md files
    if (!event.path.endsWith('.md')) return;

    // Debounce rapid file changes (wait 500ms after last change)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _processFileChange(event);
    });
  }

  /// Process the file change after debouncing
  Future<void> _processFileChange(WatchEvent event) async {
    try {
      final fileName = p.basename(event.path);

      print('📝 File ${event.type} detected: $fileName');

      switch (event.type) {
        case ChangeType.MODIFY:
          await _handleFileModified(fileName, event.path);
          break;
        case ChangeType.ADD:
          await _handleFileAdded(fileName, event.path);
          break;
        case ChangeType.REMOVE:
          await _handleFileRemoved(fileName);
          break;
      }
    } catch (e) {
      print('❌ Error processing file change: $e');
    }
  }

  /// Find a note by relativePath (manual search for now)
  Future<Note?> _findNoteByRelativePath(String fileName) async {
    try {
      // Use the database instance to get all notes (this works around findAll issue)
      final db = NoteDatabase();
      await db.fetchNotes(); // Ensure notes are loaded

      // Search in currentNotes list
      for (final note in db.currentNotes) {
        if (note.relativePath == fileName) {
          return note;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error finding note by relativePath: $e');
      return null;
    }
  }

  /// Handle file modification
  Future<void> _handleFileModified(String fileName, String filePath) async {
    try {
      // Find the note in Isar by relativePath
      final note = await _findNoteByRelativePath(fileName);

      if (note == null) {
        print('⚠️ Note not found in database for file: $fileName');
        // TODO: Consider auto-creating note entry for orphaned files
        return;
      }

      // Read current file content
      final file = File(filePath);
      if (!await file.exists()) {
        print('⚠️ File no longer exists: $filePath');
        return;
      }

      final currentContent = await file.readAsString();

      // Calculate current content hash
      final currentHash = sha256
          .convert(utf8.encode(currentContent))
          .toString();

      print('🔍 Checking file changes for: ${note.title}');
      print('   Current hash: ${currentHash.substring(0, 8)}...');
      print(
        '   Last synced: ${note.lastSyncedHash?.substring(0, 8) ?? 'none'}...',
      );

      // Compare with last synced hash
      bool wasClean = !note.isDirty;
      if (currentHash != note.lastSyncedHash) {
        // File has changed since last sync
        note.isDirty = true;
        if (wasClean) {
          print('🔄 File marked as DIRTY: ${note.title}');
        }
      } else {
        // File matches last synced version
        note.isDirty = false;
        if (!wasClean) {
          print('✅ File marked as CLEAN: ${note.title}');
        }
      }

      // Update timestamp and save
      note.updatedAt = DateTime.now();

      await NoteDatabase.isar.writeTxn(() async {
        await NoteDatabase.isar.notes.put(note);
      });
    } catch (e) {
      print('❌ Error handling file modification: $e');
    }
  }

  /// Handle file addition (new file created externally)
  Future<void> _handleFileAdded(String fileName, String filePath) async {
    try {
      print('➕ New file detected: $fileName');

      // Check if note already exists in database
      final existingNote = await _findNoteByRelativePath(fileName);

      if (existingNote != null) {
        print('📝 Note already exists in database, treating as modification');
        await _handleFileModified(fileName, filePath);
        return;
      }

      // TODO: Optionally create a new Note entry for externally created files
      print(
        'ℹ️ External file creation detected but not auto-importing: $fileName',
      );
    } catch (e) {
      print('❌ Error handling file addition: $e');
    }
  }

  /// Handle file removal
  Future<void> _handleFileRemoved(String fileName) async {
    try {
      print('🗑️ File deletion detected: $fileName');

      // Find the note in Isar
      final note = await _findNoteByRelativePath(fileName);

      if (note == null) {
        print('⚠️ Note not found in database for deleted file: $fileName');
        return;
      }

      // Mark the note as dirty since the file was externally deleted
      note.isDirty = true;
      note.updatedAt = DateTime.now();

      await NoteDatabase.isar.writeTxn(() async {
        await NoteDatabase.isar.notes.put(note);
      });

      print('🔄 Note marked as DIRTY due to file deletion: ${note.title}');

      // TODO: Consider additional strategies:
      // - Mark as isDeleted = true
      // - Keep in database but flag as "file missing"
      // - Show user notification about external deletion
    } catch (e) {
      print('❌ Error handling file removal: $e');
    }
  }

  /// Stop watching and clean up resources
  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    _watcher = null;
    _isInitialized = false;
    print('🛑 FileWatcherService disposed');
  }

  /// Get current status
  bool get isInitialized => _isInitialized;
  String? get watchedDirectory => _watchedDirectory;
}

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Directory _baseDir;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    final appDocsDir = await getApplicationDocumentsDirectory();
    _baseDir = Directory(p.join(appDocsDir.path, 'Skadoosh'));

    if (!await _baseDir.exists()) {
      await _baseDir.create(recursive: true);
      print('📁 Created Skadoosh storage directory at: ${_baseDir.path}');
    } else {
      print(
        '📁 Using existing Skadoosh storage directory at: ${_baseDir.path}',
      );
    }

    _initialized = true;
  }

  String sanitizeFilename(String title) {
    // Remove special characters and replace spaces with underscores
    String sanitized = title.replaceAll(RegExp(r'[^\w\s-]'), '');
    sanitized = sanitized.trim().replaceAll(RegExp(r'\s+'), '_');

    if (sanitized.isEmpty) {
      sanitized = 'Untitled';
    }

    // Add unique part if needed or just .md
    return '$sanitized.md';
  }

  Future<File> writeNote(String filename, String content) async {
    await init();
    final file = File(p.join(_baseDir.path, filename));
    final result = await file.writeAsString(content);
    print('📝 Note file saved: ${file.path}');
    return result;
  }

  Future<String> readNote(String filename) async {
    await init();
    final file = File(p.join(_baseDir.path, filename));
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  }

  Future<void> deleteNote(String filename) async {
    await init();
    final file = File(p.join(_baseDir.path, filename));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> fileExists(String filename) async {
    await init();
    final file = File(p.join(_baseDir.path, filename));
    return await file.exists();
  }

  /// Get the base directory path for file watching
  String get baseDirectoryPath {
    if (!_initialized) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _baseDir.path;
  }
}

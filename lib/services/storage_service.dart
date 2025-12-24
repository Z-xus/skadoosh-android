import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Directory _baseDir;
  bool _initialized = false;

  // Simple in-memory cache for file operations
  List<String>? _cachedFileList;
  DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(seconds: 30);

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

    // Handle folder creation if filename contains path separators
    final fullPath = p.join(_baseDir.path, filename);
    final file = File(fullPath);

    // Create parent directories if they don't exist
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
      print('📁 Created folder structure: ${parentDir.path}');
    }

    final result = await file.writeAsString(content);
    print('📝 Note file saved: ${file.path}');

    // Invalidate cache after write
    _invalidateCache();

    return result;
  }

  /// Get cached file list to reduce I/O operations
  Future<List<String>> getCachedFileList() async {
    await init();

    // Check if cache is valid
    if (_cachedFileList != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry) {
      return _cachedFileList!;
    }

    // Refresh cache
    final files = await _baseDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.md'))
        .map((entity) => p.basename(entity.path))
        .toList();

    _cachedFileList = files;
    _cacheTimestamp = DateTime.now();

    return files;
  }

  /// Invalidate the file cache
  void _invalidateCache() {
    _cachedFileList = null;
    _cacheTimestamp = null;
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
      // Invalidate cache after delete
      _invalidateCache();
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

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Directory _baseDir;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Request permission first
    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    // Get the public Documents directory
    String documentsPath;
    if (Platform.isAndroid) {
      // Use the standard Android public Documents path
      documentsPath = '/storage/emulated/0/Documents';
    } else {
      // For iOS, fallback to app documents (iOS doesn't have public documents concept)
      documentsPath = '/var/mobile/Documents'; // This is just a fallback
    }

    _baseDir = Directory(p.join(documentsPath, 'Skadoosh'));

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

  Future<bool> requestPermission() async {
    // For Android 11+ (API 30+), use MANAGE_EXTERNAL_STORAGE
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        // Android 11+ - request MANAGE_EXTERNAL_STORAGE
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        return status.isGranted;
      } else {
        // Android 10 and below - use regular storage permission
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    }

    // iOS doesn't need external storage permissions for Documents
    return true;
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
}

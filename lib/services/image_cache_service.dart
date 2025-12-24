import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ImageCacheService {
  static ImageCacheService? _instance;
  static ImageCacheService get instance => _instance ??= ImageCacheService._();

  ImageCacheService._();

  Directory? _cacheDir;

  // Initialize the cache directory
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'image_cache'));

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }

    print('📁 Image cache initialized at: ${_cacheDir!.path}');
  }

  // Generate cache key from URL
  String _generateCacheKey(String imageUrl) {
    final bytes = utf8.encode(imageUrl);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Get cached image file path
  String _getCacheFilePath(String imageUrl) {
    final cacheKey = _generateCacheKey(imageUrl);
    final extension = _getFileExtension(imageUrl);
    return path.join(_cacheDir!.path, '$cacheKey$extension');
  }

  // Extract file extension from URL
  String _getFileExtension(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final filename = pathSegments.last;
        if (filename.contains('.')) {
          return filename.substring(filename.lastIndexOf('.'));
        }
      }
    } catch (e) {
      print('❌ Error extracting extension from URL: $e');
    }
    return '.jpg'; // Default extension
  }

  // Check if image is cached
  Future<bool> isCached(String imageUrl) async {
    await _ensureInitialized();
    final filePath = _getCacheFilePath(imageUrl);
    return File(filePath).exists();
  }

  // Get cached image file
  Future<File?> getCachedImage(String imageUrl) async {
    await _ensureInitialized();
    final filePath = _getCacheFilePath(imageUrl);
    final file = File(filePath);

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  // Download and cache image
  Future<File?> downloadAndCacheImage(String imageUrl) async {
    try {
      await _ensureInitialized();

      // Check if already cached
      final cachedFile = await getCachedImage(imageUrl);
      if (cachedFile != null) {
        print('📷 Image already cached: $imageUrl');
        return cachedFile;
      }

      print('📥 Downloading image: $imageUrl');

      // Download image
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final filePath = _getCacheFilePath(imageUrl);
        final file = File(filePath);

        // Write to cache
        await file.writeAsBytes(response.bodyBytes);

        print('✅ Image cached successfully: $filePath');
        return file;
      } else {
        print('❌ Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error downloading image: $e');
      return null;
    }
  }

  // Cache multiple images (for note sync)
  Future<List<String>> cacheImagesForNote(List<String> imageUrls) async {
    final cachedPaths = <String>[];

    for (final imageUrl in imageUrls) {
      try {
        final cachedFile = await downloadAndCacheImage(imageUrl);
        if (cachedFile != null) {
          cachedPaths.add(cachedFile.path);
        }
      } catch (e) {
        print('❌ Error caching image $imageUrl: $e');
        // Continue with other images even if one fails
      }
    }

    print('📷 Cached ${cachedPaths.length}/${imageUrls.length} images');
    return cachedPaths;
  }

  // Get cached path for URL
  Future<String?> getCachedPath(String imageUrl) async {
    final cachedFile = await getCachedImage(imageUrl);
    return cachedFile?.path;
  }

  // Get cache size
  Future<int> getCacheSize() async {
    await _ensureInitialized();

    int totalSize = 0;
    final files = _cacheDir!.listSync();

    for (final file in files) {
      if (file is File) {
        totalSize += await file.length();
      }
    }

    return totalSize;
  }

  // Clean cache (remove old files)
  Future<void> cleanCache({int maxAgeHours = 24 * 7}) async {
    // Default: 1 week
    await _ensureInitialized();

    final cutoffTime = DateTime.now().subtract(Duration(hours: maxAgeHours));
    final files = _cacheDir!.listSync();
    int deletedCount = 0;

    for (final file in files) {
      if (file is File) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffTime)) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            print('❌ Error deleting cached file: $e');
          }
        }
      }
    }

    print('🧹 Cleaned cache: deleted $deletedCount old files');
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    await _ensureInitialized();

    final files = _cacheDir!.listSync();
    int deletedCount = 0;

    for (final file in files) {
      if (file is File) {
        try {
          await file.delete();
          deletedCount++;
        } catch (e) {
          print('❌ Error deleting cached file: $e');
        }
      }
    }

    print('🧹 Cleared all cache: deleted $deletedCount files');
  }

  // Remove specific cached image
  Future<bool> removeCachedImage(String imageUrl) async {
    try {
      await _ensureInitialized();
      final filePath = _getCacheFilePath(imageUrl);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        print('🗑️ Removed cached image: $imageUrl');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error removing cached image: $e');
      return false;
    }
  }

  // Ensure cache directory is initialized
  Future<void> _ensureInitialized() async {
    if (_cacheDir == null) {
      await initialize();
    }
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    await _ensureInitialized();

    final files = _cacheDir!.listSync();
    final fileCount = files.whereType<File>().length;
    final totalSize = await getCacheSize();

    return {
      'fileCount': fileCount,
      'totalSize': totalSize,
      'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
      'cacheDir': _cacheDir!.path,
    };
  }
}

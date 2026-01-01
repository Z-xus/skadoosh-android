import 'package:isar/isar.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:skadoosh_app/services/storage_service.dart';

part 'note.g.dart';

@Collection()
class Note {
  Id id = Isar.autoIncrement;
  late String title;

  // DEPRECATED: content is now stored in local .md files.
  // Use fileName to read/write the actual content.
  @Deprecated('Use relativePath and file storage instead')
  String body = '';

  String? fileName; // Link to the physical .md file

  // NEW: Shadow caching and change detection fields
  @Index() // For fast lookups by FileWatcher
  String? relativePath; // e.g., "MyNote.md" or "folder/subfolder/MyNote.md"

  // NEW: Folder organization fields
  @Index() // For fast folder filtering and organization
  String? folderPath; // e.g., "", "Work", "Work/Projects" (empty string = root)

  List<int>? shadowContentZLib; // GZip compressed content from last sync
  String? lastSyncedHash; // SHA-256 hash of uncompressed shadow content
  bool isDirty = false; // Indicates file needs syncing

  // Trash bin functionality
  bool isDeleted = false;
  DateTime? deletedAt;

  // Archive functionality
  bool isArchived = false;
  DateTime? archivedAt;

  // Sync-related fields
  String? serverId; // UUID from server
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastSyncedAt;
  bool needsSync = false;
  String deviceId = '';

  // Image support
  List<String> imageUrls = []; // URLs of images stored in R2
  List<String> localImagePaths = []; // Local cached image paths
  bool hasImages = false;

  // NEW: Tags support for organization
  @Index() // For fast tag filtering
  List<String> tags = []; // List of tag names (e.g., ["work", "urgent", "ideas"])

  // NEW: Bidirectional mapping between R2 URLs and local paths (stored as JSON)
  // This allows offline fallback when R2 URL is unavailable
  String?
  imagePathMapJson; // Serialized Map<String, String> where key=R2 URL, value=local path

  // In-memory cache of the deserialized map
  @ignore
  Map<String, String>? _imagePathMapCache;

  // Helper methods for image sync status
  bool get hasPendingImageUploads {
    return localImagePaths.isNotEmpty &&
        localImagePaths.length > imageUrls.length;
  }

  bool get hasUnSyncedImages {
    return localImagePaths.isNotEmpty && imageUrls.isEmpty;
  }

  int get pendingImageCount {
    if (localImagePaths.isEmpty) return 0;
    return math.max(0, localImagePaths.length - imageUrls.length);
  }

  List<String> get syncedImageUrls {
    return imageUrls.where((url) => url.startsWith('http')).toList();
  }

  List<String> get localOnlyImagePaths {
    return localImagePaths.where((path) => !path.startsWith('http')).toList();
  }

  // NEW: Image path mapping helpers
  Map<String, String> getImagePathMap() {
    if (_imagePathMapCache != null) return _imagePathMapCache!;

    // Deserialize from JSON if available
    if (imagePathMapJson != null && imagePathMapJson!.isNotEmpty) {
      try {
        final decoded = json.decode(imagePathMapJson!) as Map<String, dynamic>;
        _imagePathMapCache = decoded.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        return _imagePathMapCache!;
      } catch (e) {
        print('Error deserializing imagePathMap: $e');
      }
    }

    // Return empty map as fallback
    _imagePathMapCache = {};
    return _imagePathMapCache!;
  }

  void setImagePathMap(Map<String, String> value) {
    _imagePathMapCache = value;
    // Serialize to JSON for Isar storage
    try {
      imagePathMapJson = json.encode(value);
    } catch (e) {
      print('Error serializing imagePathMap: $e');
      imagePathMapJson = null;
    }
  }

  // Add a mapping between R2 URL and local path
  void addImageMapping(String r2Url, String localPath) {
    final map = getImagePathMap();
    map[r2Url] = localPath;
    setImagePathMap(map);
  }

  // Get local path for an R2 URL (returns null if not found)
  String? getLocalPathForUrl(String r2Url) {
    return getImagePathMap()[r2Url];
  }

  // Get R2 URL for a local path (returns null if not found)
  String? getUrlForLocalPath(String localPath) {
    final map = getImagePathMap();
    for (var entry in map.entries) {
      if (entry.value == localPath) return entry.key;
    }
    return null;
  }

  // Remove a mapping
  void removeImageMapping(String r2Url) {
    final map = getImagePathMap();
    map.remove(r2Url);
    setImagePathMap(map);
  }

  // Helper method to check if note should be permanently deleted (30 days)
  bool get shouldPermanentlyDelete {
    if (!isDeleted || deletedAt == null) return false;
    return DateTime.now().difference(deletedAt!).inDays >= 30;
  }

  // Helper method to check if note is in trash
  bool get isInTrash => isDeleted && !shouldPermanentlyDelete;

  // Helper method to check if note is active (not archived and not deleted)
  bool get isActive => !isArchived && !isDeleted;

  // NEW: Helper method to get content from storage
  Future<String> getContent() async {
    if (relativePath == null) return body; // Fallback to deprecated field
    try {
      return await StorageService().readNote(relativePath!);
    } catch (e) {
      print('Error reading note content: $e');
      return body; // Fallback to deprecated field
    }
  }

  // NEW: Helper method to update shadow cache
  void updateShadowCache(String content) {
    try {
      // Calculate SHA-256 hash of current content
      final contentBytes = utf8.encode(content);
      lastSyncedHash = sha256.convert(contentBytes).toString();

      // Compress content with GZip
      final gzipEncoder = GZipEncoder();
      shadowContentZLib = gzipEncoder.encode(contentBytes);

      print(
        '🔄 Updated shadow cache - Hash: ${lastSyncedHash?.substring(0, 8)}..., Compressed: ${shadowContentZLib?.length} bytes',
      );
    } catch (e) {
      print('Error updating shadow cache: $e');
      lastSyncedHash = null;
      shadowContentZLib = null;
    }
  }

  // NEW: Helper method to get shadow content (decompressed)
  String? getShadowContent() {
    if (shadowContentZLib == null) return null;
    try {
      final gzipDecoder = GZipDecoder();
      final decompressed = gzipDecoder.decodeBytes(shadowContentZLib!);
      return utf8.decode(decompressed);
    } catch (e) {
      print('Error decompressing shadow content: $e');
      return null;
    }
  }

  // NEW: Helper method to calculate current file hash
  Future<String?> calculateCurrentFileHash() async {
    if (relativePath == null) return null;
    try {
      final content = await getContent();
      final contentBytes = utf8.encode(content);
      return sha256.convert(contentBytes).toString();
    } catch (e) {
      print('Error calculating current file hash: $e');
      return null;
    }
  }

  // NEW: Folder helper methods (simplified for single-level)
  String get displayFileName {
    if (fileName != null) {
      return fileName!.replaceAll('.md', '');
    }
    if (relativePath != null) {
      final parts = relativePath!.split('/');
      return parts.last.replaceAll('.md', '');
    }
    return title;
  }

  bool get isInRoot => folderPath == null || folderPath!.isEmpty;

  String get fullPath {
    if (isInRoot) return fileName ?? relativePath ?? '$title.md';
    return '${folderPath!}/${fileName ?? relativePath ?? '$title.md'}';
  }

  String get folderName => folderPath ?? '';

  String get displayFolderName => isInRoot ? 'All' : folderPath!;
}

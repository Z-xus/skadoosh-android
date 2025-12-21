import 'package:isar/isar.dart';
import 'dart:convert';
import 'dart:io';
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
  String? relativePath; // e.g., "MyNote.md" - filename only

  List<int>? shadowContentZLib; // GZip compressed content from last sync
  String? lastSyncedHash; // SHA-256 hash of uncompressed shadow content
  bool isDirty = false; // Indicates file needs syncing

  // Trash bin functionality
  bool isDeleted = false;
  DateTime? deletedAt;

  // Sync-related fields
  String? serverId; // UUID from server
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastSyncedAt;
  bool needsSync = false;
  String deviceId = '';

  // Helper method to check if note should be permanently deleted (30 days)
  bool get shouldPermanentlyDelete {
    if (!isDeleted || deletedAt == null) return false;
    return DateTime.now().difference(deletedAt!).inDays >= 30;
  }

  // Helper method to check if note is in trash
  bool get isInTrash => isDeleted && !shouldPermanentlyDelete;

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
}

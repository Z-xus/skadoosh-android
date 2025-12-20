import 'package:isar/isar.dart';

part 'note.g.dart';

@Collection()
class Note {
  Id id = Isar.autoIncrement;
  late String title;
  String body = ''; // Separate body content

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
}

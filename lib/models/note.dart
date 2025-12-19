import 'package:isar/isar.dart';

part 'note.g.dart';

@Collection()
class Note {
  Id id = Isar.autoIncrement;
  late String title;

  // Sync-related fields
  String? serverId; // UUID from server
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? lastSyncedAt;
  bool needsSync = false;
  String deviceId = '';
}

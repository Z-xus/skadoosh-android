import 'package:isar/isar.dart';

part 'pending_image_upload.g.dart';

@Collection()
class PendingImageUpload {
  Id id = Isar.autoIncrement;

  @Index()
  late int noteId; // Local note ID

  @Index()
  String? serverId; // Server note ID (null for new notes)

  late String localImagePath; // Path to locally stored image
  String?
  r2ImageUrl; // R2 URL after successful upload (null if not uploaded yet)

  late DateTime createdAt;
  DateTime? uploadedAt; // When successfully uploaded to R2

  // Upload status
  @Enumerated(EnumType.name)
  UploadStatus status = UploadStatus.pending;

  // Retry information
  int retryCount = 0;
  DateTime? lastRetryAt;
  String? lastError;

  // Image metadata
  String? originalFilename;
  int? fileSize;
  String? contentType;

  bool get isPending => status == UploadStatus.pending;
  bool get isUploading => status == UploadStatus.uploading;
  bool get isCompleted => status == UploadStatus.completed;
  bool get hasFailed => status == UploadStatus.failed;

  bool get shouldRetry =>
      hasFailed &&
      retryCount < 3 &&
      (lastRetryAt == null ||
          DateTime.now().difference(lastRetryAt!).inMinutes >= 5);
}

enum UploadStatus {
  pending, // Waiting to be uploaded
  uploading, // Currently being uploaded
  completed, // Successfully uploaded
  failed, // Upload failed (will retry up to 3 times)
}

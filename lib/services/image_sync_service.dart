import 'dart:io';
import 'package:isar/isar.dart';
import 'package:skadoosh_app/models/pending_image_upload.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/models/note.dart';
import 'package:skadoosh_app/services/image_service.dart';
import 'package:skadoosh_app/services/storage_service.dart';
import 'package:path/path.dart' as path;

class ImageSyncService {
  static final ImageSyncService _instance = ImageSyncService._internal();
  factory ImageSyncService() => _instance;
  ImageSyncService._internal();

  static ImageSyncService get instance => _instance;

  final ImageService _imageService = ImageService();
  bool _isInitialized = false;
  bool _isProcessing = false;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _imageService.initialize();
    _isInitialized = true;
    print('ImageSyncService initialized');
  }

  // Queue an image for upload
  Future<void> queueImageUpload({
    required int noteId,
    String? serverId,
    required String localImagePath,
    String? originalFilename,
    int? fileSize,
    String? contentType,
  }) async {
    if (!_isInitialized) await initialize();

    // Check if this image is already queued
    final existing = await NoteDatabase.isar.pendingImageUploads
        .filter()
        .noteIdEqualTo(noteId)
        .and()
        .localImagePathEqualTo(localImagePath)
        .findFirst();

    if (existing != null) {
      print('Image already queued for upload: $localImagePath');
      return;
    }

    final upload = PendingImageUpload()
      ..noteId = noteId
      ..serverId = serverId
      ..localImagePath = localImagePath
      ..originalFilename = originalFilename
      ..fileSize = fileSize
      ..contentType = contentType
      ..createdAt = DateTime.now()
      ..status = UploadStatus.pending;

    await NoteDatabase.isar.writeTxn(() async {
      await NoteDatabase.isar.pendingImageUploads.put(upload);
    });

    print('Queued image for upload: $localImagePath (noteId: $noteId)');

    // Try to process immediately if we have internet and the note is synced
    if (_imageService.isConfigured && serverId != null) {
      _processQueueInBackground();
    }
  }

  // Process the upload queue
  Future<int> processUploadQueue({bool force = false}) async {
    if (!_isInitialized) await initialize();

    if (_isProcessing && !force) {
      print('Upload queue is already being processed');
      return 0;
    }

    _isProcessing = true;
    int processedCount = 0;

    try {
      print('🚀 Starting upload queue processing...');
      // Get all pending uploads
      final pendingUploads = await NoteDatabase.isar.pendingImageUploads
          .filter()
          .statusEqualTo(UploadStatus.pending)
          .or()
          .statusEqualTo(UploadStatus.failed)
          .findAll();

      print('Processing ${pendingUploads.length} pending image uploads');

      for (final upload in pendingUploads) {
        print('📋 Processing upload ${upload.id}:');
        print('   Note ID: ${upload.noteId}');
        print('   Server ID: ${upload.serverId}');
        print('   Local Path: ${upload.localImagePath}');
        print('   Status: ${upload.status.name}');
        print('   Retry Count: ${upload.retryCount}');

        // Skip failed uploads that shouldn't retry yet
        if (upload.hasFailed && !upload.shouldRetry) {
          print('   ⏭️ Skipping failed upload (not ready for retry)');
          continue;
        }

        // Skip uploads for notes that don't have a server ID yet
        if (upload.serverId == null || upload.serverId!.isEmpty) {
          print('   ⏸️ Upload has no server ID, checking note...');
          // Check if the note now has a server ID
          final note = await NoteDatabase.isar.notes.get(upload.noteId);
          if (note?.serverId != null && note!.serverId!.isNotEmpty) {
            print(
              '   ✅ Note now has server ID: ${note.serverId}, updating upload',
            );
            // Update the upload with the server ID
            upload.serverId = note.serverId;
            await NoteDatabase.isar.writeTxn(() async {
              await NoteDatabase.isar.pendingImageUploads.put(upload);
            });
          } else {
            print('   ⏭️ Note still not synced, skipping upload');
            continue; // Note still not synced
          }
        }

        print('   🚀 Processing upload...');
        if (await _processUpload(upload)) {
          processedCount++;
          print('   ✅ Upload completed successfully');
        } else {
          print('   ❌ Upload failed');
        }
      }

      print(
        '📊 Processed $processedCount out of ${pendingUploads.length} image uploads',
      );
      return processedCount;
    } finally {
      _isProcessing = false;
    }
  }

  // Process a single upload
  Future<bool> _processUpload(PendingImageUpload upload) async {
    try {
      print('📤 Starting upload for ${upload.localImagePath}...');

      // Mark as uploading
      upload.status = UploadStatus.uploading;
      await NoteDatabase.isar.writeTxn(() async {
        await NoteDatabase.isar.pendingImageUploads.put(upload);
      });

      // Check if local file still exists
      final localFile = File(upload.localImagePath);
      if (!await localFile.exists()) {
        print('❌ Local image file not found: ${upload.localImagePath}');
        await _markUploadAsFailed(upload, 'Local file not found');
        return false;
      }

      print('📁 File exists, uploading to R2 (noteId: ${upload.serverId})...');

      // Upload to R2
      final result = await _imageService.uploadImage(
        imageFile: localFile,
        noteId: upload.serverId!,
        compressImage: true,
      );

      print(
        '📡 R2 upload result - Success: ${result.success}, URL: ${result.publicUrl}',
      );
      if (result.error != null) {
        print('📡 R2 upload error: ${result.error}');
      }

      if (result.success && result.publicUrl != null) {
        // Upload successful
        upload.status = UploadStatus.completed;
        upload.r2ImageUrl = result.publicUrl;
        upload.uploadedAt = DateTime.now();

        await NoteDatabase.isar.writeTxn(() async {
          await NoteDatabase.isar.pendingImageUploads.put(upload);
        });

        // Update the note with the R2 URL
        await _updateNoteWithR2Url(upload);

        print(
          '✅ Successfully uploaded image: ${upload.localImagePath} -> ${result.publicUrl}',
        );
        return true;
      } else {
        // Upload failed
        await _markUploadAsFailed(
          upload,
          result.error ?? 'Unknown upload error',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error processing upload: $e');
      await _markUploadAsFailed(upload, e.toString());
      return false;
    }
  }

  // Mark upload as failed
  Future<void> _markUploadAsFailed(
    PendingImageUpload upload,
    String error,
  ) async {
    upload.status = UploadStatus.failed;
    upload.retryCount++;
    upload.lastRetryAt = DateTime.now();
    upload.lastError = error;

    await NoteDatabase.isar.writeTxn(() async {
      await NoteDatabase.isar.pendingImageUploads.put(upload);
    });

    print('❌ Upload failed (attempt ${upload.retryCount}): $error');
  }

  // Update note content with R2 URL
  Future<void> _updateNoteWithR2Url(PendingImageUpload upload) async {
    try {
      final note = await NoteDatabase.isar.notes.get(upload.noteId);
      if (note == null) return;

      // Read current content from file
      String content = '';
      if (note.relativePath != null) {
        final storageService = StorageService();
        content = await storageService.readNote(note.relativePath!);
      }

      // Replace local image path with R2 URL in content
      if (content.contains(upload.localImagePath)) {
        final updatedContent = content.replaceAll(
          upload.localImagePath,
          upload.r2ImageUrl!,
        );

        // Write updated content back to file
        if (note.relativePath != null) {
          final storageService = StorageService();
          await storageService.writeNote(note.relativePath!, updatedContent);
        }

        // Update note metadata
        final updatedImageUrls = List<String>.from(note.imageUrls);
        if (!updatedImageUrls.contains(upload.r2ImageUrl!)) {
          updatedImageUrls.add(upload.r2ImageUrl!);
        }

        note.imageUrls = updatedImageUrls;
        note.hasImages = true;
        note.updatedAt = DateTime.now();
        note.needsSync = true; // Mark for sync to update server

        await NoteDatabase.isar.writeTxn(() async {
          await NoteDatabase.isar.notes.put(note);
        });

        print('✅ Updated note content with R2 URL: ${upload.r2ImageUrl}');
      }
    } catch (e) {
      print('❌ Error updating note with R2 URL: $e');
    }
  }

  // Get pending uploads for a note
  Future<List<PendingImageUpload>> getPendingUploadsForNote(int noteId) async {
    return await NoteDatabase.isar.pendingImageUploads
        .filter()
        .noteIdEqualTo(noteId)
        .not()
        .statusEqualTo(UploadStatus.completed)
        .findAll();
  }

  // Get all pending uploads
  Future<List<PendingImageUpload>> getAllPendingUploads() async {
    return await NoteDatabase.isar.pendingImageUploads
        .filter()
        .not()
        .statusEqualTo(UploadStatus.completed)
        .findAll();
  }

  // Clean up completed uploads older than 7 days
  Future<void> cleanupCompletedUploads() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

    final completedUploads = await NoteDatabase.isar.pendingImageUploads
        .filter()
        .statusEqualTo(UploadStatus.completed)
        .uploadedAtLessThan(cutoffDate)
        .findAll();

    if (completedUploads.isNotEmpty) {
      await NoteDatabase.isar.writeTxn(() async {
        for (final upload in completedUploads) {
          await NoteDatabase.isar.pendingImageUploads.delete(upload.id);
        }
      });

      print('Cleaned up ${completedUploads.length} completed uploads');
    }
  }

  // Update server IDs for pending uploads when notes get synced
  Future<void> updateServerIdsForPendingUploads() async {
    final pendingUploads = await NoteDatabase.isar.pendingImageUploads
        .filter()
        .serverIdIsNull()
        .or()
        .serverIdEqualTo('')
        .findAll();

    for (final upload in pendingUploads) {
      final note = await NoteDatabase.isar.notes.get(upload.noteId);
      if (note?.serverId != null && note!.serverId!.isNotEmpty) {
        upload.serverId = note.serverId;
        await NoteDatabase.isar.writeTxn(() async {
          await NoteDatabase.isar.pendingImageUploads.put(upload);
        });
      }
    }
  }

  // Process queue in background (non-blocking)
  void _processQueueInBackground() {
    Future.delayed(Duration.zero, () async {
      try {
        await processUploadQueue();
      } catch (e) {
        print('Error processing upload queue in background: $e');
      }
    });
  }

  // Scan note content and queue any local images that aren't already queued
  Future<void> scanAndQueueLocalImagesInNote(Note note) async {
    if (!_isInitialized) await initialize();

    try {
      print(
        '🔍 Scanning note ${note.id} (title: "${note.title}") for local images...',
      );
      print('   Note serverId: ${note.serverId}');
      print('   Note relativePath: ${note.relativePath}');
      print('   Note fileName: ${note.fileName}');

      // Read note content
      String content = '';
      if (note.relativePath != null) {
        final storageService = StorageService();
        content = await storageService.readNote(note.relativePath!);
        print(
          '   Content read from relativePath: ${content.length} characters',
        );
      } else if (note.fileName != null) {
        final storageService = StorageService();
        content = await storageService.readNote(note.fileName!);
        print('   Content read from fileName: ${content.length} characters');
      } else {
        content = note.body; // Fallback to deprecated body field
        print('   Content read from body field: ${content.length} characters');
      }

      // Debug: Print first 200 characters of content
      final previewContent = content.length > 200
          ? content.substring(0, 200) + '...'
          : content;
      print('   Content preview: $previewContent');

      // Find all local image references
      final localImageRegex = RegExp(
        r'!\[.*?\]\((file://.*?|/.*?\.(?:jpg|jpeg|png|gif|webp))\)',
      );
      final matches = localImageRegex.allMatches(content);
      print('   Found ${matches.length} image references in content');

      for (final match in matches) {
        final imagePath = match.group(1);
        print('   Processing image reference: $imagePath');

        if (imagePath != null && !imagePath.startsWith('http')) {
          // Clean the path (remove file:// prefix if present)
          final cleanPath = imagePath.startsWith('file://')
              ? imagePath.substring(7)
              : imagePath;
          print('     Clean path: $cleanPath');

          // Check if this image is already queued
          final existingUpload = await NoteDatabase.isar.pendingImageUploads
              .filter()
              .noteIdEqualTo(note.id)
              .and()
              .localImagePathEqualTo(cleanPath)
              .findFirst();

          if (existingUpload == null) {
            print('     Image not in queue, checking if file exists...');
            // Check if file exists
            final file = File(cleanPath);
            if (await file.exists()) {
              final fileSize = await file.length();
              final fileName = path.basename(cleanPath);
              final extension = path.extension(fileName).toLowerCase();
              print('     File exists: $fileName (${fileSize} bytes)');

              String contentType = 'application/octet-stream';
              switch (extension) {
                case '.jpg':
                case '.jpeg':
                  contentType = 'image/jpeg';
                  break;
                case '.png':
                  contentType = 'image/png';
                  break;
                case '.gif':
                  contentType = 'image/gif';
                  break;
                case '.webp':
                  contentType = 'image/webp';
                  break;
              }

              await queueImageUpload(
                noteId: note.id,
                serverId: note.serverId,
                localImagePath: cleanPath,
                originalFilename: fileName,
                fileSize: fileSize,
                contentType: contentType,
              );

              print('📸 Queued previously missed image: $cleanPath');
            } else {
              print('     File does not exist: $cleanPath');
            }
          } else {
            print(
              '     Image already queued (ID: ${existingUpload.id}, status: ${existingUpload.status.name})',
            );
          }
        } else {
          print('     Skipping remote image: $imagePath');
        }
      }
    } catch (e) {
      print('❌ Error scanning note for local images: $e');
    }
  }

  Future<Map<String, int>> getUploadStats() async {
    final pending = await NoteDatabase.isar.pendingImageUploads
        .filter()
        .statusEqualTo(UploadStatus.pending)
        .count();

    final uploading = await NoteDatabase.isar.pendingImageUploads
        .filter()
        .statusEqualTo(UploadStatus.uploading)
        .count();

    final completed = await NoteDatabase.isar.pendingImageUploads
        .filter()
        .statusEqualTo(UploadStatus.completed)
        .count();

    final failed = await NoteDatabase.isar.pendingImageUploads
        .filter()
        .statusEqualTo(UploadStatus.failed)
        .count();

    return {
      'pending': pending,
      'uploading': uploading,
      'completed': completed,
      'failed': failed,
    };
  }

  // Debug function to print current queue status
  Future<void> debugPrintQueueStatus() async {
    try {
      final stats = await getUploadStats();
      final allUploads = await NoteDatabase.isar.pendingImageUploads
          .where()
          .findAll();

      print('\n🔍 === IMAGE SYNC QUEUE DEBUG ===');
      print('📊 Queue Statistics:');
      print('   - Pending: ${stats['pending']}');
      print('   - Uploading: ${stats['uploading']}');
      print('   - Completed: ${stats['completed']}');
      print('   - Failed: ${stats['failed']}');
      print('\n📋 All Uploads:');

      if (allUploads.isEmpty) {
        print('   No uploads in queue');
      } else {
        for (final upload in allUploads) {
          print('   📁 ID: ${upload.id}');
          print('      Note ID: ${upload.noteId}');
          print('      Server ID: ${upload.serverId ?? 'null'}');
          print('      Local Path: ${upload.localImagePath}');
          print('      R2 URL: ${upload.r2ImageUrl ?? 'null'}');
          print('      Status: ${upload.status.name}');
          print('      Created: ${upload.createdAt}');
          if (upload.lastError != null) {
            print('      Last Error: ${upload.lastError}');
          }
          print('   ---');
        }
      }
      print('=== END DEBUG ===\n');
    } catch (e) {
      print('❌ Error getting debug info: $e');
    }
  }
}

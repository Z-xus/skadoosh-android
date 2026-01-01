# Offline/Online Image Sync Implementation

## Overview

This implementation provides a robust offline/online image sync mechanism that handles all the scenarios you mentioned:

1. **New notes with images** - Images are saved locally and queued for upload when the note gets synced
2. **Offline image saving** - Images are always saved locally first, then uploaded when connectivity is restored
3. **Conflict resolution** - Proper handling of sync conflicts without data loss
4. **Automatic upload replacement** - Local image paths are automatically replaced with R2 URLs when uploaded

## Architecture

### 1. PendingImageUpload Model (`/models/pending_image_upload.dart`)
- Tracks images that need to be uploaded to R2
- Stores metadata: local path, note ID, server ID, upload status, retry info
- Supports different upload states: pending, uploading, completed, failed
- Includes retry logic with exponential backoff

### 2. ImageSyncService (`/services/image_sync_service.dart`)
- Manages the upload queue for pending images
- Processes uploads when notes get synced and have server IDs
- Updates note content to replace local paths with R2 URLs
- Handles upload failures and retries
- Cleans up completed uploads after 7 days

### 3. Enhanced Note Model (`/models/note.dart`)
- Added helper methods to check image sync status:
  - `hasPendingImageUploads`: Check if images need uploading
  - `hasUnSyncedImages`: Check if note has local-only images
  - `pendingImageCount`: Count of images waiting for upload
  - `syncedImageUrls`: List of successfully uploaded images
  - `localOnlyImagePaths`: List of local images not yet uploaded

### 4. Updated EditNotePage (`/pages/edit_note_page.dart`)
- Modified `_insertImageAsWidget()` to use the new sync mechanism
- Always saves images locally first (consistent behavior)
- Queues images for upload via ImageSyncService
- For synced notes, attempts immediate upload for better UX
- Falls back to queued upload if immediate upload fails

### 5. Enhanced Sync Process (`/services/key_based_sync_service.dart`)
- Added `_processImageUploads()` step after note sync
- Updates server IDs for pending uploads when notes get synced
- Processes the entire upload queue after successful sync
- Maintains separation between note sync and image upload

## How It Works

### Scenario 1: New Note with Images
1. User creates a new note and adds images
2. Images are saved to local storage (`/documents/images/`)
3. Images are queued in `PendingImageUpload` table with `serverId = null`
4. Note content references local image paths
5. When note is synced and gets a `serverId`, the queue is updated
6. Images are uploaded to R2 and note content is updated with R2 URLs

### Scenario 2: Existing Synced Note with Images
1. User adds images to an existing synced note
2. Images are saved locally and immediately queued for upload
3. If connectivity is available, immediate upload is attempted
4. If successful, note content uses R2 URL immediately
5. If upload fails, it falls back to local path and retries later

### Scenario 3: Offline Image Addition
1. User adds images while offline
2. Images are saved locally and queued for upload
3. Note content references local paths temporarily
4. When connectivity is restored and sync runs:
   - Note text sync happens first
   - Then image upload queue is processed
   - Local paths are replaced with R2 URLs
   - Note is marked for re-sync to update server

### Scenario 4: Conflict Resolution
1. If image upload fails, it's marked for retry (up to 3 attempts)
2. Local images are never deleted until successfully uploaded
3. If note content conflicts occur during sync, the shadow cache system handles text conflicts
4. Image URLs and local paths are tracked separately to avoid conflicts

## Key Benefits

### ✅ **Always Works Offline**
- Images are immediately saved locally
- No dependency on internet connectivity for core functionality

### ✅ **No Data Loss**
- Local images are preserved until successfully uploaded
- Failed uploads are retried automatically
- Comprehensive error handling and logging

### ✅ **Seamless User Experience**
- For synced notes with internet: immediate R2 display
- For offline/new notes: local display with automatic upgrade to R2

### ✅ **Efficient Resource Management**
- Upload queue prevents duplicate uploads
- Automatic cleanup of old completed uploads
- Retry logic with exponential backoff

### ✅ **Conflict-Free Operation**
- Image sync is separate from note text sync
- No overwrites or data corruption during sync
- Clear separation of local and remote state

## File Structure Changes

```
lib/
├── models/
│   ├── pending_image_upload.dart          # NEW: Upload queue model
│   ├── pending_image_upload.g.dart        # Generated Isar code
│   ├── note.dart                          # UPDATED: Added image sync helpers
│   └── note_database.dart                 # UPDATED: Added PendingImageUpload schema
├── services/
│   ├── image_sync_service.dart            # NEW: Queue management service
│   ├── key_based_sync_service.dart        # UPDATED: Added image sync integration
│   └── image_service.dart                 # EXISTING: R2 upload service
├── pages/
│   └── edit_note_page.dart               # UPDATED: New image handling
└── components/
    └── image_picker_widget.dart          # UPDATED: Added sync status display
```

## Testing Scenarios

To test the implementation, try these scenarios:

### 1. **New Note + Image + Offline**
- Create new note without internet
- Add images (should save locally)
- Go online and sync
- Verify images appear in cloud storage

### 2. **Existing Note + Image + Online**
- Add image to synced note with internet
- Should immediately show R2 URL
- Verify upload in cloud storage

### 3. **Mixed Connectivity**
- Add images while offline
- Add images while online
- Sync and verify all images are properly uploaded

### 4. **Upload Failure Recovery**
- Force network error during upload
- Verify retry mechanism works
- Check that local images are preserved

The implementation provides a robust, user-friendly solution that handles all the edge cases you mentioned while maintaining data integrity and providing a smooth user experience across all connectivity scenarios.
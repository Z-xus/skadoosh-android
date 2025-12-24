const express = require('express');
const multer = require('multer');
const { pool } = require('../database/init');
const R2StorageService = require('../utils/r2-storage');
const crypto = require('crypto');

const router = express.Router();
const r2Storage = new R2StorageService();

// Configure multer for memory storage (we'll upload to R2 directly)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allow only image files
    console.log(`🔍 File filter check - filename: ${file.originalname}, mimetype: ${file.mimetype}, fieldname: ${file.fieldname}`);
    
    if (file.mimetype && file.mimetype.startsWith('image/')) {
      console.log(`✅ File accepted: ${file.originalname} (${file.mimetype})`);
      cb(null, true);
    } else {
      console.log(`❌ File rejected: ${file.originalname} (mimetype: ${file.mimetype || 'undefined'})`);
      cb(new Error('Only image files are allowed!'), false);
    }
  },
});

// Middleware to verify key-based authentication (reuse from sync routes)
const verifyKeyAuth = async (req, res, next) => {
  try {
    const fingerprint = req.headers['key-fingerprint'];
    const challenge = req.headers['challenge'];
    const signature = req.headers['signature'];
    const clientDeviceId = req.headers['device-id'];
    
    if (!fingerprint || !challenge || !signature || !clientDeviceId) {
      return res.status(401).json({ 
        error: 'Key authentication required',
        required_headers: ['key-fingerprint', 'device-id', 'challenge', 'signature']
      });
    }

    const CryptoUtils = require('../utils/crypto');

    // Get public key and group info for the specific device
    const keyResult = await pool.query(
      'SELECT public_key, sync_group_id, device_id, device_name FROM public_keys WHERE key_fingerprint = $1 AND device_id = $2',
      [fingerprint, clientDeviceId]
    );

    if (keyResult.rows.length === 0) {
      return res.status(401).json({ error: 'Key-device combination not found' });
    }

    const publicKey = keyResult.rows[0].public_key;
    const groupId = keyResult.rows[0].sync_group_id;
    const deviceId = keyResult.rows[0].device_id;

    // Verify signature
    const isValid = CryptoUtils.verifySignature(challenge, signature, publicKey);
    
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid signature' });
    }

    // Update last used timestamp
    await pool.query(
      'UPDATE public_keys SET last_used = NOW() WHERE key_fingerprint = $1',
      [fingerprint]
    );

    req.syncGroupId = groupId;
    req.keyFingerprint = fingerprint;
    req.deviceId = deviceId;
    
    console.log(`✅ Authenticated device ${deviceId} in group ${groupId} for image upload`);
    next();

  } catch (error) {
    console.error('Key auth error:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
};

// Upload image endpoint
router.post('/upload', verifyKeyAuth, upload.single('image'), async (req, res) => {
  try {
    const { noteId } = req.body;
    const groupId = req.syncGroupId;
    const deviceId = req.deviceId;
    const keyFingerprint = req.keyFingerprint;

    if (!req.file) {
      return res.status(400).json({ error: 'No image file provided' });
    }

    console.log(`📤 Uploading image for note ${noteId} in group ${groupId}`);

    // Generate unique file path
    const filePath = r2Storage.generateFilePath(groupId, noteId, req.file.originalname);
    
    // Upload to R2
    const uploadResult = await r2Storage.uploadFile(
      req.file.buffer,
      filePath,
      req.file.mimetype
    );

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Insert image record into database
      const imageResult = await client.query(`
        INSERT INTO images (
          sync_group_id, note_id, filename, original_filename, 
          storage_path, public_url, content_type, file_size,
          device_id, key_fingerprint
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING id, created_at
      `, [
        groupId, noteId, filePath.split('/').pop(), req.file.originalname,
        filePath, uploadResult.publicUrl, req.file.mimetype, req.file.size,
        deviceId, keyFingerprint
      ]);

      const imageId = imageResult.rows[0].id;

      // Update note to mark it has images and increment version
      if (noteId) {
        await client.query(`
          UPDATE notes 
          SET has_images = TRUE, version = version + 1, updated_at = NOW()
          WHERE id = $1 AND sync_group_id = $2
        `, [noteId, groupId]);

        // Create sync event for image upload
        await client.query(`
          INSERT INTO sync_events (sync_group_id, note_id, event_type, device_id, key_fingerprint)
          VALUES ($1, $2, 'image_upload', $3, $4)
        `, [groupId, noteId, deviceId, keyFingerprint]);
      }

      await client.query('COMMIT');

      console.log(`✅ Image uploaded successfully: ${filePath}`);
      
      // Generate a long-lived signed URL for client access (24 hours)
      const signedUrl = await r2Storage.getDownloadUrl(filePath, 86400); // 24 hours

      res.json({
        success: true,
        image: {
          id: imageId,
          filename: filePath.split('/').pop(),
          originalFilename: req.file.originalname,
          publicUrl: signedUrl, // Use signed URL instead of direct R2 URL
          storagePath: filePath,
          contentType: req.file.mimetype,
          fileSize: req.file.size,
          createdAt: imageResult.rows[0].created_at
        }
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('❌ Image upload error:', error);
    res.status(500).json({ error: 'Failed to upload image' });
  }
});

// Get images for a note
router.get('/note/:noteId', verifyKeyAuth, async (req, res) => {
  try {
    const { noteId } = req.params;
    const groupId = req.syncGroupId;

    console.log(`📥 Getting images for note ${noteId} in group ${groupId}`);

    const result = await pool.query(`
      SELECT id, filename, original_filename, public_url, storage_path,
             content_type, file_size, created_at, updated_at
      FROM images
      WHERE note_id = $1 AND sync_group_id = $2 AND is_deleted = FALSE
      ORDER BY created_at ASC
    `, [noteId, groupId]);

    res.json({
      images: result.rows
    });

  } catch (error) {
    console.error('❌ Get images error:', error);
    res.status(500).json({ error: 'Failed to get images' });
  }
});

// Delete image
router.delete('/:imageId', verifyKeyAuth, async (req, res) => {
  try {
    const { imageId } = req.params;
    const groupId = req.syncGroupId;
    const deviceId = req.deviceId;
    const keyFingerprint = req.keyFingerprint;

    console.log(`🗑️  Deleting image ${imageId} in group ${groupId}`);

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Get image details
      const imageResult = await pool.query(`
        SELECT note_id, storage_path 
        FROM images 
        WHERE id = $1 AND sync_group_id = $2 AND is_deleted = FALSE
      `, [imageId, groupId]);

      if (imageResult.rows.length === 0) {
        return res.status(404).json({ error: 'Image not found' });
      }

      const { note_id: noteId, storage_path: storagePath } = imageResult.rows[0];

      // Mark image as deleted in database
      await client.query(`
        UPDATE images 
        SET is_deleted = TRUE, deleted_at = NOW()
        WHERE id = $1 AND sync_group_id = $2
      `, [imageId, groupId]);

      // Check if note still has other images
      const remainingImagesResult = await client.query(`
        SELECT COUNT(*) as count
        FROM images
        WHERE note_id = $1 AND sync_group_id = $2 AND is_deleted = FALSE
      `, [noteId, groupId]);

      const hasRemainingImages = remainingImagesResult.rows[0].count > 0;

      // Update note's has_images flag and version
      await client.query(`
        UPDATE notes 
        SET has_images = $1, version = version + 1, updated_at = NOW()
        WHERE id = $2 AND sync_group_id = $3
      `, [hasRemainingImages, noteId, groupId]);

      // Create sync event for image deletion
      await client.query(`
        INSERT INTO sync_events (sync_group_id, note_id, event_type, device_id, key_fingerprint)
        VALUES ($1, $2, 'image_delete', $3, $4)
      `, [groupId, noteId, deviceId, keyFingerprint]);

      await client.query('COMMIT');

      // Delete from R2 storage (async, don't wait for it)
      r2Storage.deleteFile(storagePath).catch(error => {
        console.error(`❌ Failed to delete file from R2: ${storagePath}`, error);
      });

      console.log(`✅ Image deleted successfully: ${imageId}`);

      res.json({
        success: true,
        message: 'Image deleted successfully'
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('❌ Delete image error:', error);
    res.status(500).json({ error: 'Failed to delete image' });
  }
});

// Get pre-signed upload URL (for direct client uploads)
router.post('/upload-url', verifyKeyAuth, async (req, res) => {
  try {
    const { filename, contentType, noteId } = req.body;
    const groupId = req.syncGroupId;

    if (!filename || !contentType) {
      return res.status(400).json({ error: 'Filename and contentType are required' });
    }

    console.log(`📝 Generating upload URL for ${filename} in group ${groupId}`);

    // Generate unique file path
    const filePath = r2Storage.generateFilePath(groupId, noteId, filename);
    
    // Get pre-signed upload URL
    const uploadUrl = await r2Storage.getUploadUrl(filePath, contentType);
    const publicUrl = r2Storage.getPublicUrl(filePath);

    res.json({
      uploadUrl,
      publicUrl,
      filePath,
      expiresIn: 3600 // 1 hour
    });

  } catch (error) {
    console.error('❌ Upload URL generation error:', error);
    res.status(500).json({ error: 'Failed to generate upload URL' });
  }
});

module.exports = router;
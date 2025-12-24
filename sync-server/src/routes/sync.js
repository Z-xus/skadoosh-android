const express = require('express');
const { pool } = require('../database/init');
const CryptoUtils = require('../utils/crypto');
const DiffMatchPatch = require('diff-match-patch');

const router = express.Router();

// Middleware to verify key-based authentication
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
    
    console.log(`✅ Authenticated device ${deviceId} in group ${groupId}`);
    next();

  } catch (error) {
    console.error('Key auth error:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
};

// Get changes since last sync (group-isolated)
router.get('/changes', verifyKeyAuth, async (req, res) => {
  try {
    const { since } = req.query;
    const groupId = req.syncGroupId;
    const deviceId = req.deviceId;

    console.log(`🔍 Getting changes for device ${deviceId} since: ${since || 'beginning'}`);

    let query = `
      SELECT n.*, se.event_type, se.created_at as event_time
      FROM notes n
      JOIN sync_events se ON n.id = se.note_id
      WHERE n.sync_group_id = $1 AND se.device_id != $2
    `;
    const params = [groupId, deviceId];

    if (since) {
      query += ` AND se.created_at > $3`;
      params.push(since);
      console.log(`🔍 Filtering events after: ${since}`);
    }

    query += ` ORDER BY se.created_at ASC`;

    console.log(`🔍 Running query with params: ${JSON.stringify(params)}`);
    const result = await pool.query(query, params);

    console.log(`📥 Found ${result.rows.length} total changes`);
    if (result.rows.length > 0) {
      console.log(`📥 Sample change: ${result.rows[0].title} from ${result.rows[0].device_id} at ${result.rows[0].event_time}`);
    }
    console.log(`📥 Returning ${result.rows.length} changes for group ${groupId} (excluding device ${deviceId})`);
    
    res.json({
      changes: result.rows,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Get changes error:', error);
    res.status(500).json({ error: 'Failed to get changes' });
  }
});

// Push changes to server (group-isolated)
router.post('/push', verifyKeyAuth, async (req, res) => {
  try {
    const { notes } = req.body;
    const groupId = req.syncGroupId;
    const keyFingerprint = req.keyFingerprint;
    const deviceId = req.deviceId;

    if (!Array.isArray(notes) || notes.length === 0) {
      return res.status(400).json({ error: 'Notes array is required' });
    }

    console.log(`📤 Pushing ${notes.length} notes for group ${groupId}`);

    const client = await pool.connect();
    const results = [];

    try {
      await client.query('BEGIN');

      for (const note of notes) {
        const { localId, serverId, title, content, eventType, createdAt, updatedAt, imageUrls, hasImages } = note;

        if (eventType === 'create') {
          console.log('Creating note with params:', {
            groupId, title, content: content || '', deviceId, keyFingerprint, localId, createdAt, updatedAt, imageUrls: imageUrls || [], hasImages: hasImages || false
          });
          
          // Create new note
          const noteResult = await client.query(`
            INSERT INTO notes (sync_group_id, title, content, device_id, key_fingerprint, local_id, created_at, updated_at, images, has_images)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING id, created_at, updated_at
          `, [groupId, title, content || '', deviceId, keyFingerprint, localId, createdAt, updatedAt, JSON.stringify(imageUrls || []), hasImages || false]);

          const newNoteId = noteResult.rows[0].id;

          // Create sync event
          await client.query(`
            INSERT INTO sync_events (sync_group_id, note_id, event_type, device_id, key_fingerprint)
            VALUES ($1, $2, 'create', $3, $4)
          `, [groupId, newNoteId, deviceId, keyFingerprint]);

          results.push({
            localId,
            serverId: newNoteId,
            status: 'created',
            createdAt: noteResult.rows[0].created_at,
            updatedAt: noteResult.rows[0].updated_at
          });

        } else if (eventType === 'update' && serverId) {
          // Update existing note (only if it belongs to this group)
          const updateResult = await client.query(`
            UPDATE notes 
            SET title = $1, content = $2, updated_at = $3, version = version + 1, images = $4, has_images = $5
            WHERE id = $6 AND sync_group_id = $7
            RETURNING id, updated_at, version
          `, [title, content || '', updatedAt, JSON.stringify(imageUrls || []), hasImages || false, serverId, groupId]);

          if (updateResult.rows.length > 0) {
            // Create sync event
            await client.query(`
              INSERT INTO sync_events (sync_group_id, note_id, event_type, device_id, key_fingerprint)
              VALUES ($1, $2, 'update', $3, $4)
            `, [groupId, serverId, deviceId, keyFingerprint]);

            results.push({
              localId,
              serverId,
              status: 'updated',
              updatedAt: updateResult.rows[0].updated_at,
              version: updateResult.rows[0].version
            });
          } else {
            results.push({
              localId,
              serverId,
              status: 'not_found'
            });
          }
        } else if (eventType === 'patch' && serverId) {
          // Apply differential patch to existing note
          try {
            console.log(`🔄 Applying patch to note ${serverId}`);
            
            // First, get the current content from database
            const currentResult = await client.query(`
              SELECT content FROM notes 
              WHERE id = $1 AND sync_group_id = $2
            `, [serverId, groupId]);

            if (currentResult.rows.length === 0) {
              console.error(`❌ Note ${serverId} not found for patch application`);
              results.push({
                localId,
                serverId,
                status: 'patch_failed',
                error: 'Note not found'
              });
              continue;
            }

            const currentContent = currentResult.rows[0].content || '';
            const patchText = note.patch;
            
            if (!patchText) {
              console.error(`❌ No patch provided for note ${serverId}`);
              results.push({
                localId,
                serverId,
                status: 'patch_failed',
                error: 'No patch provided'
              });
              continue;
            }

            // Apply patch using DiffMatchPatch
            const dmp = new DiffMatchPatch();
            const patches = dmp.patch_fromText(patchText);
            const patchResults = dmp.patch_apply(patches, currentContent);

            if (patchResults.length >= 2) {
              const newContent = patchResults[0];
              const successList = patchResults[1];

              // Check if all patches applied successfully
              const allSucceeded = successList.every(success => success);

              if (allSucceeded) {
                console.log(`✅ Patch applied successfully to note ${serverId}`);
                
                // Update the note with the new content
                const updateResult = await client.query(`
                  UPDATE notes 
                  SET content = $1, updated_at = $2, version = version + 1
                  WHERE id = $3 AND sync_group_id = $4
                  RETURNING id, updated_at, version
                `, [newContent, new Date().toISOString(), serverId, groupId]);

                if (updateResult.rows.length > 0) {
                  // Create sync event
                  await client.query(`
                    INSERT INTO sync_events (sync_group_id, note_id, event_type, device_id, key_fingerprint)
                    VALUES ($1, $2, 'patch', $3, $4)
                  `, [groupId, serverId, deviceId, keyFingerprint]);

                  results.push({
                    localId,
                    serverId,
                    status: 'patched',
                    updatedAt: updateResult.rows[0].updated_at,
                    version: updateResult.rows[0].version
                  });
                } else {
                  results.push({
                    localId,
                    serverId,
                    status: 'patch_failed',
                    error: 'Database update failed'
                  });
                }
              } else {
                console.warn(`⚠️ Some patches failed for note ${serverId}`);
                results.push({
                  localId,
                  serverId,
                  status: 'patch_failed',
                  error: 'Patch application failed'
                });
              }
            } else {
              console.error(`❌ Invalid patch result for note ${serverId}`);
              results.push({
                localId,
                serverId,
                status: 'patch_failed',
                error: 'Invalid patch result'
              });
            }
          } catch (patchError) {
            console.error(`❌ Error applying patch to note ${serverId}:`, patchError);
            results.push({
              localId,
              serverId,
              status: 'patch_failed',
              error: patchError.message
            });
          }
        }
      }

      await client.query('COMMIT');

      console.log(`✅ Successfully pushed ${results.length} notes`);
      
      res.json({
        success: true,
        results,
        timestamp: new Date().toISOString()
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Push error:', error);
    res.status(500).json({ error: 'Failed to push changes' });
  }
});

// Get all notes for initial sync (group-isolated)
router.get('/notes', verifyKeyAuth, async (req, res) => {
  try {
    const groupId = req.syncGroupId;

    const result = await pool.query(`
      SELECT id, title, content, created_at, updated_at, version, images, has_images
      FROM notes
      WHERE sync_group_id = $1
      ORDER BY updated_at DESC
    `, [groupId]);

    console.log(`📋 Returning ${result.rows.length} notes for group ${groupId}`);

    res.json({
      notes: result.rows,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Get notes error:', error);
    res.status(500).json({ error: 'Failed to get notes' });
  }
});

module.exports = router;
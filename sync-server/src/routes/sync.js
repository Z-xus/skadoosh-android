const express = require('express');
const { pool } = require('../database/init');
const CryptoUtils = require('../utils/crypto');

const router = express.Router();

// Middleware to verify key-based authentication
const verifyKeyAuth = async (req, res, next) => {
  try {
    const fingerprint = req.headers['key-fingerprint'];
    const challenge = req.headers['challenge'];
    const signature = req.headers['signature'];
    
    if (!fingerprint || !challenge || !signature) {
      return res.status(401).json({ 
        error: 'Key authentication required',
        required_headers: ['key-fingerprint', 'challenge', 'signature']
      });
    }

    // Get public key and group info
    const keyResult = await pool.query(
      'SELECT public_key, sync_group_id, device_id FROM public_keys WHERE key_fingerprint = $1',
      [fingerprint]
    );

    if (keyResult.rows.length === 0) {
      return res.status(401).json({ error: 'Key not found' });
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

    let query = `
      SELECT n.*, se.event_type, se.created_at as event_time
      FROM notes n
      JOIN sync_events se ON n.id = se.note_id
      WHERE n.sync_group_id = $1
    `;
    const params = [groupId];

    if (since) {
      query += ` AND se.created_at > $2`;
      params.push(since);
    }

    query += ` ORDER BY se.created_at ASC`;

    const result = await pool.query(query, params);

    console.log(`📥 Returning ${result.rows.length} changes for group ${groupId}`);
    
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
        const { localId, serverId, title, content, eventType, createdAt, updatedAt } = note;

        if (eventType === 'create') {
          console.log('Creating note with params:', {
            groupId, title, content: content || '', deviceId, keyFingerprint, localId, createdAt, updatedAt
          });
          
          // Create new note
          const noteResult = await client.query(`
            INSERT INTO notes (sync_group_id, title, content, device_id, key_fingerprint, local_id, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING id, created_at, updated_at
          `, [groupId, title, content || '', deviceId, keyFingerprint, localId, createdAt, updatedAt]);

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
            SET title = $1, content = $2, updated_at = $3, version = version + 1
            WHERE id = $4 AND sync_group_id = $5
            RETURNING id, updated_at, version
          `, [title, content || '', updatedAt, serverId, groupId]);

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
      SELECT id, title, content, created_at, updated_at, version
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
const express = require('express');
const { pool } = require('../database/init');
const CryptoUtils = require('../utils/crypto');
const crypto = require('crypto');

const router = express.Router();

// Generate a unique Share ID
function generateShareId(username) {
  const suffix = crypto.randomBytes(3).toString('base64').replace(/[+/=]/g, '').toLowerCase();
  return `${username}#${suffix}`;
}

// Register new user with device
router.post('/register', async (req, res) => {
  try {
    const { username, deviceName, publicKey, deviceId } = req.body;
    
    if (!username || !deviceName || !publicKey || !deviceId) {
      return res.status(400).json({ 
        error: 'Missing required fields',
        required: ['username', 'deviceName', 'publicKey', 'deviceId']
      });
    }

    console.log(`📝 Registering new user: ${username} with device: ${deviceName}`);
    console.log('🔍 Pool status:', pool ? 'Available' : 'Not available');

    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');

      // Check if username already exists
      const existingUser = await client.query(
        'SELECT id FROM users WHERE username = $1',
        [username]
      );

      let userId;
      let shareId;

      if (existingUser.rows.length > 0) {
        // User exists, just add new device
        userId = existingUser.rows[0].id;
        const userResult = await client.query(
          'SELECT share_id FROM users WHERE id = $1',
          [userId]
        );
        shareId = userResult.rows[0].share_id;
        console.log(`👤 User ${username} already exists, adding new device`);
      } else {
        // Create new user
        shareId = generateShareId(username);
        
        // Ensure Share ID is unique
        let shareIdExists = true;
        let attempts = 0;
        while (shareIdExists && attempts < 5) {
          const existing = await client.query(
            'SELECT id FROM users WHERE share_id = $1',
            [shareId]
          );
          if (existing.rows.length === 0) {
            shareIdExists = false;
          } else {
            shareId = generateShareId(username);
            attempts++;
          }
        }
        
        if (shareIdExists) {
          throw new Error('Unable to generate unique Share ID');
        }

        const userResult = await client.query(
          'INSERT INTO users (username, share_id) VALUES ($1, $2) RETURNING id',
          [username, shareId]
        );
        userId = userResult.rows[0].id;
        console.log(`✨ Created new user: ${username} with Share ID: ${shareId}`);
      }

      // Check if device already exists for this user
      const existingDevice = await client.query(
        'SELECT id FROM devices_new WHERE user_id = $1 AND device_id = $2',
        [userId, deviceId]
      );

      if (existingDevice.rows.length > 0) {
        return res.status(409).json({
          error: 'Device already registered for this user'
        });
      }

      // Create sync group for this user (devices will join each other's groups through pairing)
      const syncGroupId = crypto.randomUUID();

      // Generate key fingerprint for sync compatibility
      const keyFingerprint = CryptoUtils.getFingerprint(publicKey);

      // Register device in devices_new table (device pairing system)
      const deviceResult = await client.query(`
        INSERT INTO devices_new (user_id, device_id, device_name, public_key, sync_group_id)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id
      `, [userId, deviceId, deviceName, publicKey, syncGroupId]);

      const newDeviceId = deviceResult.rows[0].id;

      // Also register in public_keys table for sync system compatibility
      // Check if this fingerprint + device combination already exists
      const existingKey = await client.query(
        'SELECT id FROM public_keys WHERE key_fingerprint = $1 AND device_id = $2',
        [keyFingerprint, deviceId]
      );

      if (existingKey.rows.length === 0) {
        // Create sync group in old format if it doesn't exist
        const syncGroupName = `group_${keyFingerprint}`;
        
        let syncGroupDbId;
        const existingSyncGroup = await client.query(
          'SELECT id FROM sync_groups WHERE group_name = $1',
          [syncGroupName]
        );

        if (existingSyncGroup.rows.length === 0) {
          const syncGroupResult = await client.query(
            'INSERT INTO sync_groups (group_name) VALUES ($1) RETURNING id',
            [syncGroupName]
          );
          syncGroupDbId = syncGroupResult.rows[0].id;
        } else {
          syncGroupDbId = existingSyncGroup.rows[0].id;
        }

        // Insert into public_keys table for sync system compatibility
        await client.query(`
          INSERT INTO public_keys (key_fingerprint, public_key, device_id, device_name, sync_group_id)
          VALUES ($1, $2, $3, $4, $5)
        `, [keyFingerprint, publicKey, deviceId, deviceName, syncGroupDbId]);
        
        console.log(`🔑 Added key to sync system: ${keyFingerprint}`);
      }

      await client.query('COMMIT');

      console.log(`🔐 Device registered: ${deviceName} for user ${username}`);

      res.status(201).json({
        message: 'Device registered successfully',
        shareId: shareId,
        syncGroupId: syncGroupId,
        deviceId: newDeviceId,
        user: {
          username: username,
          shareId: shareId
        }
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Registration failed', details: error.message });
  }
});

// Lookup user by Share ID
router.get('/lookup/:shareId', async (req, res) => {
  try {
    const { shareId } = req.params;
    
    console.log(`🔍 Looking up Share ID: ${shareId}`);

    const result = await pool.query(
      'SELECT username, share_id, created_at FROM users WHERE share_id = $1',
      [shareId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Share ID not found' });
    }

    const user = result.rows[0];
    res.json({
      username: user.username,
      shareId: user.share_id,
      memberSince: user.created_at
    });

  } catch (error) {
    console.error('Lookup error:', error);
    res.status(500).json({ error: 'Lookup failed' });
  }
});

// Get user's devices
router.get('/devices', async (req, res) => {
  try {
    const { shareId } = req.query;
    
    if (!shareId) {
      return res.status(400).json({ error: 'Share ID required' });
    }

    const result = await pool.query(`
      SELECT d.device_name, d.device_id, d.created_at, d.last_seen, u.username
      FROM devices_new d
      JOIN users u ON d.user_id = u.id
      WHERE u.share_id = $1
      ORDER BY d.last_seen DESC
    `, [shareId]);

    res.json({
      devices: result.rows
    });

  } catch (error) {
    console.error('Get devices error:', error);
    res.status(500).json({ error: 'Failed to get devices' });
  }
});

module.exports = router;
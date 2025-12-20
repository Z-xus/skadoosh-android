const express = require('express');
const { pool } = require('../database/init');
const CryptoUtils = require('../utils/crypto');

const router = express.Router();

// Create or join a sync group with public key
router.post('/join-group', async (req, res) => {
  try {
    const { groupName, publicKey, deviceName, deviceId } = req.body;
    
    if (!groupName || !publicKey || !deviceId) {
      return res.status(400).json({ error: 'Group name, public key, and device ID are required' });
    }

    if (!CryptoUtils.isValidGroupName(groupName)) {
      return res.status(400).json({ error: 'Invalid group name format' });
    }

    const fingerprint = CryptoUtils.getFingerprint(publicKey);
    
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');

      // Create sync group if it doesn't exist
      let groupResult = await client.query(
        'SELECT id FROM sync_groups WHERE group_name = $1',
        [groupName]
      );

      let groupId;
      if (groupResult.rows.length === 0) {
        const newGroup = await client.query(
          'INSERT INTO sync_groups (group_name) VALUES ($1) RETURNING id',
          [groupName]
        );
        groupId = newGroup.rows[0].id;
      } else {
        groupId = groupResult.rows[0].id;
      }

      // Check if this key + device combination is already registered
      const keyDeviceCheck = await client.query(
        'SELECT id FROM public_keys WHERE key_fingerprint = $1 AND device_id = $2',
        [fingerprint, deviceId]
      );

      if (keyDeviceCheck.rows.length > 0) {
        // Update existing key-device combination
        await client.query(
          'UPDATE public_keys SET last_used = NOW(), device_name = COALESCE($3, device_name) WHERE key_fingerprint = $1 AND device_id = $2',
          [fingerprint, deviceId, deviceName]
        );
        console.log(`Updated existing key-device: ${fingerprint} + ${deviceId}`);
      } else {
        // Register new device with this key
        await client.query(
          'INSERT INTO public_keys (sync_group_id, public_key, key_fingerprint, device_id, device_name) VALUES ($1, $2, $3, $4, $5)',
          [groupId, publicKey, fingerprint, deviceId, deviceName]
        );
        console.log(`Registered new device: ${deviceId} with key: ${fingerprint}`);
      }

      await client.query('COMMIT');

      res.json({
        success: true,
        groupId,
        fingerprint,
        message: 'Successfully joined sync group'
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Join group error:', error);
    console.error('Error details:', {
      message: error.message,
      code: error.code,
      detail: error.detail,
      constraint: error.constraint
    });
    res.status(500).json({ 
      error: 'Failed to join sync group',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Authenticate with challenge-response
router.post('/challenge', async (req, res) => {
  try {
    const { fingerprint, deviceId } = req.body;
    
    if (!fingerprint || !deviceId) {
      return res.status(400).json({ error: 'Key fingerprint and device ID are required' });
    }

    // Check if key-device combination exists
    const keyResult = await pool.query(
      'SELECT public_key, sync_group_id FROM public_keys WHERE key_fingerprint = $1 AND device_id = $2',
      [fingerprint, deviceId]
    );

    if (keyResult.rows.length === 0) {
      return res.status(401).json({ error: 'Key-device combination not found' });
    }

    // Generate challenge
    const challenge = CryptoUtils.createChallenge();
    
    // Store challenge temporarily (in production, use Redis or similar)
    // For now, we'll include it in the response and verify immediately
    
    res.json({
      challenge,
      groupId: keyResult.rows[0].sync_group_id
    });

  } catch (error) {
    console.error('Challenge error:', error);
    res.status(500).json({ error: 'Challenge generation failed' });
  }
});

// Verify challenge response
router.post('/verify', async (req, res) => {
  try {
    const { fingerprint, challenge, signature } = req.body;
    
    if (!fingerprint || !challenge || !signature) {
      return res.status(400).json({ error: 'Fingerprint, challenge, and signature are required' });
    }

    // Get public key
    const keyResult = await pool.query(
      'SELECT public_key, sync_group_id FROM public_keys WHERE key_fingerprint = $1',
      [fingerprint]
    );

    if (keyResult.rows.length === 0) {
      return res.status(401).json({ error: 'Key not found' });
    }

    const publicKey = keyResult.rows[0].public_key;
    const groupId = keyResult.rows[0].sync_group_id;

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

    res.json({
      success: true,
      groupId,
      message: 'Authentication successful'
    });

  } catch (error) {
    console.error('Verification error:', error);
    res.status(500).json({ error: 'Verification failed' });
  }
});

// Get group info
router.get('/group/:groupId', async (req, res) => {
  try {
    const { groupId } = req.params;
    
    // Get group details
    const groupResult = await pool.query(
      'SELECT group_name, created_at FROM sync_groups WHERE id = $1',
      [groupId]
    );

    if (groupResult.rows.length === 0) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Get group members (devices)
    const membersResult = await pool.query(
      'SELECT device_name, key_fingerprint, last_used FROM public_keys WHERE sync_group_id = $1 ORDER BY last_used DESC',
      [groupId]
    );

    res.json({
      group: groupResult.rows[0],
      members: membersResult.rows
    });

  } catch (error) {
    console.error('Get group error:', error);
    res.status(500).json({ error: 'Failed to get group info' });
  }
});

module.exports = router;
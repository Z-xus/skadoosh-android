const express = require('express');
const { pool } = require('../database/init');
const crypto = require('crypto');
const CryptoUtils = require('../utils/crypto');

const router = express.Router();

// Middleware to verify device authentication (simplified for now)
const verifyDevice = async (req, res, next) => {
  try {
    const deviceId = req.headers['device-id'];
    const shareId = req.headers['share-id'];
    
    if (!deviceId || !shareId) {
      return res.status(401).json({ 
        error: 'Authentication required',
        required_headers: ['device-id', 'share-id']
      });
    }
    
    if (!deviceId || !shareId) {
      return res.status(401).json({ 
        error: 'Authentication required',
        required_headers: ['device-id', 'share-id']
      });
    }

    // Get device info
    const result = await pool.query(`
      SELECT d.id, d.user_id, d.sync_group_id, u.username, u.share_id
      FROM devices_new d
      JOIN users u ON d.user_id = u.id
      WHERE d.device_id = $1 AND u.share_id = $2
    `, [deviceId, shareId]);

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid device or share ID' });
    }

    req.device = result.rows[0];
    next();

  } catch (error) {
    console.error('Device auth error:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
};

// Send pairing request to another user
router.post('/pair-request', verifyDevice, async (req, res) => {
  try {
    const { targetShareId } = req.body;
    
    if (!targetShareId) {
      return res.status(400).json({ error: 'Target Share ID required' });
    }

    console.log(`📤 Device pairing request: ${req.device.share_id} → ${targetShareId}`);

    // Can't pair with yourself
    if (targetShareId === req.device.share_id) {
      return res.status(400).json({ error: 'Cannot pair with your own devices' });
    }

    // Check if target user exists
    const targetUser = await pool.query(
      'SELECT id, username FROM users WHERE share_id = $1',
      [targetShareId]
    );

    if (targetUser.rows.length === 0) {
      return res.status(404).json({ error: 'Target user not found' });
    }

    const targetUserId = targetUser.rows[0].id;

    // Check if request already exists
    const existingRequest = await pool.query(`
      SELECT id, status FROM device_requests 
      WHERE from_device_id = $1 AND to_user_id = $2 AND status = 'pending'
    `, [req.device.id, targetUserId]);

    if (existingRequest.rows.length > 0) {
      return res.status(409).json({ error: 'Pairing request already sent' });
    }

    // Check if devices are already paired
    const alreadyPaired = await pool.query(`
      SELECT pd.id FROM paired_devices pd
      JOIN devices_new d1 ON (pd.device1_id = d1.id OR pd.device2_id = d1.id)
      JOIN devices_new d2 ON (pd.device1_id = d2.id OR pd.device2_id = d2.id)
      WHERE d1.id = $1 AND d2.user_id = $2
    `, [req.device.id, targetUserId]);

    if (alreadyPaired.rows.length > 0) {
      return res.status(409).json({ error: 'Devices already paired' });
    }

    // Create pairing request
    const requestResult = await pool.query(`
      INSERT INTO device_requests (from_device_id, to_user_id, status)
      VALUES ($1, $2, 'pending')
      RETURNING id, created_at
    `, [req.device.id, targetUserId]);

    console.log(`✅ Pairing request sent from ${req.device.username} to ${targetUser.rows[0].username}`);

    res.status(201).json({
      message: 'Pairing request sent successfully',
      requestId: requestResult.rows[0].id,
      targetUser: targetUser.rows[0].username,
      sentAt: requestResult.rows[0].created_at
    });

  } catch (error) {
    console.error('Send pairing request error:', error);
    res.status(500).json({ error: 'Failed to send pairing request' });
  }
});

// Get pending pairing requests for current user
router.get('/requests', verifyDevice, async (req, res) => {
  try {
    console.log(`📥 Getting pairing requests for ${req.device.username}`);

    const requests = await pool.query(`
      SELECT 
        dr.id,
        dr.status,
        dr.created_at,
        u_from.username as from_username,
        u_from.share_id as from_share_id,
        d_from.device_name as from_device_name
      FROM device_requests dr
      JOIN devices_new d_from ON dr.from_device_id = d_from.id
      JOIN users u_from ON d_from.user_id = u_from.id
      WHERE dr.to_user_id = $1
      ORDER BY dr.created_at DESC
    `, [req.device.user_id]);

    res.json({
      requests: requests.rows
    });

  } catch (error) {
    console.error('Get requests error:', error);
    res.status(500).json({ error: 'Failed to get pairing requests' });
  }
});

// Accept or reject pairing request
router.post('/requests/:requestId/respond', verifyDevice, async (req, res) => {
  try {
    const { requestId } = req.params;
    const { action } = req.body; // 'accept' or 'reject'

    if (!['accept', 'reject'].includes(action)) {
      return res.status(400).json({ error: 'Action must be "accept" or "reject"' });
    }

    console.log(`🔄 ${req.device.username} ${action}ing pairing request ${requestId}`);

    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Get request details
      const requestResult = await client.query(`
        SELECT dr.*, d.id as from_device_id, d.sync_group_id as from_sync_group
        FROM device_requests dr
        JOIN devices_new d ON dr.from_device_id = d.id
        WHERE dr.id = $1 AND dr.to_user_id = $2 AND dr.status = 'pending'
      `, [requestId, req.device.user_id]);

      if (requestResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pairing request not found or already processed' });
      }

      const request = requestResult.rows[0];

      // Update request status
      await client.query(`
        UPDATE device_requests 
        SET status = $1, responded_at = NOW()
        WHERE id = $2
      `, [action, requestId]);

      let sharedGroupId = null;

      if (action === 'accept') {
        // Create shared sync group
        sharedGroupId = crypto.randomUUID();
        
        // Get all devices from both users
        const myDevices = await client.query(
          'SELECT id FROM devices_new WHERE user_id = $1',
          [req.device.user_id]
        );

        const theirDevices = await client.query(
          'SELECT id FROM devices_new WHERE id = $1',
          [request.from_device_id]
        );

        // Create pairing relationships between all devices
        for (const myDevice of myDevices.rows) {
          for (const theirDevice of theirDevices.rows) {
            await client.query(`
              INSERT INTO paired_devices (device1_id, device2_id, shared_group_id)
              VALUES ($1, $2, $3)
            `, [myDevice.id, theirDevice.id, sharedGroupId]);
          }
        }

        // Update sync group for all involved devices  
        await client.query(`
          UPDATE devices_new 
          SET sync_group_id = $1
          WHERE user_id = $2 OR id = $3
        `, [sharedGroupId, req.device.user_id, request.from_device_id]);

        // Also update the sync system (public_keys table) to use the same shared group
        // Get all devices that should share the sync group
        const allPairedDevices = await client.query(`
          SELECT d.device_id, d.public_key, d.device_name
          FROM devices_new d
          WHERE d.sync_group_id = $1
        `, [sharedGroupId]);

        // Update public_keys table for sync compatibility
        for (const device of allPairedDevices.rows) {
          const keyFingerprint = CryptoUtils.getFingerprint(device.public_key);
          const syncGroupName = `group_${sharedGroupId.replace(/-/g, '')}`;
          
          // Ensure sync group exists
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

          // Update or insert in public_keys table
          const existingKey = await client.query(
            'SELECT id FROM public_keys WHERE key_fingerprint = $1 AND device_id = $2',
            [keyFingerprint, device.device_id]
          );

          if (existingKey.rows.length > 0) {
            // Update existing record
            await client.query(`
              UPDATE public_keys 
              SET sync_group_id = $1
              WHERE key_fingerprint = $2 AND device_id = $3
            `, [syncGroupDbId, keyFingerprint, device.device_id]);
          } else {
            // Insert new record
            await client.query(`
              INSERT INTO public_keys (key_fingerprint, public_key, device_id, device_name, sync_group_id)
              VALUES ($1, $2, $3, $4, $5)
            `, [keyFingerprint, device.public_key, device.device_id, device.device_name, syncGroupDbId]);
          }
        }

        console.log(`🎉 Devices paired successfully! Shared group: ${sharedGroupId}`);
        console.log(`🔄 Updated sync system for paired devices`);
      }

      await client.query('COMMIT');

      res.json({
        message: `Pairing request ${action}ed successfully`,
        action: action,
        sharedGroupId: action === 'accept' ? sharedGroupId : null
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('Respond to request error:', error);
    res.status(500).json({ error: 'Failed to respond to pairing request' });
  }
});

// Get paired devices for current user
router.get('/paired', verifyDevice, async (req, res) => {
  try {
    console.log(`🔗 Getting paired devices for ${req.device.username}`);

    const pairedDevices = await pool.query(`
      SELECT DISTINCT
        d.device_name,
        d.device_id,
        d.last_seen,
        u.username,
        u.share_id,
        pd.paired_at,
        pd.shared_group_id
      FROM paired_devices pd
      JOIN devices_new d ON (d.id = pd.device1_id OR d.id = pd.device2_id)
      JOIN users u ON d.user_id = u.id
      WHERE (pd.device1_id IN (SELECT id FROM devices_new WHERE user_id = $1) 
             OR pd.device2_id IN (SELECT id FROM devices_new WHERE user_id = $1))
      AND u.id != $1
      ORDER BY pd.paired_at DESC
    `, [req.device.user_id]);

    res.json({
      pairedDevices: pairedDevices.rows
    });

  } catch (error) {
    console.error('Get paired devices error:', error);
    res.status(500).json({ error: 'Failed to get paired devices' });
  }
});

// Admin endpoint to migrate existing paired devices to sync system
router.post('/admin/migrate-to-sync', async (req, res) => {
  try {
    const { adminKey } = req.body;
    
    // Simple admin key check (you can make this more secure)
    if (adminKey !== process.env.ADMIN_KEY && adminKey !== 'migrate123') {
      return res.status(401).json({ error: 'Invalid admin key' });
    }

    console.log('🔄 Starting migration of existing paired devices to sync system...');

    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');

      // Get all devices that have been paired (have a shared sync_group_id)
      const pairedDevices = await client.query(`
        SELECT DISTINCT d.sync_group_id, d.device_id, d.public_key, d.device_name
        FROM devices_new d
        WHERE d.sync_group_id IS NOT NULL
        ORDER BY d.sync_group_id
      `);

      console.log(`Found ${pairedDevices.rows.length} paired devices to migrate`);

      const processedGroups = new Set();
      let migratedCount = 0;

      for (const device of pairedDevices.rows) {
        const { sync_group_id, device_id, public_key, device_name } = device;
        
        if (processedGroups.has(sync_group_id)) {
          continue; // Skip if we already processed this group
        }

        console.log(`Processing sync group: ${sync_group_id}`);

        // Get all devices in this sync group
        const groupDevices = await client.query(`
          SELECT device_id, public_key, device_name
          FROM devices_new 
          WHERE sync_group_id = $1
        `, [sync_group_id]);

        // Create sync group name for old system
        const syncGroupName = `group_${sync_group_id.replace(/-/g, '')}`;
        
        // Ensure sync group exists in old system
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
          console.log(`Created sync group: ${syncGroupName}`);
        } else {
          syncGroupDbId = existingSyncGroup.rows[0].id;
          console.log(`Using existing sync group: ${syncGroupName}`);
        }

        // Add all devices in this group to public_keys table
        for (const groupDevice of groupDevices.rows) {
          const keyFingerprint = CryptoUtils.getFingerprint(groupDevice.public_key);
          
          // Check if already exists
          const existingKey = await client.query(
            'SELECT id FROM public_keys WHERE key_fingerprint = $1 AND device_id = $2',
            [keyFingerprint, groupDevice.device_id]
          );

          if (existingKey.rows.length === 0) {
            await client.query(`
              INSERT INTO public_keys (key_fingerprint, public_key, device_id, device_name, sync_group_id)
              VALUES ($1, $2, $3, $4, $5)
            `, [keyFingerprint, groupDevice.public_key, groupDevice.device_id, groupDevice.device_name, syncGroupDbId]);
            
            console.log(`Added device to sync system: ${groupDevice.device_name} (${keyFingerprint.substring(0, 8)}...)`);
            migratedCount++;
          } else {
            console.log(`Device already in sync system: ${groupDevice.device_name}`);
          }
        }

        processedGroups.add(sync_group_id);
      }

      await client.query('COMMIT');
      
      console.log(`✅ Migration completed successfully! Migrated ${migratedCount} devices`);
      
      res.json({
        message: 'Migration completed successfully',
        totalDevices: pairedDevices.rows.length,
        migratedDevices: migratedCount,
        processedGroups: processedGroups.size
      });
      
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
    
  } catch (error) {
    console.error('Migration failed:', error);
    res.status(500).json({ 
      error: 'Migration failed', 
      details: error.message 
    });
  }
});

module.exports = router;
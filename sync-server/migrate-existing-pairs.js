const { pool, initDatabase } = require('./src/database/init');
const CryptoUtils = require('./src/utils/crypto');

async function migratePairedDevicesToSyncSystem() {
  console.log('🔄 Migrating existing paired devices to sync system...');
  
  // Initialize database first
  await initDatabase();
  
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
        } else {
          console.log(`Device already in sync system: ${groupDevice.device_name}`);
        }
      }

      processedGroups.add(sync_group_id);
    }

    await client.query('COMMIT');
    console.log('✅ Migration completed successfully!');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Migration failed:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Run migration
migratePairedDevicesToSyncSystem()
  .then(() => {
    console.log('🎉 All paired devices migrated to sync system');
    process.exit(0);
  })
  .catch(error => {
    console.error('Failed to migrate devices:', error);
    process.exit(1);
  });
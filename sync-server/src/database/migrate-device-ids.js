#!/usr/bin/env node

/**
 * Migration script to fix device ID uniqueness issue
 * This updates the database schema to support multiple devices per key
 */

const { pool } = require('./init');

async function migrateDeviceIds() {
  const client = await pool.connect();
  
  try {
    console.log('🔧 Starting device ID migration...');
    
    await client.query('BEGIN');
    
    // Step 1: Check if we already have the new schema
    const constraintCheck = await client.query(`
      SELECT constraint_name 
      FROM information_schema.table_constraints 
      WHERE table_name = 'public_keys' 
      AND constraint_name LIKE '%key_fingerprint%'
      AND constraint_type = 'UNIQUE'
    `);
    
    if (constraintCheck.rows.length > 0) {
      console.log('🗑️ Removing old unique constraint on key_fingerprint...');
      
      // Drop the old unique constraint on key_fingerprint
      await client.query(`
        ALTER TABLE public_keys 
        DROP CONSTRAINT IF EXISTS public_keys_key_fingerprint_key
      `);
    }
    
    // Step 2: Add new unique constraint on (key_fingerprint, device_id)
    try {
      await client.query(`
        ALTER TABLE public_keys 
        ADD CONSTRAINT public_keys_key_fingerprint_device_id_key 
        UNIQUE (key_fingerprint, device_id)
      `);
      console.log('✅ Added new unique constraint on (key_fingerprint, device_id)');
    } catch (error) {
      if (error.message.includes('already exists')) {
        console.log('ℹ️ Unique constraint already exists, skipping...');
      } else {
        throw error;
      }
    }
    
    // Step 3: Update any existing records that might have 'flutter_device' as device_id
    // Give them unique device IDs
    const duplicateDevices = await client.query(`
      SELECT id, device_id, created_at 
      FROM public_keys 
      WHERE device_id = 'flutter_device' 
      ORDER BY created_at
    `);
    
    if (duplicateDevices.rows.length > 1) {
      console.log(`🔄 Updating ${duplicateDevices.rows.length} duplicate device records...`);
      
      for (let i = 0; i < duplicateDevices.rows.length; i++) {
        const record = duplicateDevices.rows[i];
        const newDeviceId = i === 0 
          ? 'flutter_device' // Keep the first one as-is
          : `flutter_device_${i + 1}_${Date.now()}`; // Make others unique
          
        await client.query(
          'UPDATE public_keys SET device_id = $1 WHERE id = $2',
          [newDeviceId, record.id]
        );
        
        console.log(`   Updated device ${record.id} to: ${newDeviceId}`);
      }
    }
    
    await client.query('COMMIT');
    console.log('✅ Device ID migration completed successfully!');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    client.release();
  }
}

// Run migration if called directly
if (require.main === module) {
  migrateDeviceIds()
    .then(() => {
      console.log('🎉 Migration completed!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { migrateDeviceIds };

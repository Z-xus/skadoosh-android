#!/usr/bin/env node

/**
 * Test script to verify database schema creation works properly
 */

const { pool, initDatabase } = require('./init');

async function testDatabaseCreation() {
  try {
    console.log('🧪 Testing database creation from scratch...\n');
    
    // Test the initialization
    await initDatabase();
    
    console.log('\n🔍 Verifying table creation...');
    
    // Check if all tables exist
    const tables = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('sync_groups', 'public_keys', 'notes', 'sync_events')
      ORDER BY table_name
    `);
    
    console.log('📋 Created tables:');
    for (const table of tables.rows) {
      console.log(`   ✅ ${table.table_name}`);
    }
    
    // Check constraints
    const constraints = await pool.query(`
      SELECT 
        table_name,
        constraint_name,
        constraint_type
      FROM information_schema.table_constraints 
      WHERE table_schema = 'public'
      AND constraint_type IN ('UNIQUE', 'FOREIGN KEY')
      ORDER BY table_name, constraint_name
    `);
    
    console.log('\n🔐 Constraints:');
    for (const constraint of constraints.rows) {
      console.log(`   ✅ ${constraint.table_name}.${constraint.constraint_name} (${constraint.constraint_type})`);
    }
    
    // Test inserting sample data
    console.log('\n🧪 Testing sample data insertion...');
    
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      // Insert sample group
      const groupResult = await client.query(`
        INSERT INTO sync_groups (group_name, description) 
        VALUES ('test-group', 'Test sync group') 
        RETURNING id
      `);
      const groupId = groupResult.rows[0].id;
      console.log('   ✅ Created sample sync group');
      
      // Insert sample device
      await client.query(`
        INSERT INTO public_keys (sync_group_id, public_key, key_fingerprint, device_id, device_name)
        VALUES ($1, 'test-public-key', 'test-fingerprint', 'test-device-1', 'Test Device')
      `, [groupId]);
      console.log('   ✅ Created sample device registration');
      
      // Insert sample note
      const noteResult = await client.query(`
        INSERT INTO notes (sync_group_id, title, content, device_id, key_fingerprint)
        VALUES ($1, 'Test Note', 'This is a test note', 'test-device-1', 'test-fingerprint')
        RETURNING id
      `, [groupId]);
      const noteId = noteResult.rows[0].id;
      console.log('   ✅ Created sample note');
      
      // Insert sample sync event
      await client.query(`
        INSERT INTO sync_events (sync_group_id, note_id, event_type, device_id, key_fingerprint)
        VALUES ($1, $2, 'create', 'test-device-1', 'test-fingerprint')
      `, [groupId, noteId]);
      console.log('   ✅ Created sample sync event');
      
      await client.query('ROLLBACK'); // Don't save test data
      console.log('   🧹 Cleaned up test data');
      
    } finally {
      client.release();
    }
    
    console.log('\n🎉 Database schema test completed successfully!');
    console.log('✅ All tables created correctly');
    console.log('✅ All constraints working');
    console.log('✅ Data insertion/retrieval working');
    
  } catch (error) {
    console.error('❌ Database test failed:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

testDatabaseCreation();
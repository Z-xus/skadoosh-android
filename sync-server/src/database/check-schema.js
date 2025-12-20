#!/usr/bin/env node

/**
 * Database schema checker for device ID migration
 * Run this to check if migration is needed
 */

const { pool } = require('../database/init');

async function checkSchemaStatus() {
  try {
    console.log('🔍 Checking database schema status...\n');
    
    // Check if public_keys table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'public_keys'
      )
    `);
    
    if (!tableCheck.rows[0].exists) {
      console.log('❌ public_keys table does not exist');
      console.log('💡 Run: npm run migrate');
      return;
    }
    
    console.log('✅ public_keys table exists');
    
    // Check constraints
    const constraints = await pool.query(`
      SELECT 
        constraint_name, 
        constraint_type,
        table_name
      FROM information_schema.table_constraints 
      WHERE table_name = 'public_keys' 
      AND constraint_type = 'UNIQUE'
    `);
    
    console.log('\n🔐 Current unique constraints:');
    for (const constraint of constraints.rows) {
      console.log(`   - ${constraint.constraint_name}`);
    }
    
    // Check specific constraints
    const oldConstraint = constraints.rows.find(c => 
      c.constraint_name.includes('key_fingerprint') && 
      !c.constraint_name.includes('device_id')
    );
    
    const newConstraint = constraints.rows.find(c => 
      c.constraint_name.includes('key_fingerprint') && 
      c.constraint_name.includes('device_id')
    );
    
    console.log('\n📋 Schema Status:');
    
    if (oldConstraint && !newConstraint) {
      console.log('❌ OLD SCHEMA DETECTED');
      console.log('   - Has: UNIQUE(key_fingerprint) - BLOCKS multiple devices per key');
      console.log('   - Missing: UNIQUE(key_fingerprint, device_id)');
      console.log('\n💡 MIGRATION NEEDED:');
      console.log('   Run: npm run migrate:device-ids');
    } else if (!oldConstraint && newConstraint) {
      console.log('✅ NEW SCHEMA DETECTED');
      console.log('   - Has: UNIQUE(key_fingerprint, device_id) - ALLOWS multiple devices per key');
      console.log('   - Migration already applied');
    } else if (oldConstraint && newConstraint) {
      console.log('⚠️  MIXED SCHEMA DETECTED');
      console.log('   - Has both old and new constraints');
      console.log('   - Migration partially applied');
      console.log('\n💡 FIX NEEDED:');
      console.log('   Run: npm run migrate:device-ids');
    } else {
      console.log('❓ UNKNOWN SCHEMA STATE');
      console.log('   - No relevant constraints found');
    }
    
    // Check data
    const deviceCount = await pool.query(`
      SELECT 
        key_fingerprint,
        device_id,
        device_name,
        COUNT(*) as count
      FROM public_keys 
      GROUP BY key_fingerprint, device_id, device_name
      ORDER BY key_fingerprint
    `);
    
    console.log('\n📊 Current device registrations:');
    if (deviceCount.rows.length === 0) {
      console.log('   (No devices registered)');
    } else {
      for (const row of deviceCount.rows) {
        console.log(`   - ${row.device_id} (${row.device_name || 'No name'}) - Key: ${row.key_fingerprint.substring(0, 8)}...`);
      }
    }
    
  } catch (error) {
    console.error('❌ Schema check failed:', error);
  } finally {
    await pool.end();
  }
}

checkSchemaStatus();
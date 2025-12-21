const { Pool } = require('pg');

// Ensure we load environment variables
require('dotenv').config();

let pool;

// Try to use DATABASE_URL first (for Supabase/Heroku), then fall back to individual vars
if (process.env.DATABASE_URL) {
  pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  });
} else {
  pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'skadoosh_sync',
    password: process.env.DB_PASSWORD || 'password',
    port: process.env.DB_PORT || 5432,
    ssl: false, // No SSL for local development
  });
}

async function migrateToDevicePairing() {
  const client = await pool.connect();
  
  try {
    console.log('🔄 Starting migration to device pairing system...');
    console.log('🔍 Connected to database:', (await client.query('SELECT current_database(), current_user')).rows[0]);
    
    await client.query('BEGIN');

    // Create users table
    console.log('📋 Creating users table...');
    const usersResult = await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        username VARCHAR(50) UNIQUE NOT NULL,
        share_id VARCHAR(60) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    console.log('✅ Users table result:', usersResult);

    // Create new devices table (enhanced version)
    console.log('🔄 Creating enhanced devices table...');
    const devicesResult = await client.query(`
      CREATE TABLE IF NOT EXISTS devices_new (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id),
        device_id VARCHAR(100) NOT NULL,
        device_name VARCHAR(100) NOT NULL,
        public_key TEXT NOT NULL,
        sync_group_id UUID NOT NULL,
        created_at TIMESTAMP DEFAULT NOW(),
        last_seen TIMESTAMP DEFAULT NOW(),
        UNIQUE(user_id, device_id)
      )
    `);
    console.log('✅ Devices table result:', devicesResult);

    // Create device requests table
    console.log('📤 Creating device_requests table...');
    const requestsResult = await client.query(`
      CREATE TABLE IF NOT EXISTS device_requests (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        from_device_id UUID REFERENCES devices_new(id),
        to_user_id UUID REFERENCES users(id),
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT NOW(),
        responded_at TIMESTAMP
      )
    `);
    console.log('✅ Requests table result:', requestsResult);

    // Create paired_devices table (many-to-many relationship)
    console.log('🔗 Creating paired_devices table...');
    const pairedResult = await client.query(`
      CREATE TABLE IF NOT EXISTS paired_devices (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        device1_id UUID REFERENCES devices_new(id),
        device2_id UUID REFERENCES devices_new(id),
        shared_group_id UUID NOT NULL,
        paired_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(device1_id, device2_id)
      )
    `);
    console.log('✅ Paired devices table result:', pairedResult);

    // Create indexes for performance
    console.log('⚡ Creating indexes...');
    await client.query('CREATE INDEX IF NOT EXISTS idx_users_share_id ON users(share_id)');
    await client.query('CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices_new(user_id)');
    await client.query('CREATE INDEX IF NOT EXISTS idx_devices_sync_group ON devices_new(sync_group_id)');
    await client.query('CREATE INDEX IF NOT EXISTS idx_requests_to_user ON device_requests(to_user_id)');
    await client.query('CREATE INDEX IF NOT EXISTS idx_requests_status ON device_requests(status)');
    await client.query('CREATE INDEX IF NOT EXISTS idx_paired_devices_group ON paired_devices(shared_group_id)');

    await client.query('COMMIT');
    
    console.log('✅ Device pairing migration completed successfully!');
    console.log('📊 New tables created:');
    console.log('   - users (for Share IDs)');
    console.log('   - devices_new (enhanced device management)');
    console.log('   - device_requests (pairing requests)');
    console.log('   - paired_devices (device relationships)');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

migrateToDevicePairing().catch(console.error);
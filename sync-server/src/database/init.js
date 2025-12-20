const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'skadoosh_sync',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

const initDatabase = async () => {
  try {
    console.log('🔄 Initializing database with key-based authentication...');
    
    // Only drop tables in development/test mode with explicit flag
    const shouldReset = process.env.DB_RESET === 'true' || process.env.NODE_ENV === 'test';
    
    if (shouldReset) {
      console.log('🗑️  DEVELOPMENT MODE: Dropping existing tables...');
      await pool.query('DROP TABLE IF EXISTS sync_events CASCADE');
      await pool.query('DROP TABLE IF EXISTS notes CASCADE');
      await pool.query('DROP TABLE IF EXISTS users CASCADE');
      await pool.query('DROP TABLE IF EXISTS public_keys CASCADE');
      await pool.query('DROP TABLE IF EXISTS sync_groups CASCADE');
    } else {
      console.log('✅ PRODUCTION MODE: Preserving existing data...');
    }

    // Create sync groups table (for user isolation) - only if it doesn't exist
    console.log('📋 Ensuring sync_groups table exists...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS sync_groups (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        group_name VARCHAR(255) UNIQUE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        description TEXT
      );
    `);

    // Create public keys table (for key-based auth) - only if it doesn't exist
    console.log('🔑 Ensuring public_keys table exists...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS public_keys (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sync_group_id UUID NOT NULL REFERENCES sync_groups(id) ON DELETE CASCADE,
        public_key TEXT NOT NULL,
        key_fingerprint VARCHAR(255) NOT NULL,
        device_id VARCHAR(255) NOT NULL,
        device_name VARCHAR(255),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        UNIQUE(key_fingerprint, device_id)
      );
    `);

    // Create notes table for group-based isolation - only if it doesn't exist
    console.log('📝 Ensuring notes table exists...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sync_group_id UUID NOT NULL REFERENCES sync_groups(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        content TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        device_id VARCHAR(255) NOT NULL,
        key_fingerprint VARCHAR(255) NOT NULL,
        local_id VARCHAR(255),
        version INTEGER DEFAULT 1
      );
    `);

    // Create sync events for group-based tracking - only if it doesn't exist
    console.log('🔄 Ensuring sync_events table exists...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS sync_events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sync_group_id UUID NOT NULL REFERENCES sync_groups(id) ON DELETE CASCADE,
        note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
        event_type VARCHAR(20) NOT NULL CHECK (event_type IN ('create', 'update')),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        device_id VARCHAR(255) NOT NULL,
        key_fingerprint VARCHAR(255) NOT NULL
      );
    `);

    // Create indexes for performance - only if they don't exist
    console.log('⚡ Ensuring indexes exist...');
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_notes_sync_group_id ON notes(sync_group_id);
      CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at);
      CREATE INDEX IF NOT EXISTS idx_notes_key_fingerprint ON notes(key_fingerprint);
      CREATE INDEX IF NOT EXISTS idx_public_keys_sync_group_id ON public_keys(sync_group_id);
      CREATE INDEX IF NOT EXISTS idx_public_keys_fingerprint ON public_keys(key_fingerprint);
      CREATE INDEX IF NOT EXISTS idx_sync_events_sync_group_id ON sync_events(sync_group_id);
    `);

    if (shouldReset) {
      console.log('✅ Database reset and initialized successfully with key-based authentication');
    } else {
      console.log('✅ Database schema verified and ready for key-based authentication');
    }
  } catch (error) {
    console.error('❌ Error initializing database:', error);
    throw error;
  }
};

module.exports = { pool, initDatabase };
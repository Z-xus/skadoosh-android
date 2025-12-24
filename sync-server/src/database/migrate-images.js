const { pool } = require('./init');

const migrateImages = async () => {
  try {
    console.log('🖼️  Starting image support migration...');

    // Check if columns already exist
    const checkResult = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'notes' 
      AND column_name IN ('images', 'has_images');
    `);

    const existingColumns = checkResult.rows.map(row => row.column_name);

    // Add images JSONB column to notes table if it doesn't exist
    if (!existingColumns.includes('images')) {
      await pool.query(`
        ALTER TABLE notes 
        ADD COLUMN images JSONB DEFAULT '[]'::jsonb;
      `);
      console.log('✅ Added images column to notes table');
    } else {
      console.log('ℹ️  Images column already exists in notes table');
    }

    // Add has_images boolean column for efficient querying
    if (!existingColumns.includes('has_images')) {
      await pool.query(`
        ALTER TABLE notes 
        ADD COLUMN has_images BOOLEAN DEFAULT FALSE;
      `);
      console.log('✅ Added has_images column to notes table');
    } else {
      console.log('ℹ️  has_images column already exists in notes table');
    }

    // Create images table for detailed image tracking
    await pool.query(`
      CREATE TABLE IF NOT EXISTS images (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sync_group_id UUID NOT NULL REFERENCES sync_groups(id) ON DELETE CASCADE,
        note_id UUID REFERENCES notes(id) ON DELETE CASCADE,
        filename VARCHAR(255) NOT NULL,
        original_filename VARCHAR(255) NOT NULL,
        storage_path TEXT NOT NULL,
        public_url TEXT,
        content_type VARCHAR(100) NOT NULL,
        file_size INTEGER NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        device_id VARCHAR(255) NOT NULL,
        key_fingerprint VARCHAR(255) NOT NULL,
        is_deleted BOOLEAN DEFAULT FALSE,
        deleted_at TIMESTAMP WITH TIME ZONE
      );
    `);
    console.log('✅ Created images table');

    // Create indexes for performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_images_sync_group_id ON images(sync_group_id);
      CREATE INDEX IF NOT EXISTS idx_images_note_id ON images(note_id);
      CREATE INDEX IF NOT EXISTS idx_images_storage_path ON images(storage_path);
      CREATE INDEX IF NOT EXISTS idx_notes_has_images ON notes(has_images);
    `);
    console.log('✅ Created image indexes');

    // Create sync events for image operations
    await pool.query(`
      ALTER TABLE sync_events 
      DROP CONSTRAINT IF EXISTS sync_events_event_type_check;
    `);

    await pool.query(`
      ALTER TABLE sync_events 
      ADD CONSTRAINT sync_events_event_type_check 
      CHECK (event_type IN ('create', 'update', 'patch', 'image_upload', 'image_delete'));
    `);
    console.log('✅ Updated sync_events table to support image operations');

    console.log('🎉 Image support migration completed successfully!');
  } catch (error) {
    console.error('❌ Error during image migration:', error);
    throw error;
  }
};

// Run migration if this file is executed directly
if (require.main === module) {
  migrateImages()
    .then(() => {
      console.log('✅ Migration completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { migrateImages };
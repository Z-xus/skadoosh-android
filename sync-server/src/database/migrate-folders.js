#!/usr/bin/env node

/**
 * Migration to add folder support to notes table
 * 
 * Adds three new fields to the notes table:
 * - folder_path: The folder path (e.g., "Work/Projects")
 * - file_name: The note's filename (e.g., "MyNote.md")
 * - relative_path: The full relative path (e.g., "Work/Projects/MyNote.md")
 * 
 * Usage:
 *   node sync-server/src/database/migrate-folders.js
 */

const { pool } = require('./init');

async function migrateFolders() {
  try {
    console.log('🔄 Starting folder migration...');

    // Check if columns already exist
    const checkResult = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'notes' 
      AND column_name IN ('folder_path', 'file_name', 'relative_path')
    `);

    const existingColumns = checkResult.rows.map(row => row.column_name);
    console.log(`📋 Existing folder columns: ${existingColumns.join(', ') || 'none'}`);

    // Add missing columns
    if (!existingColumns.includes('folder_path')) {
      console.log('➕ Adding folder_path column...');
      await pool.query(`
        ALTER TABLE notes 
        ADD COLUMN folder_path TEXT DEFAULT ''
      `);
      console.log('✅ folder_path column added');
    } else {
      console.log('✓ folder_path column already exists');
    }

    if (!existingColumns.includes('file_name')) {
      console.log('➕ Adding file_name column...');
      await pool.query(`
        ALTER TABLE notes 
        ADD COLUMN file_name TEXT DEFAULT ''
      `);
      console.log('✅ file_name column added');
    } else {
      console.log('✓ file_name column already exists');
    }

    if (!existingColumns.includes('relative_path')) {
      console.log('➕ Adding relative_path column...');
      await pool.query(`
        ALTER TABLE notes 
        ADD COLUMN relative_path TEXT DEFAULT ''
      `);
      console.log('✅ relative_path column added');
    } else {
      console.log('✓ relative_path column already exists');
    }

    // Create index on folder_path for efficient folder queries
    console.log('➕ Creating index on folder_path...');
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_notes_folder_path ON notes(folder_path)
    `);
    console.log('✅ Index on folder_path created');

    console.log('✅ Folder migration completed successfully!');

  } catch (error) {
    console.error('❌ Folder migration failed:', error);
    throw error;
  }
}

// Run migration if called directly
if (require.main === module) {
  migrateFolders()
    .then(() => {
      console.log('👋 Migration complete, closing connection...');
      return pool.end();
    })
    .then(() => {
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration error:', error);
      pool.end().finally(() => {
        process.exit(1);
      });
    });
}

module.exports = { migrateFolders };

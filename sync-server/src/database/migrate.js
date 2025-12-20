#!/usr/bin/env node

/**
 * Database migration script for Skadoosh Sync Server
 * 
 * Usage:
 *   npm run migrate           - Apply migrations (safe for production)
 *   npm run migrate:reset     - Reset database (DANGER: deletes all data)
 * 
 * Environment variables:
 *   DB_RESET=true             - Force reset database (DANGER)
 *   NODE_ENV=development      - Enable development mode features
 */

const { pool, initDatabase } = require('./init');

async function main() {
  const command = process.argv[2];
  
  try {
    if (command === 'reset') {
      console.log('⚠️  WARNING: This will DELETE ALL DATA in your database!');
      console.log('⚠️  This operation is IRREVERSIBLE!');
      console.log('⚠️  Only proceed if you are absolutely sure.');
      console.log('');
      
      // Add a delay to let users read the warning
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // Set reset flag and run initialization
      process.env.DB_RESET = 'true';
      await initDatabase();
      console.log('🗑️  Database has been reset successfully');
      
    } else {
      // Safe migration - only create missing tables/indexes
      console.log('🔄 Running safe database migration...');
      await initDatabase();
      console.log('✅ Migration completed successfully');
    }
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
    console.log('👋 Database connection closed');
  }
}

main();
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { pool } = require('./db');

async function migrate() {
  const client = await pool.connect();
  try {
    console.log('🚀 Starting database migration...');
    const sqlFile = path.join(__dirname, '../../migrations/001_init.sql');
    if (!fs.existsSync(sqlFile)) {
      throw new Error(`Migration file not found: ${sqlFile}`);
    }
    const sql = fs.readFileSync(sqlFile, 'utf8');
    await client.query(sql);
    console.log('✅ Migration completed successfully!');

    // Seed default admin user
    const bcrypt = require('bcryptjs');
    const passwordHash = await bcrypt.hash('admin123', 12);
    await client.query(`
      INSERT INTO users (name, email, password_hash, role)
      VALUES ($1, $2, $3, 'admin')
      ON CONFLICT (email) DO NOTHING
    `, ['Super Admin', 'admin@hotel.com', passwordHash]);
    console.log('✅ Default admin user created: admin@hotel.com / admin123');
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    pool.end();
  }
}

migrate();

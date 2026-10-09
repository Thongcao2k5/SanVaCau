import 'dotenv/config';
import pg from 'pg';
import { readFile } from 'node:fs/promises';

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
try {
  await client.connect();
  const tables = (await client.query("SELECT tablename FROM pg_tables WHERE schemaname='public'")).rows;
  if (tables.length) throw new Error('Use an empty database for snapshot import. Existing tables will not be overwritten.');
  await client.query('BEGIN');
  await client.query(await readFile(new URL('../../database/schema.sql', import.meta.url), 'utf8'));
  await client.query(await readFile(new URL('../../database/data.sql', import.meta.url), 'utf8'));
  await client.query('COMMIT');
  console.log('Demo database restored successfully.');
} catch (error) {
  await client.query('ROLLBACK').catch(() => {});
  throw error;
} finally { await client.end(); }

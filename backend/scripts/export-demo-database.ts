import 'dotenv/config';
import pg from 'pg';
import { hash } from 'bcryptjs';
import { Prisma } from '@prisma/client';
import { writeFile } from 'node:fs/promises';

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
try {
  await client.connect();
  await client.query('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY');
  const tables: string[] = (await client.query("SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename")).rows.map(r => r.tablename);
  const relations = (await client.query("SELECT child.relname AS child, parent.relname AS parent FROM pg_constraint fk JOIN pg_class child ON child.oid=fk.conrelid JOIN pg_class parent ON parent.oid=fk.confrelid WHERE fk.contype='f' AND child.relnamespace='public'::regnamespace")).rows;
  const ordered: string[] = [];
  while (ordered.length < tables.length) {
    const available = tables.find(t => !ordered.includes(t) && relations.filter(r => r.child === t && r.parent !== t).every(r => ordered.includes(r.parent)));
    if (!available) throw new Error('Database has a circular dependency');
    ordered.push(available);
  }
  const lines = ['-- Shareable local database snapshot. Accounts and addresses are demo data.', '-- Demo passwords: Admin123456 for ADMIN; Customer123456 for other users.', '-- Auth OTPs, audit logs, contact/support messages and private settings are excluded.', ''];
  const counts: Record<string, number> = {};
  const demoHash = await hash('Customer123456', 10);
  const adminHash = await hash('Admin123456', 10);
  for (const table of ordered) {
    if (['auth_otp', 'audit_log', 'contact_message', 'support_ticket', 'support_ticket_message'].includes(table)) continue;
    const model = Prisma.dmmf.datamodel.models.find(m => (m.dbName ?? m.name) === table);
    if (!model) continue;
    const allowed = new Set(model.fields.filter(f => f.kind !== 'object').map(f => f.dbName ?? f.name));
    const columns: string[] = (await client.query("SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name=$1 ORDER BY ordinal_position", [table])).rows.map(r => r.column_name).filter(c => allowed.has(c));
    const projection = columns.map(c => `${pg.escapeIdentifier(c)}::text AS ${pg.escapeIdentifier(c)}`).join(', ');
    // Legacy local inventory is per branch; the app schema uses global stock.
    const query = table === 'inventory'
      ? 'SELECT MIN(id)::text AS id, product_variant_id::text, SUM(quantity)::text AS quantity, MAX(updated_at)::text AS updated_at FROM inventory GROUP BY product_variant_id ORDER BY MIN(id)'
      : `SELECT ${projection} FROM ${pg.escapeIdentifier(table)} ORDER BY ${pg.escapeIdentifier(columns.includes('id') ? 'id' : columns[0])}`;
    const rows = (await client.query(query)).rows;
    counts[table] = 0;
    for (const row of rows) {
      if (table === 'system_setting' && row.is_public !== 'true') continue;
      if (table === 'app_user') {
        row.email = row.role === 'ADMIN' ? `admin-${row.id}@example.com` : `customer-${row.id}@example.com`;
        row.full_name = row.role === 'ADMIN' ? 'Demo Admin' : `Khách hàng demo ${row.id}`;
        row.phone = null;
        row.password_hash = row.role === 'ADMIN' ? adminHash : demoHash;
      }
      if (table === 'customer_address') {
        Object.assign(row, { recipient_name: 'Khách hàng demo', phone: '0900000000', address_line: 'Địa chỉ demo', ward: null, district: null, city: 'TP.HCM', note: null });
      }
      const values = columns.map(c => row[c] === null ? 'NULL' : pg.escapeLiteral(row[c])).join(', ');
      lines.push(`INSERT INTO ${pg.escapeIdentifier(table)} (${columns.map(pg.escapeIdentifier).join(', ')}) VALUES (${values});`);
      counts[table]++;
    }
    if (columns.includes('id')) {
      lines.push(`SELECT setval(pg_get_serial_sequence('${table}', 'id'), COALESCE(MAX(id), 1), MAX(id) IS NOT NULL) FROM ${pg.escapeIdentifier(table)};`);
    }
  }
  await client.query('COMMIT');
  await writeFile(new URL('../../database/data.sql', import.meta.url), lines.join('\n') + '\n');
  await writeFile(new URL('../../database/counts.json', import.meta.url), JSON.stringify(counts, null, 2) + '\n');
  console.log(counts);
} finally { await client.end(); }

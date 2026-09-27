import { prisma } from "../../src/lib/prisma.js";
import { assertSafeTestDatabase } from "./db-safety.js";

export const clearDatabase = async () => {
  assertSafeTestDatabase(process.env.DATABASE_URL);

  const tablenames = await prisma.$queryRaw<
    Array<{ tablename: string }>
  >`SELECT tablename FROM pg_tables WHERE schemaname='public'`;

  const tables = tablenames
    .map(({ tablename }) => tablename)
    .filter((name) => name !== "_prisma_migrations")
    .map((name) => `"public"."${name}"`)
    .join(", ");

  try {
    if (tables.length > 0) {
      await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${tables} CASCADE;`);
    }
  } catch (error) {
    console.error("Error clearing database:", error);
    throw error;
  }
};

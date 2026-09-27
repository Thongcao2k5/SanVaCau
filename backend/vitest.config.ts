import dotenv from "dotenv";
import { defineConfig } from "vitest/config";
import { assertSafeTestDatabase } from "./tests/helpers/db-safety.js";

dotenv.config({ path: ".env.test", override: true });
assertSafeTestDatabase(process.env.DATABASE_URL);

export default defineConfig({
  test: {
    environment: "node",
    setupFiles: ["tests/setup/test-env.ts"],
    include: ["tests/integration/**/*.test.ts"],
    pool: "forks",
    fileParallelism: false,
  },
});

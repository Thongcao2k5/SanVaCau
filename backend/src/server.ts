import { app } from "./app.js";
import { env } from "./config/env.js";
import { prisma } from "./lib/prisma.js";

const server = app.listen(env.PORT, () => {
  console.log(`SanVaCau API listening on port ${env.PORT}`);
});

const shutdown = async (signal: NodeJS.Signals) => {
  console.log(`${signal} received. Shutting down server...`);

  server.close(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

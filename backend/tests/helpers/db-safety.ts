export const assertSafeTestDatabase = (databaseUrl: string | undefined) => {
  if (!databaseUrl) {
    throw new Error(
      "DATABASE_URL is missing. Copy .env.test.example to .env.test before running integration tests."
    );
  }

  let databaseName: string;

  try {
    const parsedUrl = new URL(databaseUrl);
    databaseName = decodeURIComponent(parsedUrl.pathname.replace(/^\//, ""));
  } catch {
    throw new Error("DATABASE_URL in .env.test is not a valid PostgreSQL URL.");
  }

  if (!databaseName.toLowerCase().endsWith("_test")) {
    throw new Error(
      `Integration tests require a database name ending in "_test"; received "${databaseName || "<empty>"}".`
    );
  }
};

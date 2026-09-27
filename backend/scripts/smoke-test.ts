/**
 * SanVaCau Backend Smoke Test
 *
 * Quickly verifies the most important API endpoints are responding correctly.
 * Run with: npm run smoke:test
 *
 * Prerequisites:
 *   - Backend server is running on http://localhost:3000
 *   - Admin account exists (run POST /api/auth/dev/create-admin first)
 */

// ─── Configuration ───────────────────────────────────────────────────────────

const BASE_URL = process.env.SMOKE_TEST_URL ?? "http://localhost:3000/api";
const ADMIN_EMAIL = "admin@shopvacau.com";
const ADMIN_PASSWORD = "Admin123456";

// ─── Types ───────────────────────────────────────────────────────────────────

interface TestResult {
  endpoint: string;
  method: string;
  status: number | "ERR";
  passed: boolean;
  message: string;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/** Make an HTTP request and return status + parsed JSON body. */
async function request(
  method: string,
  path: string,
  options?: { body?: Record<string, unknown>; token?: string }
): Promise<{ status: number; body: Record<string, unknown> }> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  if (options?.token) {
    headers["Authorization"] = `Bearer ${options.token}`;
  }

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: options?.body ? JSON.stringify(options.body) : undefined,
  });

  // Parse response body as JSON; fall back to empty object if parsing fails
  let body: Record<string, unknown> = {};
  try {
    body = (await res.json()) as Record<string, unknown>;
  } catch {
    // non-JSON response — leave body empty
  }

  return { status: res.status, body };
}

/** Run a single test case and return the result. */
async function runTest(
  method: string,
  path: string,
  options?: {
    token?: string;
    body?: Record<string, unknown>;
    expectedStatus?: number;
    description?: string;
  }
): Promise<TestResult> {
  const expectedStatus = options?.expectedStatus ?? 200;
  const label = options?.description ?? `${method} ${path}`;

  try {
    const { status, body } = await request(method, path, {
      body: options?.body,
      token: options?.token,
    });

    const success = (body as Record<string, unknown>).success;
    const passed = status === expectedStatus && success === true;

    return {
      endpoint: label,
      method,
      status,
      passed,
      message: passed
        ? "OK"
        : `Expected ${expectedStatus}, got ${status}${success === false ? ` — ${(body as Record<string, unknown>).message ?? "unknown error"}` : ""}`,
    };
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : "Unknown error";
    return {
      endpoint: label,
      method,
      status: "ERR",
      passed: false,
      message: `Network error: ${errorMessage}`,
    };
  }
}

// ─── Print helpers ───────────────────────────────────────────────────────────

function printResult(result: TestResult): void {
  const icon = result.passed ? "✅" : "❌";
  const status = typeof result.status === "number" ? result.status.toString() : result.status;
  const msg = result.passed ? "" : ` → ${result.message}`;
  console.log(`  ${icon}  [${status}]  ${result.endpoint}${msg}`);
}

function printSummary(results: TestResult[]): void {
  const passed = results.filter((r) => r.passed).length;
  const failed = results.filter((r) => !r.passed).length;
  const total = results.length;

  console.log("");
  console.log("═══════════════════════════════════════════════════");
  console.log(`  SMOKE TEST SUMMARY: ${passed}/${total} passed, ${failed} failed`);
  console.log("═══════════════════════════════════════════════════");

  if (failed > 0) {
    console.log("");
    console.log("  Failed tests:");
    for (const r of results.filter((r) => !r.passed)) {
      console.log(`    ❌  ${r.endpoint} → ${r.message}`);
    }
  }

  console.log("");
}

// ─── Main test runner ────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const results: TestResult[] = [];

  console.log("");
  console.log("🔥  SanVaCau Backend Smoke Test");
  console.log(`    Target: ${BASE_URL}`);
  console.log("");

  // ── Pre-check: verify server is reachable ──────────────────────────────

  try {
    await fetch(`${BASE_URL}/health`);
  } catch {
    console.error("❌  Cannot connect to the backend server.");
    console.error(`    Make sure the server is running at ${BASE_URL}`);
    console.error("    Start it with: npm run dev");
    console.error("");
    process.exit(1);
  }

  // ── Phase 1: Public endpoints ──────────────────────────────────────────

  console.log("── Phase 1: Public Endpoints ──");

  results.push(await runTest("GET", "/health", { description: "Health check" }));
  results.push(await runTest("GET", "/health/db", { description: "Database check" }));
  results.push(await runTest("GET", "/bootstrap", { description: "Bootstrap data" }));
  results.push(await runTest("GET", "/faqs?page=1&limit=5", { description: "Public FAQs" }));
  results.push(await runTest("GET", "/pages?page=1&limit=5", { description: "Public static pages" }));
  results.push(await runTest("GET", "/metadata", { description: "Metadata/enums" }));
  results.push(
    await runTest("GET", "/app-status?platform=android&version=1.0.0", {
      description: "App status",
    })
  );
  results.push(await runTest("GET", "/settings/public", { description: "Public settings" }));
  results.push(await runTest("GET", "/home", { description: "Home page data" }));
  results.push(await runTest("GET", "/categories", { description: "Categories" }));
  results.push(await runTest("GET", "/brands", { description: "Brands" }));
  results.push(await runTest("GET", "/products", { description: "Products" }));
  results.push(await runTest("GET", "/branches", { description: "Branches" }));
  results.push(await runTest("GET", "/courts", { description: "Courts" }));
  results.push(await runTest("GET", "/courts/time-slots", { description: "Time slots" }));
  results.push(await runTest("GET", "/banners", { description: "Banners" }));
  results.push(await runTest("GET", "/news", { description: "News" }));
  results.push(await runTest("GET", "/racket-services", { description: "Racket services" }));

  console.log("");

  // ── Phase 2: Auth flow ─────────────────────────────────────────────────

  console.log("── Phase 2: Auth Flow ──");

  // First, ensure admin exists by calling the dev endpoint
  const ensureAdmin = await runTest("POST", "/auth/dev/create-admin", {
    body: { password: ADMIN_PASSWORD, fullName: "Quản trị viên" },
    expectedStatus: 201,
    description: "Ensure admin account",
  });
  results.push(ensureAdmin);

  // Login as admin
  const loginResult = await request("POST", "/auth/login", {
    body: { email: ADMIN_EMAIL, password: ADMIN_PASSWORD },
  });

  let adminToken: string | null = null;

  if (loginResult.status === 200 && loginResult.body.success === true) {
    const data = loginResult.body.data as Record<string, unknown> | undefined;
    adminToken = (data?.token as string) ?? null;

    results.push({
      endpoint: "Admin login",
      method: "POST",
      status: 200,
      passed: true,
      message: "OK",
    });
  } else {
    results.push({
      endpoint: "Admin login",
      method: "POST",
      status: loginResult.status,
      passed: false,
      message: `Login failed: ${loginResult.body.message ?? "unknown"}`,
    });
  }

  // GET /api/auth/me
  if (adminToken) {
    results.push(
      await runTest("GET", "/auth/me", {
        token: adminToken,
        description: "Auth /me (admin)",
      })
    );
  } else {
    results.push({
      endpoint: "Auth /me (admin)",
      method: "GET",
      status: "ERR",
      passed: false,
      message: "Skipped — no admin token",
    });
  }

  console.log("");

  // ── Phase 3: Protected/admin endpoints ─────────────────────────────────

  console.log("── Phase 3: Admin Endpoints ──");

  if (adminToken) {
    results.push(
      await runTest("GET", "/dashboard/summary", {
        token: adminToken,
        description: "Dashboard summary",
      })
    );
    results.push(
      await runTest("GET", "/settings", {
        token: adminToken,
        description: "Settings (all)",
      })
    );
    results.push(
      await runTest("GET", "/audit-logs", {
        token: adminToken,
        description: "Audit logs",
      })
    );
    results.push(
      await runTest("GET", "/auth/admin/users?page=1&limit=5", {
        token: adminToken,
        description: "Admin user list",
      })
    );
    results.push(
      await runTest("GET", "/notifications", {
        token: adminToken,
        description: "Notifications",
      })
    );
  } else {
    const skippedEndpoints = [
      "Dashboard summary",
      "Settings (all)",
      "Audit logs",
      "Admin user list",
      "Notifications",
    ];
    for (const ep of skippedEndpoints) {
      results.push({
        endpoint: ep,
        method: "GET",
        status: "ERR",
        passed: false,
        message: "Skipped — no admin token",
      });
    }
  }

  // ── Phase 4: Error handling verification ────────────────────────────────

  console.log("");
  console.log("── Phase 4: Error Handling ──");

  // Unauthenticated access to a protected endpoint should return 401
  const unauthResult = await request("GET", "/auth/me");
  results.push({
    endpoint: "Unauthenticated → 401",
    method: "GET",
    status: unauthResult.status,
    passed: unauthResult.status === 401,
    message: unauthResult.status === 401 ? "OK" : `Expected 401, got ${unauthResult.status}`,
  });

  // Wrong credentials should return 401
  const badLoginResult = await request("POST", "/auth/login", {
    body: { email: ADMIN_EMAIL, password: "wrongpassword" },
  });
  results.push({
    endpoint: "Bad credentials → 401",
    method: "POST",
    status: badLoginResult.status,
    passed: badLoginResult.status === 401,
    message: badLoginResult.status === 401 ? "OK" : `Expected 401, got ${badLoginResult.status}`,
  });

  // ── Print all results ──────────────────────────────────────────────────

  console.log("");
  console.log("── All Results ──");
  for (const r of results) {
    printResult(r);
  }

  printSummary(results);

  // Exit with non-zero code if any test failed
  const anyFailed = results.some((r) => !r.passed);
  process.exit(anyFailed ? 1 : 0);
}

// ─── Run ─────────────────────────────────────────────────────────────────────

main().catch((err) => {
  console.error("❌  Smoke test crashed:", err);
  process.exit(1);
});

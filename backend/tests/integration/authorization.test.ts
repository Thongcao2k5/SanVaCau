import { describe, it, expect, beforeEach } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { signAuthToken } from "../../src/lib/auth.js";

describe("Authorization Flow", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  const getCustomerToken = () =>
    signAuthToken({
      id: "1001",
      email: "customer@example.com",
      role: "CUSTOMER",
      branchId: null,
    });

  const getAdminToken = () =>
    signAuthToken({
      id: "1002",
      email: "admin@example.com",
      role: "ADMIN",
      branchId: null,
    });

  const getManagerToken = () =>
    signAuthToken({
      id: "1003",
      email: "manager@example.com",
      role: "BRANCH_MANAGER",
      branchId: "1",
    });

  it("CUSTOMER cannot access ADMIN-only endpoint", async () => {
    const res = await request
      .get("/api/dashboard/summary")
      .set("Authorization", `Bearer ${getCustomerToken()}`);
    
    // Expect 403 Forbidden because they are authenticated but lack permissions
    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it("ADMIN can access ADMIN-only endpoint", async () => {
    const res = await request
      .get("/api/dashboard/summary")
      .set("Authorization", `Bearer ${getAdminToken()}`);
    
    // Expect 200 OK since they have permission (though data might be empty)
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it("BRANCH_MANAGER can access shared manager/admin endpoint", async () => {
    const res = await request
      .get("/api/dashboard/summary")
      .set("Authorization", `Bearer ${getManagerToken()}`);
    
    // The dashboard summary allows ["ADMIN", "BRANCH_MANAGER", "STAFF"]
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

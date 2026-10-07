import { describe, it, expect, beforeEach } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { createAdmin } from "../helpers/fixtures.js";

describe("Authentication Flow", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  const validCustomer = {
    email: "test@example.com",
    password: "Password123",
    fullName: "Test Customer",
    phone: "0901234567",
  };

  it("Register a customer successfully", async () => {
    const res = await request.post("/api/auth/register").send(validCustomer);
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe(validCustomer.email);
    expect(res.body.data.user.role).toBe("CUSTOMER");
    expect(res.body.data.token).toBeDefined();
  });

  it("Reject duplicate email registration", async () => {
    await request.post("/api/auth/register").send(validCustomer);
    const res = await request.post("/api/auth/register").send(validCustomer);
    expect(res.status).toBe(409); // Typically conflict
    expect(res.body.success).toBe(false);
  });

  it("Reject invalid registration data", async () => {
    const res = await request.post("/api/auth/register").send({
      email: "not-an-email",
      password: "123", // too short
    });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("Login successfully with created customer", async () => {
    await request.post("/api/auth/register").send(validCustomer);

    const res = await request.post("/api/auth/login").send({
      email: validCustomer.email,
      password: validCustomer.password,
    });
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
  });

  it("Reject wrong password", async () => {
    await request.post("/api/auth/register").send(validCustomer);

    const res = await request.post("/api/auth/login").send({
      email: validCustomer.email,
      password: "WrongPassword123",
    });
    
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it("GET /api/auth/me succeeds with valid token", async () => {
    const regRes = await request.post("/api/auth/register").send(validCustomer);
    const token = regRes.body.data.token;

    const res = await request
      .get("/api/auth/me")
      .set("Authorization", `Bearer ${token}`);
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe(validCustomer.email);
  });

  it("GET /api/auth/me returns 401 without token", async () => {
    const res = await request.get("/api/auth/me");
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it("Invalid JWT returns 401", async () => {
    const res = await request
      .get("/api/auth/me")
      .set("Authorization", "Bearer this-is-not-a-valid-jwt");
    
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it("Reject /dev/create-admin in production environment", async () => {
    const originalEnv = process.env.NODE_ENV;

    try {
      process.env.NODE_ENV = "production";

      const res = await request.post("/api/auth/dev/create-admin").send({
        password: "SomePassword123",
        fullName: "Admin",
      });

      expect(res.status).toBe(404);
    } finally {
      process.env.NODE_ENV = originalEnv;
    }
  });

  it("POST /api/auth/admin/users rejects a non-numeric branchId", async () => {
    const { token } = await createAdmin();

    const res = await request
      .post("/api/auth/admin/users")
      .set("Authorization", `Bearer ${token}`)
      .send({
        email: "staff@example.com",
        password: "Password123",
        fullName: "Test Staff",
        role: "STAFF",
        branchId: "not-a-number",
      });

    expect(res.status).toBe(400);
    expect(res.body).toEqual({
      success: false,
      message: "branchId is invalid",
    });
  });
});

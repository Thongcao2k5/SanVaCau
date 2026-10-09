import { describe, it, expect, beforeEach } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { createAdmin } from "../helpers/fixtures.js";
import { prisma } from "../../src/lib/prisma.js";

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

  const registerCustomer = async () => {
    const requestOtp = await request
      .post("/api/auth/register/request-otp")
      .send(validCustomer);
    expect(requestOtp.status).toBe(202);
    return request.post("/api/auth/register/verify-otp").send({
      email: validCustomer.email,
      code: requestOtp.body.data.debugOtp,
    });
  };

  it("Register a customer successfully", async () => {
    const res = await registerCustomer();
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe(validCustomer.email);
    expect(res.body.data.user.role).toBe("CUSTOMER");
    expect(res.body.data.token).toBeDefined();
  });

  it("Reject duplicate email registration", async () => {
    await registerCustomer();
    const res = await request.post("/api/auth/register/request-otp").send(validCustomer);
    expect(res.status).toBe(409); // Typically conflict
    expect(res.body.success).toBe(false);
  });

  it("Reject invalid registration data", async () => {
    const res = await request.post("/api/auth/register/request-otp").send({
      email: "not-an-email",
      password: "123", // too short
    });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("Reject malformed email registration", async () => {
    const res = await request.post("/api/auth/register").send({
      ...validCustomer,
      email: "not-an-email",
    });

    expect(res.status).toBe(400);
    expect(res.body).toEqual({
      success: false,
      message: "registration data is invalid",
    });
  });

  it("Login successfully with created customer", async () => {
    await registerCustomer();

    const res = await request.post("/api/auth/login").send({
      email: validCustomer.email,
      password: validCustomer.password,
    });
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
  });

  it("Login returns the mustChangePassword flag", async () => {
    await registerCustomer();
    await prisma.app_user.update({
      where: { email: validCustomer.email },
      data: { must_change_password: true },
    });

    const res = await request.post("/api/auth/login").send({
      email: validCustomer.email,
      password: validCustomer.password,
    });

    expect(res.status).toBe(200);
    expect(res.body.data.user.mustChangePassword).toBe(true);
  });

  it("Reject malformed email login", async () => {
    const res = await request.post("/api/auth/login").send({
      email: "not-an-email",
      password: validCustomer.password,
    });

    expect(res.status).toBe(400);
    expect(res.body.message).toBe("email is invalid");
  });

  it("Reject wrong password", async () => {
    await registerCustomer();

    const res = await request.post("/api/auth/login").send({
      email: validCustomer.email,
      password: "WrongPassword123",
    });
    
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it("GET /api/auth/me succeeds with valid token", async () => {
    const regRes = await registerCustomer();
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

  it("Reject changing to the current password", async () => {
    const registerResponse = await registerCustomer();

    const res = await request
      .post("/api/auth/change-password")
      .set("Authorization", `Bearer ${registerResponse.body.data.token}`)
      .send({
        currentPassword: validCustomer.password,
        newPassword: validCustomer.password,
      });

    expect(res.status).toBe(400);
    expect(res.body.message).toBe(
      "new password must be different from current password",
    );
  });

  it("Reset password with a valid email OTP", async () => {
    await registerCustomer();
    const otpResponse = await request
      .post("/api/auth/forgot-password/request-otp")
      .send({ email: validCustomer.email });

    const resetResponse = await request
      .post("/api/auth/forgot-password/reset")
      .send({
        email: validCustomer.email,
        code: otpResponse.body.data.debugOtp,
        newPassword: "NewPassword123",
      });

    expect(resetResponse.status).toBe(200);
    const loginResponse = await request.post("/api/auth/login").send({
      email: validCustomer.email,
      password: "NewPassword123",
    });
    expect(loginResponse.status).toBe(200);
  });

  it("Reject an invalid password reset OTP", async () => {
    await registerCustomer();
    await request
      .post("/api/auth/forgot-password/request-otp")
      .send({ email: validCustomer.email });

    const response = await request
      .post("/api/auth/forgot-password/reset")
      .send({
        email: validCustomer.email,
        code: "000000",
        newPassword: "NewPassword123",
      });

    expect(response.status).toBe(400);
    expect(response.body.message).toBe("OTP is invalid or expired");
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

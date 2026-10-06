import { describe, it, expect } from "vitest";
import { request } from "../helpers/app.js";

describe("Public API Endpoints", () => {
  it("GET /api/health should return 200", async () => {
    const res = await request.get("/api/health");
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toBe("SanVaCau API is running");
  });

  it("GET /api/health/db should return 200", async () => {
    const res = await request.get("/api/health/db");
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.database).toBe("connected");
  });

  it("GET /api/bootstrap should return success", async () => {
    const res = await request.get("/api/bootstrap");
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    // Even an empty DB will return arrays
    expect(res.body.data).toHaveProperty("settings");
    expect(res.body.data).toHaveProperty("banners");
  });

  it("GET /api/settings/public should return public settings", async () => {
    const res = await request.get("/api/settings/public");

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toEqual(expect.any(Object));
  });

  it("GET /api/metadata/:group should return the requested labels", async () => {
    const res = await request.get("/api/metadata/bookingStatuses");

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.bookingStatuses).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ value: "BOOKED", label: "Đã đặt" }),
      ]),
    );
  });

  it("should return expected error format for unknown routes", async () => {
    const res = await request.get("/api/unknown-route-12345");
    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBeDefined();
  });
});

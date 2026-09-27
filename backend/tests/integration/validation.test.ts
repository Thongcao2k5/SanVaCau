import { describe, it, expect } from "vitest";
import { request } from "../helpers/app.js";

describe("Validation Rules", () => {
  it("Invalid BigInt route IDs return 400 instead of 500", async () => {
    // A non-numeric ID like "abc" should be caught by validation, not crash the DB
    const res = await request.get("/api/products/abc");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("Invalid pagination values return validation error", async () => {
    const res = await request.get("/api/news?limit=-1");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("Invalid date input is rejected", async () => {
    // 2026-02-31 is an invalid date
    const res = await request.get("/api/bookings/availability?courtId=1&date=2026-02-31");
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });
});

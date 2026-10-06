import { beforeEach, describe, expect, it } from "vitest";
import { prisma } from "../../src/lib/prisma.js";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import {
  createBranch,
  createCategory,
  createCourt,
  createCustomer,
  createProduct,
} from "../helpers/fixtures.js";

describe("Personal review management", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  it("requires authentication to list personal reviews", async () => {
    const response = await request.get("/api/reviews/me");

    expect(response.status).toBe(401);
  });

  it("lists only the current user's reviews with target metadata", async () => {
    const [{ user, token }, otherCustomer, category, branch] = await Promise.all([
      createCustomer(),
      createCustomer(),
      createCategory(),
      createBranch(),
    ]);
    const [product, court] = await Promise.all([
      createProduct(category.id),
      createCourt(branch.id),
    ]);

    await prisma.review.createMany({
      data: [
        {
          user_id: user.id,
          target_type: "PRODUCT",
          target_id: product.id,
          rating: 5,
          comment: "San pham tot",
        },
        {
          user_id: user.id,
          target_type: "COURT",
          target_id: court.id,
          rating: 4,
          comment: "San sach se",
          status: "HIDDEN",
        },
        {
          user_id: otherCustomer.user.id,
          target_type: "PRODUCT",
          target_id: product.id,
          rating: 3,
        },
      ],
    });

    const response = await request
      .get("/api/reviews/me?limit=10")
      .set("Authorization", `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.data.pagination).toMatchObject({ total: 2, page: 1, limit: 10 });
    expect(response.body.data.items).toHaveLength(2);
    expect(response.body.data.items.every((item: { userId: string }) => item.userId === user.id.toString())).toBe(true);
    expect(response.body.data.items).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          targetType: "PRODUCT",
          targetId: product.id.toString(),
          target: {
            type: "PRODUCT",
            id: product.id.toString(),
            name: product.name,
          },
        }),
        expect.objectContaining({
          targetType: "COURT",
          targetId: court.id.toString(),
          target: {
            type: "COURT",
            id: court.id.toString(),
            name: court.name,
          },
        }),
      ]),
    );
  });

  it("supports filtering and pagination for personal reviews", async () => {
    const { user, token } = await createCustomer();
    const category = await createCategory();
    const [firstProduct, secondProduct] = await Promise.all([
      createProduct(category.id),
      createProduct(category.id),
    ]);

    await prisma.review.createMany({
      data: [
        { user_id: user.id, target_type: "PRODUCT", target_id: firstProduct.id, rating: 5 },
        { user_id: user.id, target_type: "PRODUCT", target_id: secondProduct.id, rating: 4 },
      ],
    });

    const response = await request
      .get("/api/reviews/me?targetType=PRODUCT&status=PUBLISHED&page=2&limit=1")
      .set("Authorization", `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body.data.items).toHaveLength(1);
    expect(response.body.data.items[0].target.type).toBe("PRODUCT");
    expect(response.body.data.pagination).toEqual({ page: 2, limit: 1, total: 2, totalPages: 2 });
  });

  it("updates the current user's review", async () => {
    const { user, token } = await createCustomer();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const review = await prisma.review.create({
      data: {
        user_id: user.id,
        target_type: "PRODUCT",
        target_id: product.id,
        rating: 5,
        comment: "Ban dau",
      },
    });

    const response = await request
      .patch(`/api/reviews/${review.id}`)
      .set("Authorization", `Bearer ${token}`)
      .send({ rating: 3, comment: "  Da cap nhat  " });

    expect(response.status).toBe(200);
    expect(response.body.data.review).toMatchObject({
      id: review.id.toString(),
      rating: 3,
      comment: "Da cap nhat",
    });
    await expect(prisma.review.findUniqueOrThrow({ where: { id: review.id } })).resolves.toMatchObject({
      rating: 3,
      comment: "Da cap nhat",
    });
  });

  it("rejects updates to another customer's review", async () => {
    const [owner, otherCustomer] = await Promise.all([createCustomer(), createCustomer()]);
    const category = await createCategory();
    const product = await createProduct(category.id);
    const review = await prisma.review.create({
      data: {
        user_id: owner.user.id,
        target_type: "PRODUCT",
        target_id: product.id,
        rating: 5,
      },
    });

    const response = await request
      .patch(`/api/reviews/${review.id}`)
      .set("Authorization", `Bearer ${otherCustomer.token}`)
      .send({ rating: 1 });

    expect(response.status).toBe(403);
    await expect(prisma.review.findUniqueOrThrow({ where: { id: review.id } })).resolves.toMatchObject({ rating: 5 });
  });

  it("validates review updates and reports a missing review", async () => {
    const { user, token } = await createCustomer();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const review = await prisma.review.create({
      data: {
        user_id: user.id,
        target_type: "PRODUCT",
        target_id: product.id,
        rating: 5,
      },
    });
    const authorization = { Authorization: `Bearer ${token}` };

    const invalidRating = await request
      .patch(`/api/reviews/${review.id}`)
      .set(authorization)
      .send({ rating: 6 });
    const longComment = await request
      .patch(`/api/reviews/${review.id}`)
      .set(authorization)
      .send({ comment: "x".repeat(1001) });
    const missingReview = await request
      .patch("/api/reviews/999999999")
      .set(authorization)
      .send({ rating: 4 });

    expect(invalidRating.status).toBe(400);
    expect(longComment.status).toBe(400);
    expect(missingReview.status).toBe(404);
  });
});

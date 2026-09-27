import { describe, it, expect, beforeEach } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { prisma } from "../../src/lib/prisma.js";
import {
  createCustomer,
  createBranch,
  createCategory,
  createProduct,
  createProductVariant,
  createInventory,
} from "../helpers/fixtures.js";

describe("Cart Flow", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  it("Customer adds an active product variant to the cart and adding the same variant updates quantity", async () => {
    const branch = await createBranch();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await createInventory(branch.id, variant.id, 10);
    
    const { token } = await createCustomer();

    // Add first time
    const res1 = await request
      .post("/api/cart/items")
      .set("Authorization", `Bearer ${token}`)
      .send({
        productVariantId: variant.id.toString(),
        quantity: 2,
      });

    expect(res1.status).toBe(200);
    expect(res1.body.success).toBe(true);
    expect(res1.body.data.cart.items.length).toBe(1);
    expect(res1.body.data.cart.items[0].quantity).toBe(2);

    // Add second time
    const res2 = await request
      .post("/api/cart/items")
      .set("Authorization", `Bearer ${token}`)
      .send({
        productVariantId: variant.id.toString(),
        quantity: 3,
      });

    expect(res2.status).toBe(200);
    expect(res2.body.data.cart.items.length).toBe(1);
    expect(res2.body.data.cart.items[0].quantity).toBe(5);
  });

  it("Customer updates cart quantity", async () => {
    const branch = await createBranch();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await createInventory(branch.id, variant.id, 10);
    
    const { token } = await createCustomer();

    const addRes = await request
      .post("/api/cart/items")
      .set("Authorization", `Bearer ${token}`)
      .send({
        productVariantId: variant.id.toString(),
        quantity: 2,
      });

    const itemId = addRes.body.data.cart.items[0].id;

    const updateRes = await request
      .patch(`/api/cart/items/${itemId}`)
      .set("Authorization", `Bearer ${token}`)
      .send({ quantity: 8 });

    expect(updateRes.status).toBe(200);
    expect(updateRes.body.data.cart.items[0].quantity).toBe(8);
  });

  it("Customer removes a cart item", async () => {
    const branch = await createBranch();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await createInventory(branch.id, variant.id, 10);
    
    const { token } = await createCustomer();

    const addRes = await request
      .post("/api/cart/items")
      .set("Authorization", `Bearer ${token}`)
      .send({
        productVariantId: variant.id.toString(),
        quantity: 2,
      });

    const itemId = addRes.body.data.cart.items[0].id;

    const deleteRes = await request
      .delete(`/api/cart/items/${itemId}`)
      .set("Authorization", `Bearer ${token}`);

    expect(deleteRes.status).toBe(200);
    expect(deleteRes.body.data.cart.items.length).toBe(0);
  });

  it("Customer clears their cart", async () => {
    const branch = await createBranch();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant1 = await createProductVariant(product.id, 50000);
    const variant2 = await createProductVariant(product.id, 60000);
    await createInventory(branch.id, variant1.id, 10);
    await createInventory(branch.id, variant2.id, 10);
    
    const { token } = await createCustomer();

    await request.post("/api/cart/items").set("Authorization", `Bearer ${token}`).send({ productVariantId: variant1.id.toString(), quantity: 1 });
    await request.post("/api/cart/items").set("Authorization", `Bearer ${token}`).send({ productVariantId: variant2.id.toString(), quantity: 1 });

    const clearRes = await request.delete("/api/cart").set("Authorization", `Bearer ${token}`);

    expect(clearRes.status).toBe(200);
    expect(clearRes.body.data.cart.items.length).toBe(0);
  });

  it("Reject zero, negative, non-integer, or otherwise invalid quantities", async () => {
    const branch = await createBranch();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await createInventory(branch.id, variant.id, 10);
    
    const { token } = await createCustomer();

    const invalidInputs = [0, -1, 1.5, "2"];

    for (const quantity of invalidInputs) {
      const res = await request
        .post("/api/cart/items")
        .set("Authorization", `Bearer ${token}`)
        .send({
          productVariantId: variant.id.toString(),
          quantity,
        });
      expect(res.status).toBe(400);
    }
  });

  it("Reject inactive products or variants", async () => {
    const branch = await createBranch();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await prisma.product_variant.update({ where: { id: variant.id }, data: { is_active: false } });
    await createInventory(branch.id, variant.id, 10);
    
    const { token } = await createCustomer();

    const res = await request
      .post("/api/cart/items")
      .set("Authorization", `Bearer ${token}`)
      .send({
        productVariantId: variant.id.toString(),
        quantity: 1,
      });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/not available/i);
  });

  it("Reject quantity greater than available inventory", async () => {
    const branch = await createBranch();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await createInventory(branch.id, variant.id, 2);
    
    const { token } = await createCustomer();

    const res = await request
      .post("/api/cart/items")
      .set("Authorization", `Bearer ${token}`)
      .send({
        productVariantId: variant.id.toString(),
        quantity: 3,
      });

    expect(res.status).toBe(400);
  });

  it("One customer cannot access or modify another customer's cart", async () => {
    const branch = await createBranch();
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await createInventory(branch.id, variant.id, 10);
    
    const { token: token1 } = await createCustomer();
    const { token: token2 } = await createCustomer();

    const addRes = await request
      .post("/api/cart/items")
      .set("Authorization", `Bearer ${token1}`)
      .send({
        productVariantId: variant.id.toString(),
        quantity: 2,
      });

    const itemId = addRes.body.data.cart.items[0].id;

    // Customer 2 tries to delete item from Customer 1's cart
    const deleteRes = await request
      .delete(`/api/cart/items/${itemId}`)
      .set("Authorization", `Bearer ${token2}`);

    // The API might return 404 because the item isn't in their cart
    expect(deleteRes.status).toBe(404);
  });

  it("Unauthenticated requests return 401", async () => {
    const res = await request.get("/api/cart");
    expect(res.status).toBe(401);
  });
});

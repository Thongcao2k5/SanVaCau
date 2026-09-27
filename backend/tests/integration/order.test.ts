import { describe, it, expect, beforeEach } from "vitest";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { prisma } from "../../src/lib/prisma.js";
import {
  createCustomer,
  createAdmin,
  createBranchManager,
  createBranch,
  createCategory,
  createProduct,
  createProductVariant,
  createInventory,
} from "../helpers/fixtures.js";

describe("Order Flow", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  const setupCart = async (token: string, branchId: bigint, quantity = 2) => {
    const category = await createCategory();
    const product = await createProduct(category.id);
    const variant = await createProductVariant(product.id, 50000);
    await createInventory(branchId, variant.id, 10);
    
    await request
      .post("/api/cart/items")
      .set("Authorization", `Bearer ${token}`)
      .send({
        productVariantId: variant.id.toString(),
        quantity,
      });
      
    return { variant, product };
  };

  it("Customer creates an order from valid cart items, backend calculates totals, inventory decreases, cart clears", async () => {
    const branch = await createBranch();
    const { token, user } = await createCustomer();
    const { variant } = await setupCart(token, branch.id, 2);

    const initialInventory = await prisma.inventory.findFirst({
      where: { product_variant_id: variant.id, branch_id: branch.id }
    });

    const res = await request
      .post("/api/orders")
      .set("Authorization", `Bearer ${token}`)
      .send({ branchId: branch.id.toString() });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.order.totalAmount).toBe("100000"); // 50000 * 2

    // Inventory decreases
    const postInventory = await prisma.inventory.findFirst({
      where: { product_variant_id: variant.id, branch_id: branch.id }
    });
    expect(postInventory!.quantity).toBe(initialInventory!.quantity - 2);

    // Cart is empty
    const cartRes = await request.get("/api/cart").set("Authorization", `Bearer ${token}`);
    expect(cartRes.body.data.cart.items.length).toBe(0);
  });

  it("Reject order creation from an empty cart", async () => {
    const branch = await createBranch();
    const { token } = await createCustomer();

    const res = await request
      .post("/api/orders")
      .set("Authorization", `Bearer ${token}`)
      .send({ branchId: branch.id.toString() });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/cart is empty/i);
  });

  it("Reject insufficient inventory and ensure no partial data is created", async () => {
    const branch = await createBranch();
    const { token } = await createCustomer();
    
    // Add 2 items to cart
    const { variant } = await setupCart(token, branch.id, 2);
    
    // Manually reduce inventory to 1
    await prisma.inventory.updateMany({
      where: { product_variant_id: variant.id, branch_id: branch.id },
      data: { quantity: 1 }
    });

    const initialOrderCount = await prisma.customer_order.count();
    const initialOrderItemCount = await prisma.order_item.count();
    const initialCartItemCount = await prisma.cart_item.count();

    const res = await request
      .post("/api/orders")
      .set("Authorization", `Bearer ${token}`)
      .send({ branchId: branch.id.toString() });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/not enough stock/i);

    // Verify rollback
    const postOrderCount = await prisma.customer_order.count();
    expect(postOrderCount).toBe(initialOrderCount);
    expect(await prisma.order_item.count()).toBe(initialOrderItemCount);
    expect(await prisma.cart_item.count()).toBe(initialCartItemCount);

    const postInventory = await prisma.inventory.findFirst({
      where: { product_variant_id: variant.id, branch_id: branch.id }
    });
    expect(postInventory!.quantity).toBe(1); // not reduced further
  });

  it("Reject inactive product variants", async () => {
    const branch = await createBranch();
    const { token } = await createCustomer();
    const { variant } = await setupCart(token, branch.id, 2);
    
    // Deactivate variant
    await prisma.product_variant.update({ where: { id: variant.id }, data: { is_active: false } });

    const res = await request
      .post("/api/orders")
      .set("Authorization", `Bearer ${token}`)
      .send({ branchId: branch.id.toString() });

    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/no longer available/i);
  });

  it("Customer can view only their own orders", async () => {
    const branch = await createBranch();
    const { token: token1 } = await createCustomer();
    const { token: token2 } = await createCustomer();
    
    await setupCart(token1, branch.id, 1);
    
    const postRes = await request
      .post("/api/orders")
      .set("Authorization", `Bearer ${token1}`)
      .send({ branchId: branch.id.toString() });
      
    const orderId = postRes.body.data.order.id;

    const getRes1 = await request.get(`/api/orders/me/${orderId}`).set("Authorization", `Bearer ${token1}`);
    expect(getRes1.status).toBe(200);

    const getRes2 = await request.get(`/api/orders/me/${orderId}`).set("Authorization", `Bearer ${token2}`);
    expect(getRes2.status).toBe(404);
  });

  it("Branch manager access is limited to the assigned branch", async () => {
    const branch1 = await createBranch();
    const branch2 = await createBranch();
    const { token: custToken } = await createCustomer();
    const { token: managerToken } = await createBranchManager(branch1.id);
    
    await setupCart(custToken, branch1.id, 1);
    const post1 = await request.post("/api/orders").set("Authorization", `Bearer ${custToken}`).send({ branchId: branch1.id.toString() });
    const order1Id = post1.body.data.order.id;

    await setupCart(custToken, branch2.id, 1);
    const post2 = await request.post("/api/orders").set("Authorization", `Bearer ${custToken}`).send({ branchId: branch2.id.toString() });
    const order2Id = post2.body.data.order.id;

    // View orders
    const getRes = await request.get("/api/orders").set("Authorization", `Bearer ${managerToken}`);
    expect(getRes.status).toBe(200);
    expect(getRes.body.data.orders.length).toBe(1);
    expect(getRes.body.data.orders[0].id).toBe(order1Id);

    // Try to update order from another branch
    const patchRes = await request
      .patch(`/api/orders/${order2Id}/status`)
      .set("Authorization", `Bearer ${managerToken}`)
      .send({ status: "READY_FOR_PICKUP" });
    
    expect(patchRes.status).toBe(403);
  });

  it("Admin can access permitted management endpoints", async () => {
    const branch = await createBranch();
    const { token: custToken } = await createCustomer();
    const { token: adminToken } = await createAdmin();
    
    await setupCart(custToken, branch.id, 1);
    await request.post("/api/orders").set("Authorization", `Bearer ${custToken}`).send({ branchId: branch.id.toString() });

    const getRes = await request.get("/api/orders").set("Authorization", `Bearer ${adminToken}`);
    expect(getRes.status).toBe(200);
    expect(getRes.body.data.orders.length).toBeGreaterThan(0);
  });

  it("Test valid and invalid order status transitions", async () => {
    const branch = await createBranch();
    const { token: custToken } = await createCustomer();
    const { token: adminToken } = await createAdmin();
    
    const { variant } = await setupCart(custToken, branch.id, 2);
    const postRes = await request.post("/api/orders").set("Authorization", `Bearer ${custToken}`).send({ branchId: branch.id.toString() });
    const orderId = postRes.body.data.order.id;

    // Valid: PENDING -> CANCELLED
    const cancelRes = await request
      .patch(`/api/orders/${orderId}/status`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({ status: "CANCELLED" });
      
    expect(cancelRes.status).toBe(200);
    expect(cancelRes.body.data.order.status).toBe("CANCELLED");

    // Re-increment inventory check (should happen when CANCELLED)
    const inventory = await prisma.inventory.findFirst({
      where: { product_variant_id: variant.id, branch_id: branch.id }
    });
    // initial 10 - 2 (order) + 2 (cancel) = 10
    expect(inventory!.quantity).toBe(10); 

    // Invalid: CANCELLED -> READY_FOR_PICKUP (Cannot modify cancelled order)
    const invalidRes = await request
      .patch(`/api/orders/${orderId}/status`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({ status: "READY_FOR_PICKUP" });
      
    expect(invalidRes.status).toBe(400);
  });
});

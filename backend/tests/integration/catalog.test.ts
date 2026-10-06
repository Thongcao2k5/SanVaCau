import { beforeEach, describe, expect, it } from "vitest";
import { prisma } from "../../src/lib/prisma.js";
import { request } from "../helpers/app.js";
import { clearDatabase } from "../helpers/db.js";
import { createBrand, createCategory, createProduct } from "../helpers/fixtures.js";

describe("Public catalog filters", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  it("returns only active categories and brands", async () => {
    const [activeCategory, inactiveCategory, activeBrand, inactiveBrand] = await Promise.all([
      createCategory(),
      createCategory(),
      createBrand(),
      createBrand(),
    ]);
    await Promise.all([
      prisma.category.update({
        where: { id: inactiveCategory.id },
        data: { is_active: false },
      }),
      prisma.brand.update({
        where: { id: inactiveBrand.id },
        data: { is_active: false },
      }),
    ]);

    const [categoriesResponse, brandsResponse] = await Promise.all([
      request.get("/api/categories"),
      request.get("/api/brands"),
    ]);

    expect(categoriesResponse.status).toBe(200);
    expect(categoriesResponse.body.data.categories).toEqual([
      expect.objectContaining({ id: activeCategory.id.toString(), name: activeCategory.name }),
    ]);
    expect(brandsResponse.status).toBe(200);
    expect(brandsResponse.body.data.brands).toEqual([
      expect.objectContaining({ id: activeBrand.id.toString(), name: activeBrand.name }),
    ]);
  });

  it("filters products by category and brand together", async () => {
    const [selectedCategory, otherCategory, selectedBrand, otherBrand] = await Promise.all([
      createCategory(),
      createCategory(),
      createBrand(),
      createBrand(),
    ]);
    const expected = await createProduct(selectedCategory.id, selectedBrand.id);
    await Promise.all([
      createProduct(selectedCategory.id, otherBrand.id),
      createProduct(otherCategory.id, selectedBrand.id),
    ]);

    const response = await request.get(
      `/api/products?categoryId=${selectedCategory.id}&brandId=${selectedBrand.id}`,
    );

    expect(response.status).toBe(200);
    expect(response.body.data.products).toHaveLength(1);
    expect(response.body.data.products[0]).toMatchObject({
      id: expected.id.toString(),
      categoryId: selectedCategory.id.toString(),
      brandId: selectedBrand.id.toString(),
    });
  });
});

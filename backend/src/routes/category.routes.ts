import { Router } from "express"; // Tạo router riêng cho category
import { prisma } from "../lib/prisma.js"; // Query database bằng Prisma
import { requireAuth } from "../middleware/auth.middleware.js"; // Kiểm tra đăng nhập
import { requireRole } from "../middleware/role.middleware.js"; // Kiểm tra quyền ADMIN

export const categoryRouter = Router(); // Router riêng cho category

type CategoryRow = { // Kiểu dữ liệu category lấy từ database
    id: bigint;
    name: string;
    parent_id: bigint | null;
    description: string | null;
    sort_order: number;
    is_active: boolean;
};

type CategoryResponse = { // Kiểu dữ liệu category trả ra API
    id: string;
    name: string;
    parentId: string | null;
    description: string | null;
    sortOrder: number;
    isActive: boolean;
    children: CategoryResponse[];
};

const categorySelect = { // Danh sách field cần lấy từ Prisma
    id: true,
    name: true,
    parent_id: true,
    description: true,
    sort_order: true,
    is_active: true,
} as const;

const parseBigIntId = (value: string | string[] | undefined) => { // Chuyển id từ URL/body sang BigInt an toàn
    return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const toCategoryResponse = (category: CategoryRow): CategoryResponse => ({ // Đổi database field sang API field
    id: category.id.toString(),
    name: category.name,
    parentId: category.parent_id?.toString() ?? null,
    description: category.description,
    sortOrder: category.sort_order,
    isActive: category.is_active,
    children: [],
});

const buildCategoryTree = (categories: CategoryRow[]) => { // Chuyển flat list thành tree cha-con
    const categoryMap = new Map<string, CategoryResponse>(); // Map để tra category theo id nhanh
    const roots: CategoryResponse[] = []; // Danh sách category gốc parentId = null

    for (const category of categories) { // Tạo response object cho từng category
        const item = toCategoryResponse(category);
        categoryMap.set(item.id, item);
    }

    for (const category of categories) { // Gắn category con vào cha
        const item = categoryMap.get(category.id.toString());

        if (!item) {
            continue;
        }

        const parentId = category.parent_id?.toString() ?? null;

        if (!parentId) {
            roots.push(item);
            continue;
        }

        const parent = categoryMap.get(parentId);

        if (parent) {
            parent.children.push(item);
        } else {
            roots.push(item);
        }
    }

    return roots;
};

categoryRouter.get("/", async (_req, res, next) => { // GET /api/categories
    try {
        const categories = await prisma.category.findMany({ // Lấy category đang active
            where: {
                is_active: true,
            },
            orderBy: [
                { sort_order: "asc" },
                { id: "asc" },
            ],
            select: categorySelect,
        });

        res.json({
            success: true,
            data: {
                categories: buildCategoryTree(categories),
            },
        });
    } catch (error) {
        next(error);
    }
});

categoryRouter.get("/:id", async (req, res, next) => { // GET /api/categories/:id
    try {
        const id = parseBigIntId(req.params.id);

        if (!id) {
            res.status(400).json({
                success: false,
                message: "invalid category id",
            });
            return;
        }

        const category = await prisma.category.findUnique({ // Tìm category theo id
            where: { id },
            select: categorySelect,
        });

        if (!category || !category.is_active) {
            res.status(404).json({
                success: false,
                message: "category not found",
            });
            return;
        }

        res.json({
            success: true,
            data: {
                category: toCategoryResponse(category),
            },
        });
    } catch (error) {
        next(error);
    }
});

categoryRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => { // ADMIN tạo category
    try {
        const name = typeof req.body?.name === "string" ? req.body.name.trim() : "";
        const description = typeof req.body?.description === "string" ? req.body.description.trim() : null;
        const sortOrder = Number.isInteger(req.body?.sortOrder) ? req.body.sortOrder : 0;
        const parentId = req.body?.parentId === null || req.body?.parentId === undefined
            ? null
            : parseBigIntId(String(req.body.parentId));

        if (!name) {
            res.status(400).json({
                success: false,
                message: "name is required",
            });
            return;
        }

        if (req.body?.parentId !== null && req.body?.parentId !== undefined && !parentId) {
            res.status(400).json({
                success: false,
                message: "parentId is invalid",
            });
            return;
        }

        if (parentId) {
            const parent = await prisma.category.findUnique({ // Kiểm tra parent category có tồn tại không
                where: { id: parentId },
                select: {
                    id: true,
                    is_active: true,
                },
            });

            if (!parent || !parent.is_active) {
                res.status(400).json({
                    success: false,
                    message: "parent category not found",
                });
                return;
            }
        }

        const category = await prisma.category.create({
            data: {
                name,
                parent_id: parentId,
                description,
                sort_order: sortOrder,
                is_active: true,
            },
            select: categorySelect,
        });

        res.status(201).json({
            success: true,
            message: "Category created successfully",
            data: {
                category: toCategoryResponse(category),
            },
        });
    } catch (error) {
        next(error);
    }
});

categoryRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => { // ADMIN cập nhật category
    try {
        const id = parseBigIntId(req.params.id);

        if (!id) {
            res.status(400).json({
                success: false,
                message: "invalid category id",
            });
            return;
        }

        const existingCategory = await prisma.category.findUnique({ // Kiểm tra category hiện tại
            where: { id },
            select: {
                id: true,
            },
        });

        if (!existingCategory) {
            res.status(404).json({
                success: false,
                message: "category not found",
            });
            return;
        }

        const name = typeof req.body?.name === "string" ? req.body.name.trim() : undefined;
        const description =
            req.body?.description === null
                ? null
                : typeof req.body?.description === "string"
                    ? req.body.description.trim()
                    : undefined;
        const sortOrder = Number.isInteger(req.body?.sortOrder) ? req.body.sortOrder : undefined;
        const isActive = typeof req.body?.isActive === "boolean" ? req.body.isActive : undefined;
        const parentId =
            req.body?.parentId === undefined
                ? undefined
                : req.body.parentId === null
                    ? null
                    : parseBigIntId(String(req.body.parentId));

        if (name === "") {
            res.status(400).json({
                success: false,
                message: "name cannot be empty",
            });
            return;
        }

        if (req.body?.parentId !== undefined && req.body.parentId !== null && !parentId) {
            res.status(400).json({
                success: false,
                message: "parentId is invalid",
            });
            return;
        }

        if (parentId && parentId === id) {
            res.status(400).json({
                success: false,
                message: "category cannot be its own parent",
            });
            return;
        }

        if (parentId) {
            const parent = await prisma.category.findUnique({
                where: { id: parentId },
                select: {
                    id: true,
                    is_active: true,
                },
            });

            if (!parent || !parent.is_active) {
                res.status(400).json({
                    success: false,
                    message: "parent category not found",
                });
                return;
            }
        }

        const category = await prisma.category.update({
            where: { id },
            data: {
                ...(name !== undefined ? { name } : {}),
                ...(description !== undefined ? { description } : {}),
                ...(sortOrder !== undefined ? { sort_order: sortOrder } : {}),
                ...(isActive !== undefined ? { is_active: isActive } : {}),
                ...(parentId !== undefined ? { parent_id: parentId } : {}),
            },
            select: categorySelect,
        });

        res.json({
            success: true,
            message: "Category updated successfully",
            data: {
                category: toCategoryResponse(category),
            },
        });
    } catch (error) {
        next(error);
    }
});

categoryRouter.patch("/:id/inactivate", requireAuth, requireRole("ADMIN"), async (req, res, next) => { // ADMIN ẩn category
    try {
        const id = parseBigIntId(req.params.id);

        if (!id) {
            res.status(400).json({
                success: false,
                message: "invalid category id",
            });
            return;
        }

        const category = await prisma.category.update({
            where: { id },
            data: {
                is_active: false,
            },
            select: categorySelect,
        });

        res.json({
            success: true,
            message: "Category inactivated successfully",
            data: {
                category: toCategoryResponse(category),
            },
        });
    } catch (error) {
        next(error);
    }
});
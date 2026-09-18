import { Router } from "express"; // Tạo router riêng cho brand
import { prisma } from "../lib/prisma.js"; // Query database bằng Prisma
import { requireAuth } from "../middleware/auth.middleware.js"; // Kiểm tra đăng nhập
import { requireRole } from "../middleware/role.middleware.js"; // Kiểm tra quyền ADMIN

export const brandRouter = Router(); // Router riêng cho brand

type BrandRow = { // Kiểu dữ liệu brand lấy từ database
    id: bigint;
    name: string;
    description: string | null;
    is_active: boolean;
};

const brandSelect = { // Danh sách field cần lấy từ Prisma
    id: true,
    name: true,
    description: true,
    is_active: true,
} as const;

const parseBigIntId = (value: string | string[] | undefined) => { // Chuyển id từ URL sang BigInt an toàn
    return typeof value === "string" && /^\d+$/.test(value) ? BigInt(value) : null;
};

const toBrandResponse = (brand: BrandRow) => ({ // Đổi database field sang API field
    id: brand.id.toString(),
    name: brand.name,
    description: brand.description,
    isActive: brand.is_active,
});

brandRouter.get("/", async (_req, res, next) => { // GET /api/brands
    try {
        const brands = await prisma.brand.findMany({ // Lấy danh sách brand đang active
            where: {
                is_active: true,
            },
            orderBy: {
                name: "asc",
            },
            select: brandSelect,
        });

        res.json({
            success: true,
            data: {
                brands: brands.map(toBrandResponse),
            },
        });
    } catch (error) {
        next(error);
    }
});

brandRouter.get("/:id", async (req, res, next) => { // GET /api/brands/:id
    try {
        const id = parseBigIntId(req.params.id);

        if (!id) {
            res.status(400).json({
                success: false,
                message: "invalid brand id",
            });
            return;
        }

        const brand = await prisma.brand.findUnique({ // Tìm brand theo id
            where: { id },
            select: brandSelect,
        });

        if (!brand || !brand.is_active) {
            res.status(404).json({
                success: false,
                message: "brand not found",
            });
            return;
        }

        res.json({
            success: true,
            data: {
                brand: toBrandResponse(brand),
            },
        });
    } catch (error) {
        next(error);
    }
});

brandRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => { // ADMIN tạo brand
    try {
        const name = typeof req.body?.name === "string" ? req.body.name.trim() : "";
        const description = typeof req.body?.description === "string" ? req.body.description.trim() : null;

        if (!name) {
            res.status(400).json({
                success: false,
                message: "name is required",
            });
            return;
        }

        const existingBrand = await prisma.brand.findUnique({ // Kiểm tra brand trùng tên
            where: { name },
            select: { id: true },
        });

        if (existingBrand) {
            res.status(409).json({
                success: false,
                message: "brand already exists",
            });
            return;
        }

        const brand = await prisma.brand.create({ // Tạo brand mới
            data: {
                name,
                description,
                is_active: true,
            },
            select: brandSelect,
        });

        res.status(201).json({
            success: true,
            message: "Brand created successfully",
            data: {
                brand: toBrandResponse(brand),
            },
        });
    } catch (error) {
        next(error);
    }
});

brandRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => { // ADMIN cập nhật brand
    try {
        const id = parseBigIntId(req.params.id);

        if (!id) {
            res.status(400).json({
                success: false,
                message: "invalid brand id",
            });
            return;
        }

        const existingBrand = await prisma.brand.findUnique({ // Kiểm tra brand có tồn tại không
            where: { id },
            select: { id: true },
        });

        if (!existingBrand) {
            res.status(404).json({
                success: false,
                message: "brand not found",
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
        const isActive = typeof req.body?.isActive === "boolean" ? req.body.isActive : undefined;

        if (name === "") {
            res.status(400).json({
                success: false,
                message: "name cannot be empty",
            });
            return;
        }

        if (name !== undefined) {
            const duplicatedBrand = await prisma.brand.findUnique({ // Nếu đổi tên, kiểm tra tên mới có bị trùng không
                where: { name },
                select: { id: true },
            });

            if (duplicatedBrand && duplicatedBrand.id !== id) {
                res.status(409).json({
                    success: false,
                    message: "brand already exists",
                });
                return;
            }
        }

        const brand = await prisma.brand.update({ // Cập nhật brand
            where: { id },
            data: {
                ...(name !== undefined ? { name } : {}),
                ...(description !== undefined ? { description } : {}),
                ...(isActive !== undefined ? { is_active: isActive } : {}),
            },
            select: brandSelect,
        });

        res.json({
            success: true,
            message: "Brand updated successfully",
            data: {
                brand: toBrandResponse(brand),
            },
        });
    } catch (error) {
        next(error);
    }
});

brandRouter.patch("/:id/inactivate", requireAuth, requireRole("ADMIN"), async (req, res, next) => { // ADMIN ẩn brand
    try {
        const id = parseBigIntId(req.params.id);

        if (!id) {
            res.status(400).json({
                success: false,
                message: "invalid brand id",
            });
            return;
        }

        const brand = await prisma.brand.update({ // Không xóa cứng, chỉ chuyển is_active = false
            where: { id },
            data: {
                is_active: false,
            },
            select: brandSelect,
        });

        res.json({
            success: true,
            message: "Brand inactivated successfully",
            data: {
                brand: toBrandResponse(brand),
            },
        });
    } catch (error) {
        next(error);
    }
});
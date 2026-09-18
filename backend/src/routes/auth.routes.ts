import { Router } from "express";
import { hashPassword, signAuthToken, verifyPassword } from "../lib/auth.js";
import { prisma } from "../lib/prisma.js";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import type { AuthUser } from "../types/auth.js";

export const authRouter = Router();

const toAuthUser = (user: {
  id: bigint;
  email: string;
  role: string;
  branch_id: bigint | null;
}): AuthUser => ({
  id: user.id.toString(),
  email: user.email,
  role: user.role,
  branchId: user.branch_id?.toString() ?? null,
});

const normalizeEmail = (email: unknown) =>
  typeof email === "string" ? email.trim().toLowerCase() : "";

authRouter.post("/register", async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = typeof req.body?.password === "string" ? req.body.password : "";
    const fullName = typeof req.body?.fullName === "string" ? req.body.fullName.trim() : "";
    const phone = typeof req.body?.phone === "string" ? req.body.phone.trim() : null;

    if (!email || !password || !fullName) {
      res.status(400).json({
        success: false,
        message: "email, password, and fullName are required",
      });
      return;
    }

    if (password.length < 6) {
      res.status(400).json({
        success: false,
        message: "password must be at least 6 characters",
      });
      return;
    }

    const existingUser = await prisma.app_user.findUnique({
      where: { email },
      select: { id: true },
    });

    if (existingUser) {
      res.status(409).json({
        success: false,
        message: "email already exists",
      });
      return;
    }

    const user = await prisma.app_user.create({
      data: {
        email,
        password_hash: await hashPassword(password),
        full_name: fullName,
        phone,
        role: "CUSTOMER",
        status: "ACTIVE",
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
      },
    });

    const authUser = toAuthUser(user);

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: authUser.id,
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: authUser.branchId,
        },
        token: signAuthToken(authUser),
      },
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post("/login", async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = typeof req.body?.password === "string" ? req.body.password : "";

    if (!email || !password) {
      res.status(400).json({
        success: false,
        message: "email and password are required",
      });
      return;
    }

    const user = await prisma.app_user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        password_hash: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
      },
    });

    if (!user || !(await verifyPassword(password, user.password_hash))) {
      res.status(401).json({
        success: false,
        message: "invalid email or password",
      });
      return;
    }

    if (user.status !== "ACTIVE") {
      res.status(403).json({
        success: false,
        message: "account is not active",
      });
      return;
    }

    const authUser = toAuthUser(user);

    res.json({
      success: true,
      data: {
        user: {
          id: authUser.id,
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: authUser.branchId,
        },
        token: signAuthToken(authUser),
      },
    });
  } catch (error) {
    next(error);
  }
});


authRouter.post("/dev/create-admin", async (req, res, next) => {
  try {
    const password = typeof req.body?.password === "string" ? req.body.password : "";
    const fullName =
      typeof req.body?.fullName === "string" && req.body.fullName.trim()
        ? req.body.fullName.trim()
        : "Quản trị viên";

    if (password.length < 6) {
      res.status(400).json({
        success: false,
        message: "password must be at least 6 characters",
      });
      return;
    }

    const user = await prisma.app_user.upsert({
      where: { email: "admin@shopvacau.com" },
      create: {
        email: "admin@shopvacau.com",
        password_hash: await hashPassword(password),
        full_name: fullName,
        role: "ADMIN",
        status: "ACTIVE",
        branch_id: null,
      },
      update: {
        password_hash: await hashPassword(password),
        full_name: fullName,
        role: "ADMIN",
        status: "ACTIVE",
        branch_id: null,
        must_change_password: false,
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
      },
    });

    const authUser = toAuthUser(user);

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: authUser.id,
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: authUser.branchId,
        },
        token: signAuthToken(authUser),
      },
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post("/admin/users", requireAuth, requireRole("ADMIN"), async (req, res, next) => { // Chỉ ADMIN được tạo tài khoản nội bộ
  try {
    const email = normalizeEmail(req.body?.email); // Chuẩn hóa email: trim + lowercase
    const password = typeof req.body?.password === "string" ? req.body.password : ""; // Mật khẩu ban đầu
    const fullName = typeof req.body?.fullName === "string" ? req.body.fullName.trim() : ""; // Họ tên nhân viên/quản lý
    const phone = typeof req.body?.phone === "string" ? req.body.phone.trim() : null; // Số điện thoại, có thể null
    const role = typeof req.body?.role === "string" ? req.body.role.trim().toUpperCase() : ""; // Role được yêu cầu tạo
    const branchId = typeof req.body?.branchId === "string" || typeof req.body?.branchId === "number"
      ? BigInt(req.body.branchId)
      : null; // STAFF/BRANCH_MANAGER bắt buộc có branchId

    if (!email || !password || !fullName || !role || !branchId) { // Kiểm tra dữ liệu bắt buộc
      res.status(400).json({
        success: false,
        message: "email, password, fullName, role, and branchId are required",
      });
      return;
    }

    if (password.length < 6) { // Mật khẩu tối thiểu 6 ký tự
      res.status(400).json({
        success: false,
        message: "password must be at least 6 characters",
      });
      return;
    }

    if (!["STAFF", "BRANCH_MANAGER"].includes(role)) { // API này chỉ cho tạo STAFF hoặc BRANCH_MANAGER
      res.status(400).json({
        success: false,
        message: "role must be STAFF or BRANCH_MANAGER",
      });
      return;
    }

    const existingUser = await prisma.app_user.findUnique({ // Kiểm tra email đã tồn tại chưa
      where: { email },
      select: { id: true },
    });

    if (existingUser) { // Nếu email đã có thì không tạo trùng
      res.status(409).json({
        success: false,
        message: "email already exists",
      });
      return;
    }

    const branch = await prisma.branch.findUnique({ // Kiểm tra branchId có tồn tại không
      where: { id: branchId },
      select: { id: true },
    });

    if (!branch) { // Nếu branch không tồn tại thì không tạo staff/manager
      res.status(400).json({
        success: false,
        message: "branch not found",
      });
      return;
    }

    const user = await prisma.app_user.create({ // Tạo tài khoản nội bộ
      data: {
        email,
        password_hash: await hashPassword(password),
        full_name: fullName,
        phone,
        role,
        status: "ACTIVE",
        branch_id: branchId,
        must_change_password: true,
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
        must_change_password: true,
        created_at: true,
        updated_at: true,
      },
    });

    res.status(201).json({
      success: true,
      message: "User created successfully",
      data: {
        user: {
          id: user.id.toString(),
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: user.branch_id?.toString() ?? null,
          mustChangePassword: user.must_change_password,
          createdAt: user.created_at,
          updatedAt: user.updated_at,
        },
      },
    });
  } catch (error) {
    next(error); // Nếu lỗi bất ngờ thì chuyển sang errorMiddleware
  }
});


authRouter.patch("/admin/users/:id/status", requireAuth, requireRole("ADMIN"), async (req, res, next) => { // Chỉ ADMIN được đổi trạng thái tài khoản
  try {
    const userId = typeof req.params.id === "string" && /^\d+$/.test(req.params.id)
      ? BigInt(req.params.id)
      : null; // Lấy id user từ URL và kiểm tra phải là số

    const status = typeof req.body?.status === "string" ? req.body.status.trim().toUpperCase() : ""; // Trạng thái mới

    if (!userId) { // Nếu id không hợp lệ
      res.status(400).json({
        success: false,
        message: "invalid user id",
      });
      return;
    }

    if (!["ACTIVE", "LOCKED", "INACTIVE"].includes(status)) { // Chỉ cho 3 trạng thái hợp lệ
      res.status(400).json({
        success: false,
        message: "status must be ACTIVE, LOCKED, or INACTIVE",
      });
      return;
    }

    if (userId === BigInt(req.user!.id)) { // Không cho admin tự khóa/chỉnh status chính mình
      res.status(400).json({
        success: false,
        message: "cannot update your own status",
      });
      return;
    }

    const existingUser = await prisma.app_user.findUnique({ // Kiểm tra user có tồn tại không
      where: { id: userId },
      select: { id: true },
    });

    if (!existingUser) { // Nếu user không tồn tại
      res.status(404).json({
        success: false,
        message: "user not found",
      });
      return;
    }

    const user = await prisma.app_user.update({ // Cập nhật status user
      where: { id: userId },
      data: {
        status,
        updated_at: new Date(),
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
        must_change_password: true,
        created_at: true,
        updated_at: true,
      },
    });

    res.json({
      success: true,
      message: "User status updated successfully",
      data: {
        user: {
          id: user.id.toString(),
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: user.branch_id?.toString() ?? null,
          mustChangePassword: user.must_change_password,
          createdAt: user.created_at,
          updatedAt: user.updated_at,
        },
      },
    });
  } catch (error) {
    next(error); // Nếu lỗi bất ngờ thì chuyển sang errorMiddleware
  }
});

authRouter.patch("/admin/users/:id/password", requireAuth, requireRole("ADMIN"), async (req, res, next) => { // Chỉ ADMIN được reset mật khẩu user khác
  try {
    const userId = typeof req.params.id === "string" && /^\d+$/.test(req.params.id)
      ? BigInt(req.params.id)
      : null; // Lấy id user từ URL và kiểm tra phải là số

    const newPassword = typeof req.body?.newPassword === "string" ? req.body.newPassword : ""; // Mật khẩu mới do ADMIN đặt

    if (!userId) { // Nếu id không hợp lệ
      res.status(400).json({
        success: false,
        message: "invalid user id",
      });
      return;
    }

    if (userId === BigInt(req.user!.id)) { // Không cho admin reset password chính mình ở API quản trị này
      res.status(400).json({
        success: false,
        message: "cannot reset your own password here",
      });
      return;
    }

    if (newPassword.length < 6) { // Mật khẩu mới tối thiểu 6 ký tự
      res.status(400).json({
        success: false,
        message: "newPassword must be at least 6 characters",
      });
      return;
    }

    const existingUser = await prisma.app_user.findUnique({ // Kiểm tra user có tồn tại không
      where: { id: userId },
      select: { id: true },
    });

    if (!existingUser) { // Nếu user không tồn tại
      res.status(404).json({
        success: false,
        message: "user not found",
      });
      return;
    }

    const user = await prisma.app_user.update({ // Cập nhật password_hash mới và bắt user đổi mật khẩu sau này
      where: { id: userId },
      data: {
        password_hash: await hashPassword(newPassword),
        must_change_password: true,
        updated_at: new Date(),
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
        must_change_password: true,
        created_at: true,
        updated_at: true,
      },
    });

    res.json({
      success: true,
      message: "User password reset successfully",
      data: {
        user: {
          id: user.id.toString(),
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: user.branch_id?.toString() ?? null,
          mustChangePassword: user.must_change_password,
          createdAt: user.created_at,
          updatedAt: user.updated_at,
        },
      },
    });
  } catch (error) {
    next(error); // Nếu lỗi bất ngờ thì chuyển sang errorMiddleware
  }
});


authRouter.get("/admin/users", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const page = Math.max(Number(req.query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 100);
    const skip = (page - 1) * limit;

    const [users, total] = await Promise.all([
      prisma.app_user.findMany({
        skip,
        take: limit,
        orderBy: {
          created_at: "desc",
        },
        select: {
          id: true,
          email: true,
          full_name: true,
          phone: true,
          role: true,
          status: true,
          branch_id: true,
          must_change_password: true,
          created_at: true,
          updated_at: true,
        },
      }),
      prisma.app_user.count(),
    ]);

    res.json({
      success: true,
      data: {
        users: users.map((user) => ({
          id: user.id.toString(),
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: user.branch_id?.toString() ?? null,
          mustChangePassword: user.must_change_password,
          createdAt: user.created_at,
          updatedAt: user.updated_at,
        })),
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

authRouter.get("/me", requireAuth, (req, res) => {
  res.json({
    success: true,
    data: {
      user: req.user,
    },
  });
});


authRouter.get("/profile", requireAuth, async (req, res, next) => { // User đã đăng nhập mới được xem profile
  try {
    const user = await prisma.app_user.findUnique({ // Tìm user mới nhất trong database theo id từ token
      where: {
        id: BigInt(req.user!.id),
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
        must_change_password: true,
        created_at: true,
        updated_at: true,
      },
    });

    if (!user) { // Nếu token có id nhưng user không còn tồn tại trong database
      res.status(404).json({
        success: false,
        message: "user not found",
      });
      return;
    }

    res.json({
      success: true,
      data: {
        user: {
          id: user.id.toString(),
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: user.branch_id?.toString() ?? null,
          mustChangePassword: user.must_change_password,
          createdAt: user.created_at,
          updatedAt: user.updated_at,
        },
      },
    });
  } catch (error) {
    next(error); // Nếu có lỗi bất ngờ thì chuyển sang errorMiddleware
  }
});


authRouter.patch("/profile", requireAuth, async (req, res, next) => { // User đã đăng nhập mới được cập nhật profile
  try {
    const fullName = typeof req.body?.fullName === "string" ? req.body.fullName.trim() : ""; // Họ tên mới
    const phone =
      req.body?.phone === null
        ? null
        : typeof req.body?.phone === "string"
          ? req.body.phone.trim()
          : undefined; // Số điện thoại mới, null nghĩa là xóa số điện thoại

    if (!fullName) { // fullName bắt buộc để tránh profile bị rỗng tên
      res.status(400).json({
        success: false,
        message: "fullName is required",
      });
      return;
    }

    const user = await prisma.app_user.update({ // Cập nhật user hiện tại trong database
      where: {
        id: BigInt(req.user!.id),
      },
      data: {
        full_name: fullName,
        phone,
        updated_at: new Date(),
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        phone: true,
        role: true,
        status: true,
        branch_id: true,
        must_change_password: true,
        created_at: true,
        updated_at: true,
      },
    });

    res.json({
      success: true,
      message: "Profile updated successfully",
      data: {
        user: {
          id: user.id.toString(),
          email: user.email,
          fullName: user.full_name,
          phone: user.phone,
          role: user.role,
          status: user.status,
          branchId: user.branch_id?.toString() ?? null,
          mustChangePassword: user.must_change_password,
          createdAt: user.created_at,
          updatedAt: user.updated_at,
        },
      },
    });
  } catch (error) {
    next(error); // Nếu có lỗi bất ngờ thì chuyển sang errorMiddleware
  }
});


authRouter.post("/change-password", requireAuth, async (req, res, next) => { // User đã đăng nhập mới được đổi mật khẩu
  try {
    const currentPassword = typeof req.body?.currentPassword === "string" ? req.body.currentPassword : ""; // Mật khẩu hiện tại user nhập
    const newPassword = typeof req.body?.newPassword === "string" ? req.body.newPassword : ""; // Mật khẩu mới user muốn đổi

    if (!currentPassword || !newPassword) { // Nếu thiếu một trong hai mật khẩu
      res.status(400).json({
        success: false,
        message: "currentPassword and newPassword are required",
      });
      return;
    }

    if (newPassword.length < 6) { // Mật khẩu mới tối thiểu 6 ký tự
      res.status(400).json({
        success: false,
        message: "newPassword must be at least 6 characters",
      });
      return;
    }

    const user = await prisma.app_user.findUnique({ // Tìm user hiện tại trong database
      where: {
        id: BigInt(req.user!.id),
      },
      select: {
        id: true,
        password_hash: true,
      },
    });

    if (!user) { // Nếu token có user id nhưng database không còn user
      res.status(404).json({
        success: false,
        message: "user not found",
      });
      return;
    }

    if (!(await verifyPassword(currentPassword, user.password_hash))) { // So mật khẩu hiện tại với password_hash trong database
      res.status(401).json({
        success: false,
        message: "current password is incorrect",
      });
      return;
    }

    await prisma.app_user.update({ // Cập nhật password_hash mới
      where: {
        id: user.id,
      },
      data: {
        password_hash: await hashPassword(newPassword),
        must_change_password: false,
        updated_at: new Date(),
      },
    });

    res.json({
      success: true,
      message: "Password changed successfully",
    });
  } catch (error) {
    next(error); // Nếu có lỗi bất ngờ thì chuyển sang errorMiddleware
  }
});


authRouter.get("/admin-check", requireAuth, requireRole("ADMIN"), (req, res) => {
  res.json({
    success: true,
    message: "Admin access granted",
    data: {
      user: req.user,
    },
  });


});


import { Router } from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import { requireAuth } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/role.middleware.js";
import { createAuditLog } from "../lib/audit-log.js";

export const uploadRouter = Router();

const uploadDir = path.join(process.cwd(), "uploads", "images");
const allowedImageExtensions: Record<string, string> = {
  "image/jpeg": ".jpg",
  "image/png": ".png",
  "image/webp": ".webp",
};

// Ensure the directory exists
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, uploadDir);
  },
  filename: (_req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const ext = allowedImageExtensions[file.mimetype] ?? ".jpg";
    cb(null, uniqueSuffix + ext);
  },
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (_req, file, cb) => {
    const allowedMimeTypes = ["image/jpeg", "image/png", "image/webp"];
    if (allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error("LIMIT_UNEXPECTED_FILE_TYPE"));
    }
  },
});

uploadRouter.post(
  "/image",
  requireAuth,
  requireRole("ADMIN"),
  (req, res, next) => {
    upload.single("image")(req, res, (err: unknown) => {
      if (err) {
        if (err instanceof multer.MulterError) {
          if (err.code === "LIMIT_FILE_SIZE") {
            return res.status(400).json({
              success: false,
              message: "File is too large. Max size is 5MB.",
            });
          }
          return res.status(400).json({
            success: false,
            message: `Upload error: ${err.message}`,
          });
        } else if (err instanceof Error && err.message === "LIMIT_UNEXPECTED_FILE_TYPE") {
          return res.status(400).json({
            success: false,
            message: "Invalid file type. Only JPEG, PNG, and WebP are allowed.",
          });
        }
        return next(err);
      }
      
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "No image file provided",
        });
      }

      const imageUrl = `/uploads/images/${req.file.filename}`;

      res.status(200).json({
        success: true,
        message: "Image uploaded successfully",
        data: {
          imageUrl,
        },
      });

      createAuditLog({
        actorId: req.user!.id,
        actorRole: req.user!.role,
        action: "IMAGE_UPLOADED",
        entityType: "upload",
        afterData: { imageUrl, originalName: req.file.originalname, size: req.file.size },
        ipAddress: req.ip ?? null,
        userAgent: req.headers["user-agent"] ?? null,
      });
    });
  }
);

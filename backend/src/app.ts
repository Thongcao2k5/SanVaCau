import cors from "cors";
import express from "express";
import helmet from "helmet";
import path from "path";
import { errorMiddleware } from "./middleware/error.middleware.js";
import { generalRateLimit } from "./middleware/rate-limit.middleware.js";
import { router } from "./routes/index.js";

export const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true, limit: "1mb" }));

app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));

app.use("/api", generalRateLimit, router);

app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route not found" });
});

app.use(errorMiddleware);

import cors from "cors";
import express from "express";
import { errorMiddleware } from "./middleware/error.middleware.js";
import { router } from "./routes/index.js";

export const app = express();

app.use(cors());
app.use(express.json());

app.use("/api", router);

app.use(errorMiddleware);

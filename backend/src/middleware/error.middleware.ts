import type { ErrorRequestHandler } from "express";
import pkg from "@prisma/client";
const { Prisma } = pkg;

export const errorMiddleware: ErrorRequestHandler = (err, req, res, next) => {
  let statusCode = 500;
  let message = "Internal server error";
  let details: string | undefined = undefined;

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === "P2002") {
      statusCode = 409;
      message = "Duplicate value";
    } else if (err.code === "P2025") {
      statusCode = 404;
      message = "Record not found";
    }
  } else if (err instanceof SyntaxError && "status" in err && err.status === 400 && "body" in err) {
    statusCode = 400;
    message = "Invalid JSON body";
  } else if (err instanceof Error) {
    if (process.env.NODE_ENV !== "production") {
      details = err.message;
    }
  }

  res.status(statusCode).json({
    success: false,
    message,
    ...(details && { details }),
  });
};

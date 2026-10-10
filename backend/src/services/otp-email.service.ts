import nodemailer from "nodemailer";

type SendOtpEmailInput = {
  email: string;
  code: string;
  purpose: "REGISTER" | "RESET_PASSWORD" | "CHANGE_EMAIL";
};

export const sendOtpEmail = async ({ email, code, purpose }: SendOtpEmailInput) => {
  if (process.env.NODE_ENV === "test") {
    return;
  }

  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT);
  const user = process.env.SMTP_USER;
  const password = process.env.SMTP_PASSWORD;
  const from = process.env.SMTP_FROM || user;

  if (!host || !Number.isFinite(port) || !user || !password || !from) {
    throw new Error("OTP email provider is not configured");
  }

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass: password },
  });

  const purposeText = purpose === "REGISTER"
    ? "Xac nhan dang ky tai khoan"
    : purpose === "CHANGE_EMAIL"
      ? "Xac nhan thay doi email"
      : "Xac nhan dat lai mat khau";
  await transporter.sendMail({
    from: `SanVaCau <${from}>`,
    to: email,
    subject: purpose === "REGISTER"
      ? "Ma OTP dang ky tai khoan SanVaCau"
      : purpose === "CHANGE_EMAIL"
        ? "Ma OTP thay doi email SanVaCau"
        : "Ma OTP dat lai mat khau SanVaCau",
    text: `Ma OTP cua ban la ${code}. Ma co hieu luc trong 5 phut. Khong chia se ma nay voi bat ky ai.`,
    html: `
      <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px">
        <h2 style="color:#d92128">SanVaCau</h2>
        <p>${purposeText}</p>
        <p style="font-size:32px;font-weight:700;letter-spacing:8px">${code}</p>
        <p>Ma co hieu luc trong 5 phut. Khong chia se ma nay voi bat ky ai.</p>
      </div>
    `,
  });
};

-- Additive migration for existing databases; keeps all previous payments.
ALTER TABLE "payment" ADD COLUMN IF NOT EXISTS "checkout_url" TEXT;
ALTER TABLE "payment" ADD COLUMN IF NOT EXISTS "gateway_trans_id" VARCHAR(100);

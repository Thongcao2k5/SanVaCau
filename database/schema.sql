-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE "app_user" (
    "id" BIGSERIAL NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "full_name" VARCHAR(150) NOT NULL,
    "phone" VARCHAR(20),
    "avatar_url" VARCHAR(1000),
    "role" VARCHAR(30) NOT NULL DEFAULT 'CUSTOMER',
    "status" VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    "branch_id" BIGINT,
    "must_change_password" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "app_user_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "auth_otp" (
    "id" BIGSERIAL NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "purpose" VARCHAR(30) NOT NULL,
    "code_hash" VARCHAR(255) NOT NULL,
    "payload" JSONB,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "expires_at" TIMESTAMP(6) NOT NULL,
    "last_sent_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "consumed_at" TIMESTAMP(6),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "auth_otp_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_log" (
    "id" BIGSERIAL NOT NULL,
    "actor_id" BIGINT,
    "actor_role" VARCHAR(30),
    "action" VARCHAR(100) NOT NULL,
    "entity_type" VARCHAR(100) NOT NULL,
    "entity_id" BIGINT,
    "before_data" JSONB,
    "after_data" JSONB,
    "ip_address" VARCHAR(80),
    "user_agent" VARCHAR(500),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "banner" (
    "id" BIGSERIAL NOT NULL,
    "title" VARCHAR(200),
    "image_url" VARCHAR(1000) NOT NULL,
    "link_url" VARCHAR(1000),
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "start_at" TIMESTAMP(6),
    "end_at" TIMESTAMP(6),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "banner_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "booking" (
    "id" BIGSERIAL NOT NULL,
    "customer_id" BIGINT NOT NULL,
    "court_id" BIGINT NOT NULL,
    "booking_date" DATE NOT NULL,
    "status" VARCHAR(20) NOT NULL DEFAULT 'BOOKED',
    "total_amount" DECIMAL(18,2) NOT NULL,
    "payment_method" VARCHAR(20),
    "payment_status" VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "checked_in_at" TIMESTAMP(6),
    "completed_at" TIMESTAMP(6),
    "cancelled_at" TIMESTAMP(6),

    CONSTRAINT "booking_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "booking_slot" (
    "id" BIGSERIAL NOT NULL,
    "booking_id" BIGINT NOT NULL,
    "court_id" BIGINT NOT NULL,
    "booking_date" DATE NOT NULL,
    "time_slot_id" BIGINT NOT NULL,
    "price_at_booking" DECIMAL(18,2) NOT NULL,

    CONSTRAINT "booking_slot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "branch" (
    "id" BIGSERIAL NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "address" VARCHAR(300) NOT NULL,
    "phone" VARCHAR(20),
    "description" VARCHAR(1000),
    "image_url" VARCHAR(1000),
    "is_featured" BOOLEAN NOT NULL DEFAULT false,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "opening_time" TIME(6) NOT NULL,
    "closing_time" TIME(6) NOT NULL,
    "status" VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "branch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "branch_service" (
    "id" BIGSERIAL NOT NULL,
    "branch_id" BIGINT NOT NULL,
    "service_id" BIGINT NOT NULL,
    "reference_price" DECIMAL(18,2),
    "description" VARCHAR(1000),
    "estimated_duration" VARCHAR(100),
    "is_available" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "branch_service_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "brand" (
    "id" BIGSERIAL NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "description" VARCHAR(500),
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "brand_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cart" (
    "id" BIGSERIAL NOT NULL,
    "customer_id" BIGINT NOT NULL,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "cart_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cart_item" (
    "id" BIGSERIAL NOT NULL,
    "cart_id" BIGINT NOT NULL,
    "product_variant_id" BIGINT NOT NULL,
    "quantity" INTEGER NOT NULL,

    CONSTRAINT "cart_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "category" (
    "id" BIGSERIAL NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "parent_id" BIGINT,
    "description" VARCHAR(500),
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "court" (
    "id" BIGSERIAL NOT NULL,
    "branch_id" BIGINT NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "description" VARCHAR(500),
    "status" VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT "court_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "court_price" (
    "id" BIGSERIAL NOT NULL,
    "court_id" BIGINT NOT NULL,
    "time_slot_id" BIGINT NOT NULL,
    "price" DECIMAL(18,2) NOT NULL,

    CONSTRAINT "court_price_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "customer_order" (
    "id" BIGSERIAL NOT NULL,
    "customer_id" BIGINT NOT NULL,
    "branch_id" BIGINT NOT NULL,
    "status" VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    "total_amount" DECIMAL(18,2) NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ready_at" TIMESTAMP(6),
    "completed_at" TIMESTAMP(6),
    "cancelled_at" TIMESTAMP(6),

    CONSTRAINT "customer_order_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inventory" (
    "id" BIGSERIAL NOT NULL,
    "product_variant_id" BIGINT NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 0,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inventory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "news" (
    "id" BIGSERIAL NOT NULL,
    "title" VARCHAR(250) NOT NULL,
    "summary" VARCHAR(500),
    "content" TEXT NOT NULL,
    "thumbnail_url" VARCHAR(1000),
    "author_user_id" BIGINT NOT NULL,
    "branch_id" BIGINT,
    "status" VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    "published_at" TIMESTAMP(6),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "news_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification" (
    "id" BIGSERIAL NOT NULL,
    "user_id" BIGINT NOT NULL,
    "type" VARCHAR(80) NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "message" VARCHAR(1000) NOT NULL,
    "data" JSONB,
    "read_at" TIMESTAMP(6),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_item" (
    "id" BIGSERIAL NOT NULL,
    "order_id" BIGINT NOT NULL,
    "product_variant_id" BIGINT NOT NULL,
    "product_name" VARCHAR(200) NOT NULL,
    "variant_name" VARCHAR(150) NOT NULL,
    "unit_price" DECIMAL(18,2) NOT NULL,
    "quantity" INTEGER NOT NULL,

    CONSTRAINT "order_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "product" (
    "id" BIGSERIAL NOT NULL,
    "category_id" BIGINT NOT NULL,
    "brand_id" BIGINT,
    "name" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "image_url" VARCHAR(1000),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "is_featured" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "product_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "product_variant" (
    "id" BIGSERIAL NOT NULL,
    "product_id" BIGINT NOT NULL,
    "sku" VARCHAR(80) NOT NULL,
    "variant_name" VARCHAR(150) NOT NULL,
    "option_1_name" VARCHAR(50),
    "option_1_value" VARCHAR(100),
    "option_2_name" VARCHAR(50),
    "option_2_value" VARCHAR(100),
    "price" DECIMAL(18,2) NOT NULL,
    "image_url" VARCHAR(1000),
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "product_variant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "racket_service" (
    "id" BIGSERIAL NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "description" VARCHAR(1000),
    "image_url" VARCHAR(1000),
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "racket_service_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "time_slot" (
    "id" BIGSERIAL NOT NULL,
    "start_time" TIME(6) NOT NULL,
    "end_time" TIME(6) NOT NULL,
    "sort_order" INTEGER NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "time_slot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payment" (
    "id" BIGSERIAL NOT NULL,
    "user_id" BIGINT NOT NULL,
    "target_type" VARCHAR(30) NOT NULL,
    "target_id" BIGINT NOT NULL,
    "provider" VARCHAR(50) NOT NULL,
    "amount" DECIMAL(18,2) NOT NULL,
    "status" VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    "transaction_ref" VARCHAR(100),
    "paid_at" TIMESTAMP(6),
    "failed_at" TIMESTAMP(6),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "review" (
    "id" BIGSERIAL NOT NULL,
    "user_id" BIGINT NOT NULL,
    "target_type" VARCHAR(30) NOT NULL,
    "target_id" BIGINT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" VARCHAR(1000),
    "status" VARCHAR(30) NOT NULL DEFAULT 'PUBLISHED',
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "review_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "favorite" (
    "id" BIGSERIAL NOT NULL,
    "user_id" BIGINT NOT NULL,
    "target_type" VARCHAR(30) NOT NULL,
    "target_id" BIGINT NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "favorite_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "customer_address" (
    "id" BIGSERIAL NOT NULL,
    "customer_id" BIGINT NOT NULL,
    "recipient_name" VARCHAR(150) NOT NULL,
    "phone" VARCHAR(20) NOT NULL,
    "address_line" VARCHAR(300) NOT NULL,
    "ward" VARCHAR(120),
    "district" VARCHAR(120),
    "city" VARCHAR(120),
    "note" VARCHAR(500),
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "customer_address_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "voucher" (
    "id" BIGSERIAL NOT NULL,
    "code" VARCHAR(50) NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" VARCHAR(1000),
    "discount_type" VARCHAR(30) NOT NULL,
    "discount_value" DECIMAL(18,2) NOT NULL,
    "max_discount_amount" DECIMAL(18,2),
    "min_order_amount" DECIMAL(18,2),
    "target_type" VARCHAR(30) NOT NULL DEFAULT 'ALL',
    "usage_limit" INTEGER,
    "used_count" INTEGER NOT NULL DEFAULT 0,
    "per_user_limit" INTEGER DEFAULT 1,
    "start_at" TIMESTAMP(6),
    "end_at" TIMESTAMP(6),
    "status" VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "voucher_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "voucher_usage" (
    "id" BIGSERIAL NOT NULL,
    "voucher_id" BIGINT NOT NULL,
    "user_id" BIGINT NOT NULL,
    "target_type" VARCHAR(30) NOT NULL,
    "target_id" BIGINT NOT NULL,
    "discount_amount" DECIMAL(18,2) NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "voucher_usage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_fulfillment" (
    "id" BIGSERIAL NOT NULL,
    "order_id" BIGINT NOT NULL,
    "fulfillment_type" VARCHAR(30) NOT NULL,
    "status" VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    "recipient_name" VARCHAR(150),
    "phone" VARCHAR(20),
    "address_line" VARCHAR(300),
    "ward" VARCHAR(120),
    "district" VARCHAR(120),
    "city" VARCHAR(120),
    "note" VARCHAR(500),
    "shipping_fee" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "tracking_code" VARCHAR(100),
    "shipped_at" TIMESTAMP(6),
    "delivered_at" TIMESTAMP(6),
    "picked_up_at" TIMESTAMP(6),
    "cancelled_at" TIMESTAMP(6),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_fulfillment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "support_ticket" (
    "id" BIGSERIAL NOT NULL,
    "customer_id" BIGINT NOT NULL,
    "subject" VARCHAR(200) NOT NULL,
    "message" VARCHAR(2000) NOT NULL,
    "category" VARCHAR(50) NOT NULL,
    "status" VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    "priority" VARCHAR(30) NOT NULL DEFAULT 'NORMAL',
    "target_type" VARCHAR(30),
    "target_id" BIGINT,
    "assigned_to" BIGINT,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolved_at" TIMESTAMP(6),
    "closed_at" TIMESTAMP(6),

    CONSTRAINT "support_ticket_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "support_ticket_message" (
    "id" BIGSERIAL NOT NULL,
    "ticket_id" BIGINT NOT NULL,
    "sender_id" BIGINT NOT NULL,
    "message" VARCHAR(2000) NOT NULL,
    "is_staff" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "support_ticket_message_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "system_setting" (
    "key" VARCHAR(100) NOT NULL,
    "value" JSONB NOT NULL,
    "description" VARCHAR(500),
    "is_public" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "system_setting_pkey" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "contact_message" (
    "id" BIGSERIAL NOT NULL,
    "user_id" BIGINT,
    "full_name" VARCHAR(150) NOT NULL,
    "email" VARCHAR(150),
    "phone" VARCHAR(20),
    "type" VARCHAR(30) NOT NULL,
    "subject" VARCHAR(200) NOT NULL,
    "message" VARCHAR(2000) NOT NULL,
    "status" VARCHAR(30) NOT NULL DEFAULT 'NEW',
    "admin_note" VARCHAR(1000),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolved_at" TIMESTAMP(6),
    "archived_at" TIMESTAMP(6),

    CONSTRAINT "contact_message_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "faq_item" (
    "id" BIGSERIAL NOT NULL,
    "category" VARCHAR(80) NOT NULL,
    "question" VARCHAR(250) NOT NULL,
    "answer" TEXT NOT NULL,
    "status" VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "view_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "published_at" TIMESTAMP(6),
    "archived_at" TIMESTAMP(6),

    CONSTRAINT "faq_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "static_page" (
    "id" BIGSERIAL NOT NULL,
    "slug" VARCHAR(120) NOT NULL,
    "title" VARCHAR(250) NOT NULL,
    "summary" VARCHAR(500),
    "content" TEXT NOT NULL,
    "type" VARCHAR(50) NOT NULL,
    "status" VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "published_at" TIMESTAMP(6),
    "archived_at" TIMESTAMP(6),

    CONSTRAINT "static_page_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "app_user_email_key" ON "app_user"("email");

-- CreateIndex
CREATE INDEX "ix_app_user_branch" ON "app_user"("branch_id", "role");

-- CreateIndex
CREATE INDEX "auth_otp_email_purpose_created_at_idx" ON "auth_otp"("email", "purpose", "created_at");

-- CreateIndex
CREATE INDEX "audit_log_actor_id_idx" ON "audit_log"("actor_id");

-- CreateIndex
CREATE INDEX "audit_log_entity_type_entity_id_idx" ON "audit_log"("entity_type", "entity_id");

-- CreateIndex
CREATE INDEX "audit_log_created_at_idx" ON "audit_log"("created_at");

-- CreateIndex
CREATE INDEX "ix_booking_court_date" ON "booking"("court_id", "booking_date");

-- CreateIndex
CREATE INDEX "ix_booking_customer_date" ON "booking"("customer_id", "booking_date");

-- CreateIndex
CREATE INDEX "ix_booking_slot_schedule" ON "booking_slot"("court_id", "booking_date", "time_slot_id");

-- CreateIndex
CREATE UNIQUE INDEX "booking_slot_booking_id_time_slot_id_key" ON "booking_slot"("booking_id", "time_slot_id");

-- CreateIndex
CREATE UNIQUE INDEX "booking_slot_court_id_booking_date_time_slot_id_key" ON "booking_slot"("court_id", "booking_date", "time_slot_id");

-- CreateIndex
CREATE UNIQUE INDEX "branch_service_branch_id_service_id_key" ON "branch_service"("branch_id", "service_id");

-- CreateIndex
CREATE UNIQUE INDEX "brand_name_key" ON "brand"("name");

-- CreateIndex
CREATE UNIQUE INDEX "cart_customer_id_key" ON "cart"("customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "cart_item_cart_id_product_variant_id_key" ON "cart_item"("cart_id", "product_variant_id");

-- CreateIndex
CREATE UNIQUE INDEX "court_branch_id_name_key" ON "court"("branch_id", "name");

-- CreateIndex
CREATE UNIQUE INDEX "court_price_court_id_time_slot_id_key" ON "court_price"("court_id", "time_slot_id");

-- CreateIndex
CREATE INDEX "ix_order_branch_status" ON "customer_order"("branch_id", "status");

-- CreateIndex
CREATE INDEX "ix_order_customer" ON "customer_order"("customer_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "inventory_product_variant_id_key" ON "inventory"("product_variant_id");

-- CreateIndex
CREATE INDEX "ix_news_status_published" ON "news"("status", "published_at");

-- CreateIndex
CREATE INDEX "notification_user_id_read_at_created_at_idx" ON "notification"("user_id", "read_at", "created_at");

-- CreateIndex
CREATE INDEX "notification_type_idx" ON "notification"("type");

-- CreateIndex
CREATE INDEX "ix_product_brand" ON "product"("brand_id");

-- CreateIndex
CREATE INDEX "ix_product_category" ON "product"("category_id");

-- CreateIndex
CREATE UNIQUE INDEX "product_variant_sku_key" ON "product_variant"("sku");

-- CreateIndex
CREATE UNIQUE INDEX "time_slot_sort_order_key" ON "time_slot"("sort_order");

-- CreateIndex
CREATE UNIQUE INDEX "time_slot_start_time_end_time_key" ON "time_slot"("start_time", "end_time");

-- CreateIndex
CREATE UNIQUE INDEX "payment_transaction_ref_key" ON "payment"("transaction_ref");

-- CreateIndex
CREATE INDEX "payment_user_id_created_at_idx" ON "payment"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "payment_target_type_target_id_idx" ON "payment"("target_type", "target_id");

-- CreateIndex
CREATE INDEX "payment_status_idx" ON "payment"("status");

-- CreateIndex
CREATE INDEX "review_target_type_target_id_status_idx" ON "review"("target_type", "target_id", "status");

-- CreateIndex
CREATE INDEX "review_user_id_created_at_idx" ON "review"("user_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "review_user_id_target_type_target_id_key" ON "review"("user_id", "target_type", "target_id");

-- CreateIndex
CREATE INDEX "favorite_user_id_created_at_idx" ON "favorite"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "favorite_target_type_target_id_idx" ON "favorite"("target_type", "target_id");

-- CreateIndex
CREATE UNIQUE INDEX "favorite_user_id_target_type_target_id_key" ON "favorite"("user_id", "target_type", "target_id");

-- CreateIndex
CREATE INDEX "customer_address_customer_id_is_default_idx" ON "customer_address"("customer_id", "is_default");

-- CreateIndex
CREATE INDEX "customer_address_customer_id_created_at_idx" ON "customer_address"("customer_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "voucher_code_key" ON "voucher"("code");

-- CreateIndex
CREATE INDEX "voucher_code_idx" ON "voucher"("code");

-- CreateIndex
CREATE INDEX "voucher_status_start_at_end_at_idx" ON "voucher"("status", "start_at", "end_at");

-- CreateIndex
CREATE INDEX "voucher_target_type_idx" ON "voucher"("target_type");

-- CreateIndex
CREATE INDEX "voucher_usage_user_id_voucher_id_idx" ON "voucher_usage"("user_id", "voucher_id");

-- CreateIndex
CREATE INDEX "voucher_usage_target_type_target_id_idx" ON "voucher_usage"("target_type", "target_id");

-- CreateIndex
CREATE UNIQUE INDEX "voucher_usage_voucher_id_target_type_target_id_key" ON "voucher_usage"("voucher_id", "target_type", "target_id");

-- CreateIndex
CREATE UNIQUE INDEX "order_fulfillment_order_id_key" ON "order_fulfillment"("order_id");

-- CreateIndex
CREATE INDEX "order_fulfillment_fulfillment_type_status_idx" ON "order_fulfillment"("fulfillment_type", "status");

-- CreateIndex
CREATE INDEX "order_fulfillment_tracking_code_idx" ON "order_fulfillment"("tracking_code");

-- CreateIndex
CREATE INDEX "support_ticket_customer_id_created_at_idx" ON "support_ticket"("customer_id", "created_at");

-- CreateIndex
CREATE INDEX "support_ticket_status_priority_idx" ON "support_ticket"("status", "priority");

-- CreateIndex
CREATE INDEX "support_ticket_target_type_target_id_idx" ON "support_ticket"("target_type", "target_id");

-- CreateIndex
CREATE INDEX "support_ticket_message_ticket_id_created_at_idx" ON "support_ticket_message"("ticket_id", "created_at");

-- CreateIndex
CREATE INDEX "system_setting_is_public_idx" ON "system_setting"("is_public");

-- CreateIndex
CREATE INDEX "contact_message_status_created_at_idx" ON "contact_message"("status", "created_at");

-- CreateIndex
CREATE INDEX "contact_message_type_created_at_idx" ON "contact_message"("type", "created_at");

-- CreateIndex
CREATE INDEX "contact_message_user_id_created_at_idx" ON "contact_message"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "faq_item_status_category_sort_order_idx" ON "faq_item"("status", "category", "sort_order");

-- CreateIndex
CREATE INDEX "faq_item_category_idx" ON "faq_item"("category");

-- CreateIndex
CREATE INDEX "faq_item_published_at_idx" ON "faq_item"("published_at");

-- CreateIndex
CREATE UNIQUE INDEX "static_page_slug_key" ON "static_page"("slug");

-- CreateIndex
CREATE INDEX "static_page_status_type_sort_order_idx" ON "static_page"("status", "type", "sort_order");

-- CreateIndex
CREATE INDEX "static_page_slug_idx" ON "static_page"("slug");

-- CreateIndex
CREATE INDEX "static_page_published_at_idx" ON "static_page"("published_at");

-- AddForeignKey
ALTER TABLE "app_user" ADD CONSTRAINT "app_user_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branch"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "audit_log" ADD CONSTRAINT "audit_log_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "app_user"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "booking" ADD CONSTRAINT "booking_court_id_fkey" FOREIGN KEY ("court_id") REFERENCES "court"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "booking" ADD CONSTRAINT "booking_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "app_user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "booking_slot" ADD CONSTRAINT "booking_slot_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "booking"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "booking_slot" ADD CONSTRAINT "booking_slot_court_id_fkey" FOREIGN KEY ("court_id") REFERENCES "court"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "booking_slot" ADD CONSTRAINT "booking_slot_time_slot_id_fkey" FOREIGN KEY ("time_slot_id") REFERENCES "time_slot"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "branch_service" ADD CONSTRAINT "branch_service_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branch"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "branch_service" ADD CONSTRAINT "branch_service_service_id_fkey" FOREIGN KEY ("service_id") REFERENCES "racket_service"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "cart" ADD CONSTRAINT "cart_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "app_user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "cart_item" ADD CONSTRAINT "cart_item_cart_id_fkey" FOREIGN KEY ("cart_id") REFERENCES "cart"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "cart_item" ADD CONSTRAINT "cart_item_product_variant_id_fkey" FOREIGN KEY ("product_variant_id") REFERENCES "product_variant"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "category" ADD CONSTRAINT "category_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "category"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "court" ADD CONSTRAINT "court_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branch"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "court_price" ADD CONSTRAINT "court_price_court_id_fkey" FOREIGN KEY ("court_id") REFERENCES "court"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "court_price" ADD CONSTRAINT "court_price_time_slot_id_fkey" FOREIGN KEY ("time_slot_id") REFERENCES "time_slot"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "customer_order" ADD CONSTRAINT "customer_order_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branch"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "customer_order" ADD CONSTRAINT "customer_order_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "app_user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "inventory" ADD CONSTRAINT "inventory_product_variant_id_fkey" FOREIGN KEY ("product_variant_id") REFERENCES "product_variant"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "news" ADD CONSTRAINT "news_author_user_id_fkey" FOREIGN KEY ("author_user_id") REFERENCES "app_user"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "news" ADD CONSTRAINT "news_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branch"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "notification" ADD CONSTRAINT "notification_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "app_user"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_item" ADD CONSTRAINT "order_item_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "customer_order"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_item" ADD CONSTRAINT "order_item_product_variant_id_fkey" FOREIGN KEY ("product_variant_id") REFERENCES "product_variant"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "product" ADD CONSTRAINT "product_brand_id_fkey" FOREIGN KEY ("brand_id") REFERENCES "brand"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "product" ADD CONSTRAINT "product_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "category"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "product_variant" ADD CONSTRAINT "product_variant_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "product"("id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "payment" ADD CONSTRAINT "payment_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "app_user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "review" ADD CONSTRAINT "review_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "app_user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favorite" ADD CONSTRAINT "favorite_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "app_user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customer_address" ADD CONSTRAINT "customer_address_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "app_user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "voucher_usage" ADD CONSTRAINT "voucher_usage_voucher_id_fkey" FOREIGN KEY ("voucher_id") REFERENCES "voucher"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "voucher_usage" ADD CONSTRAINT "voucher_usage_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "app_user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_fulfillment" ADD CONSTRAINT "order_fulfillment_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "customer_order"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "support_ticket" ADD CONSTRAINT "support_ticket_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "app_user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "support_ticket" ADD CONSTRAINT "support_ticket_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "app_user"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "support_ticket_message" ADD CONSTRAINT "support_ticket_message_ticket_id_fkey" FOREIGN KEY ("ticket_id") REFERENCES "support_ticket"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "support_ticket_message" ADD CONSTRAINT "support_ticket_message_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "app_user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contact_message" ADD CONSTRAINT "contact_message_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "app_user"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ================================================================
-- SanVaCau - SEED DATA PostgreSQL
-- Chạy SAU file SanVaCau_Database_PostgreSQL.sql
--
-- Đã làm sạch từ JSON nguồn:
-- * Giữ danh mục gốc hợp lệ.
-- * Brand được lưu ở bảng brand, không tạo category kiểu "Vợt ... Yonex".
-- * Không import các Name sản phẩm bị dính menu/navigation trong JSON nguồn.
-- * Tạo một bộ sản phẩm mẫu sạch, đúng schema để test database/app.
-- ================================================================

BEGIN;

-- 1. DANH MỤC

INSERT INTO category (name, parent_id, description, sort_order, is_active)
SELECT 'Vợt cầu lông', NULL, 'Danh mục Vợt cầu lông', 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = 'Vợt cầu lông' AND parent_id IS NULL);

INSERT INTO category (name, parent_id, description, sort_order, is_active)
SELECT 'Giày cầu lông', NULL, 'Danh mục Giày cầu lông', 2, TRUE
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = 'Giày cầu lông' AND parent_id IS NULL);

INSERT INTO category (name, parent_id, description, sort_order, is_active)
SELECT 'Áo cầu lông', NULL, 'Danh mục Áo cầu lông', 3, TRUE
WHERE NOT EXISTS (SELECT 1 FROM category WHERE name = 'Áo cầu lông' AND parent_id IS NULL);


-- 2. THƯƠNG HIỆU

INSERT INTO brand (name, description, is_active)
VALUES ('Li-Ning', 'Thương hiệu Li-Ning', TRUE)
ON CONFLICT (name) DO NOTHING;

INSERT INTO brand (name, description, is_active)
VALUES ('Victor', 'Thương hiệu Victor', TRUE)
ON CONFLICT (name) DO NOTHING;

INSERT INTO brand (name, description, is_active)
VALUES ('Yonex', 'Thương hiệu Yonex', TRUE)
ON CONFLICT (name) DO NOTHING;


-- 3. SẢN PHẨM MẪU SẠCH

INSERT INTO product (category_id, brand_id, name, description, image_url, is_active)
SELECT c.id, b.id, 'Vợt Yonex Astrox 88D Pro', 'Dữ liệu mẫu cho Vợt Yonex Astrox 88D Pro', NULL, TRUE
FROM category c JOIN brand b ON b.name = 'Yonex'
WHERE c.name = 'Vợt cầu lông' AND c.parent_id IS NULL
AND NOT EXISTS (SELECT 1 FROM product p WHERE p.name = 'Vợt Yonex Astrox 88D Pro');

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'V-T-YONEX-ASTROX-88D-PRO-4UG5', '4UG5', 4200000, NULL, TRUE
FROM product p WHERE p.name = 'Vợt Yonex Astrox 88D Pro'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'V-T-YONEX-ASTROX-88D-PRO-3UG5', '3UG5', 4300000, NULL, TRUE
FROM product p WHERE p.name = 'Vợt Yonex Astrox 88D Pro'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product (category_id, brand_id, name, description, image_url, is_active)
SELECT c.id, b.id, 'Vợt Li-Ning Axforce 80', 'Dữ liệu mẫu cho Vợt Li-Ning Axforce 80', NULL, TRUE
FROM category c JOIN brand b ON b.name = 'Li-Ning'
WHERE c.name = 'Vợt cầu lông' AND c.parent_id IS NULL
AND NOT EXISTS (SELECT 1 FROM product p WHERE p.name = 'Vợt Li-Ning Axforce 80');

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'V-T-LI-NING-AXFORCE-80-4UG5', '4UG5', 3900000, NULL, TRUE
FROM product p WHERE p.name = 'Vợt Li-Ning Axforce 80'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'V-T-LI-NING-AXFORCE-80-3UG5', '3UG5', 4000000, NULL, TRUE
FROM product p WHERE p.name = 'Vợt Li-Ning Axforce 80'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product (category_id, brand_id, name, description, image_url, is_active)
SELECT c.id, b.id, 'Giày Yonex Power Cushion', 'Dữ liệu mẫu cho Giày Yonex Power Cushion', NULL, TRUE
FROM category c JOIN brand b ON b.name = 'Yonex'
WHERE c.name = 'Giày cầu lông' AND c.parent_id IS NULL
AND NOT EXISTS (SELECT 1 FROM product p WHERE p.name = 'Giày Yonex Power Cushion');

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'GI-Y-YONEX-POWER-CUSHION-SIZE-39', 'Size 39', 2200000, NULL, TRUE
FROM product p WHERE p.name = 'Giày Yonex Power Cushion'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'GI-Y-YONEX-POWER-CUSHION-SIZE-40', 'Size 40', 2200000, NULL, TRUE
FROM product p WHERE p.name = 'Giày Yonex Power Cushion'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'GI-Y-YONEX-POWER-CUSHION-SIZE-41', 'Size 41', 2200000, NULL, TRUE
FROM product p WHERE p.name = 'Giày Yonex Power Cushion'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'GI-Y-YONEX-POWER-CUSHION-SIZE-42', 'Size 42', 2200000, NULL, TRUE
FROM product p WHERE p.name = 'Giày Yonex Power Cushion'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'GI-Y-YONEX-POWER-CUSHION-SIZE-43', 'Size 43', 2200000, NULL, TRUE
FROM product p WHERE p.name = 'Giày Yonex Power Cushion'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product (category_id, brand_id, name, description, image_url, is_active)
SELECT c.id, b.id, 'Giày Victor A970', 'Dữ liệu mẫu cho Giày Victor A970', NULL, TRUE
FROM category c JOIN brand b ON b.name = 'Victor'
WHERE c.name = 'Giày cầu lông' AND c.parent_id IS NULL
AND NOT EXISTS (SELECT 1 FROM product p WHERE p.name = 'Giày Victor A970');

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'GI-Y-VICTOR-A970-SIZE-39', 'Size 39', 2500000, NULL, TRUE
FROM product p WHERE p.name = 'Giày Victor A970'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'GI-Y-VICTOR-A970-SIZE-40', 'Size 40', 2500000, NULL, TRUE
FROM product p WHERE p.name = 'Giày Victor A970'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'GI-Y-VICTOR-A970-SIZE-41', 'Size 41', 2500000, NULL, TRUE
FROM product p WHERE p.name = 'Giày Victor A970'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'GI-Y-VICTOR-A970-SIZE-42', 'Size 42', 2500000, NULL, TRUE
FROM product p WHERE p.name = 'Giày Victor A970'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'GI-Y-VICTOR-A970-SIZE-43', 'Size 43', 2500000, NULL, TRUE
FROM product p WHERE p.name = 'Giày Victor A970'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product (category_id, brand_id, name, description, image_url, is_active)
SELECT c.id, b.id, 'Áo cầu lông Yonex Basic', 'Dữ liệu mẫu cho Áo cầu lông Yonex Basic', NULL, TRUE
FROM category c JOIN brand b ON b.name = 'Yonex'
WHERE c.name = 'Áo cầu lông' AND c.parent_id IS NULL
AND NOT EXISTS (SELECT 1 FROM product p WHERE p.name = 'Áo cầu lông Yonex Basic');

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'O-C-U-L-NG-YONEX-BASIC-SIZE-S', 'Size S', 450000, NULL, TRUE
FROM product p WHERE p.name = 'Áo cầu lông Yonex Basic'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'O-C-U-L-NG-YONEX-BASIC-SIZE-M', 'Size M', 450000, NULL, TRUE
FROM product p WHERE p.name = 'Áo cầu lông Yonex Basic'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'O-C-U-L-NG-YONEX-BASIC-SIZE-L', 'Size L', 450000, NULL, TRUE
FROM product p WHERE p.name = 'Áo cầu lông Yonex Basic'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'O-C-U-L-NG-YONEX-BASIC-SIZE-XL', 'Size XL', 450000, NULL, TRUE
FROM product p WHERE p.name = 'Áo cầu lông Yonex Basic'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'O-C-U-L-NG-YONEX-BASIC-SIZE-XXL', 'Size XXL', 450000, NULL, TRUE
FROM product p WHERE p.name = 'Áo cầu lông Yonex Basic'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product (category_id, brand_id, name, description, image_url, is_active)
SELECT c.id, b.id, 'Áo cầu lông Li-Ning Basic', 'Dữ liệu mẫu cho Áo cầu lông Li-Ning Basic', NULL, TRUE
FROM category c JOIN brand b ON b.name = 'Li-Ning'
WHERE c.name = 'Áo cầu lông' AND c.parent_id IS NULL
AND NOT EXISTS (SELECT 1 FROM product p WHERE p.name = 'Áo cầu lông Li-Ning Basic');

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'O-C-U-L-NG-LI-NING-BASIC-SIZE-S', 'Size S', 480000, NULL, TRUE
FROM product p WHERE p.name = 'Áo cầu lông Li-Ning Basic'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'O-C-U-L-NG-LI-NING-BASIC-SIZE-M', 'Size M', 480000, NULL, TRUE
FROM product p WHERE p.name = 'Áo cầu lông Li-Ning Basic'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'O-C-U-L-NG-LI-NING-BASIC-SIZE-L', 'Size L', 480000, NULL, TRUE
FROM product p WHERE p.name = 'Áo cầu lông Li-Ning Basic'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'O-C-U-L-NG-LI-NING-BASIC-SIZE-XL', 'Size XL', 480000, NULL, TRUE
FROM product p WHERE p.name = 'Áo cầu lông Li-Ning Basic'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_variant (product_id, sku, variant_name, price, image_url, is_active)
SELECT p.id, 'O-C-U-L-NG-LI-NING-BASIC-SIZE-XXL', 'Size XXL', 480000, NULL, TRUE
FROM product p WHERE p.name = 'Áo cầu lông Li-Ning Basic'
ON CONFLICT (sku) DO NOTHING;


COMMIT;

-- Kiểm tra nhanh sau khi chạy:
SELECT id, name, parent_id FROM category ORDER BY sort_order, id;
SELECT id, name FROM brand ORDER BY name;
SELECT p.id, p.name, c.name AS category, b.name AS brand
FROM product p
JOIN category c ON c.id = p.category_id
LEFT JOIN brand b ON b.id = p.brand_id
ORDER BY p.id;
SELECT pv.id, p.name AS product, pv.variant_name, pv.price
FROM product_variant pv
JOIN product p ON p.id = pv.product_id
ORDER BY p.id, pv.id;

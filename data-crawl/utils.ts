import * as fs from 'fs';
import * as path from 'path';

export function generateSKU(brand: string, id: number): string {
    const b = brand ? brand.substring(0, 3).toUpperCase() : 'VNB';
    return `${b}-${String(id).padStart(5, '0')}`;
}

export function saveJson(data: any, filename: string) {
    fs.writeFileSync(path.join(__dirname, filename), JSON.stringify(data, null, 2), 'utf-8');
}

export function saveSql(data: any, filename: string) {
    let sql = `USE SanVaCau;\nGO\n\n`;

    // Disable constraints temporarily if needed, or delete data (be careful with real DBs)
    // sql += `DELETE FROM dbo.ProductVariant;\nDELETE FROM dbo.Product;\nDELETE FROM dbo.Category;\nDELETE FROM dbo.Brand;\nGO\n\n`;

    // Extract brands
    const brands = new Set<string>();
    data.categories.forEach((cat: any) => {
        cat.products.forEach((p: any) => {
            if (p.BrandName) brands.add(p.BrandName);
        });
    });

    sql += `-- ======================= BRANDS =======================\n`;
    const brandMap = new Map<string, number>();
    let brandId = 1;
    Array.from(brands).forEach(brand => {
        if(brand) {
            sql += `INSERT INTO dbo.Brand (Name, Description, IsActive) VALUES (N'${brand.replace(/'/g, "''")}', N'Thương hiệu ${brand.replace(/'/g, "''")}', 1);\n`;
            brandMap.set(brand, brandId++);
        }
    });
    sql += `GO\n\n`;

    sql += `-- ===================== CATEGORIES =====================\n`;
    let catId = 1;
    const catIdMap = new Map<string, number>();

    // Insert Parent Categories
    data.categories.forEach((cat: any) => {
        if (cat.ParentName == null) {
            sql += `INSERT INTO dbo.Category (ParentId, Name, Description, IsActive) VALUES (NULL, N'${cat.Name.replace(/'/g, "''")}', NULL, 1);\n`;
            catIdMap.set(cat.Name, catId++);
        }
    });
    sql += `GO\n\n`;

    // Insert Sub Categories
    data.categories.forEach((cat: any) => {
        if (cat.ParentName != null) {
            const parentId = catIdMap.get(cat.ParentName) || 'NULL';
            sql += `INSERT INTO dbo.Category (ParentId, Name, Description, IsActive) VALUES (${parentId}, N'${cat.Name.replace(/'/g, "''")}', NULL, 1);\n`;
            catIdMap.set(cat.Name, catId++);
        }
    });
    sql += `GO\n\n`;

    sql += `-- ===================== PRODUCTS =======================\n`;
    let productId = 1;
    data.categories.forEach((cat: any) => {
        cat.products.forEach((p: any) => {
            const cId = catIdMap.get(cat.Name) || 1;
            const bId = brandMap.get(p.BrandName) || 'NULL';
            const img = p.ImageUrl ? `'${p.ImageUrl}'` : 'NULL';

            sql += `INSERT INTO dbo.Product (CategoryId, BrandId, Name, Description, ImageUrl, IsActive) VALUES (${cId}, ${bId}, N'${p.Name.replace(/'/g, "''")}', NULL, ${img}, 1);\n`;

            const price = p.Price || 0;

            p.Variants.forEach((v: any, vIndex: number) => {
                const sku = generateSKU(p.BrandName || 'VNB', (productId * 10) + vIndex);
                sql += `INSERT INTO dbo.ProductVariant (ProductId, SKU, VariantName, Price, ImageUrl, IsActive) VALUES (${productId}, '${sku}', N'${v.VariantName}', ${price}, ${img}, 1);\n`;
            });

            productId++;
        });
    });
    sql += `GO\n`;

    fs.writeFileSync(path.join(__dirname, filename), sql, 'utf-8');
}

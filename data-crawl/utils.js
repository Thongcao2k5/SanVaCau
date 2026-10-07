"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateSKU = generateSKU;
exports.saveJson = saveJson;
exports.saveSql = saveSql;
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
function generateSKU(brand, id) {
    const b = brand ? brand.substring(0, 3).toUpperCase() : 'VNB';
    return `${b}-${String(id).padStart(5, '0')}`;
}
function saveJson(data, filename) {
    fs.writeFileSync(path.join(__dirname, filename), JSON.stringify(data, null, 2), 'utf-8');
}
function saveSql(data, filename) {
    let sql = `USE SanVaCau;\nGO\n\n`;
    // Disable constraints temporarily if needed, or delete data (be careful with real DBs)
    // sql += `DELETE FROM dbo.ProductVariant;\nDELETE FROM dbo.Product;\nDELETE FROM dbo.Category;\nDELETE FROM dbo.Brand;\nGO\n\n`;
    // Extract brands
    const brands = new Set();
    data.categories.forEach((cat) => {
        cat.products.forEach((p) => {
            if (p.BrandName)
                brands.add(p.BrandName);
        });
    });
    sql += `-- ======================= BRANDS =======================\n`;
    const brandMap = new Map();
    let brandId = 1;
    Array.from(brands).forEach(brand => {
        if (brand) {
            sql += `INSERT INTO dbo.Brand (Name, Description, IsActive) VALUES (N'${brand.replace(/'/g, "''")}', N'Thương hiệu ${brand.replace(/'/g, "''")}', 1);\n`;
            brandMap.set(brand, brandId++);
        }
    });
    sql += `GO\n\n`;
    sql += `-- ===================== CATEGORIES =====================\n`;
    let catId = 1;
    const catIdMap = new Map();
    // Insert Parent Categories
    data.categories.forEach((cat) => {
        if (cat.ParentName == null) {
            sql += `INSERT INTO dbo.Category (ParentId, Name, Description, IsActive) VALUES (NULL, N'${cat.Name.replace(/'/g, "''")}', NULL, 1);\n`;
            catIdMap.set(cat.Name, catId++);
        }
    });
    sql += `GO\n\n`;
    // Insert Sub Categories
    data.categories.forEach((cat) => {
        if (cat.ParentName != null) {
            const parentId = catIdMap.get(cat.ParentName) || 'NULL';
            sql += `INSERT INTO dbo.Category (ParentId, Name, Description, IsActive) VALUES (${parentId}, N'${cat.Name.replace(/'/g, "''")}', NULL, 1);\n`;
            catIdMap.set(cat.Name, catId++);
        }
    });
    sql += `GO\n\n`;
    sql += `-- ===================== PRODUCTS =======================\n`;
    let productId = 1;
    data.categories.forEach((cat) => {
        cat.products.forEach((p) => {
            const cId = catIdMap.get(cat.Name) || 1;
            const bId = brandMap.get(p.BrandName) || 'NULL';
            const img = p.ImageUrl ? `'${p.ImageUrl}'` : 'NULL';
            sql += `INSERT INTO dbo.Product (CategoryId, BrandId, Name, Description, ImageUrl, IsActive) VALUES (${cId}, ${bId}, N'${p.Name.replace(/'/g, "''")}', NULL, ${img}, 1);\n`;
            const price = p.Price || 0;
            p.Variants.forEach((v, vIndex) => {
                const sku = generateSKU(p.BrandName || 'VNB', (productId * 10) + vIndex);
                sql += `INSERT INTO dbo.ProductVariant (ProductId, SKU, VariantName, Price, ImageUrl, IsActive) VALUES (${productId}, '${sku}', N'${v.VariantName}', ${price}, ${img}, 1);\n`;
            });
            productId++;
        });
    });
    sql += `GO\n`;
    fs.writeFileSync(path.join(__dirname, filename), sql, 'utf-8');
}

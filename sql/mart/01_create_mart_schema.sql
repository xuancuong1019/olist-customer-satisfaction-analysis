/* ==============================================================================
   PROJECT     : OLIST E-COMMERCE ANALYTICS
   SCRIPT NAME : 01_create_mart_schema_and_views.sql
   LAYER       : MART (Gold Layer - Analytics & BI Ready)
   PURPOSE     : 
       1. Khởi tạo schema [mart] dành riêng cho Data Analyst & Power BI.
   ============================================================================== */

USE e_commerce;
GO

-- 1. Khởi tạo Schema [mart] nếu chưa tồn tại
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'mart')
BEGIN
    EXEC('CREATE SCHEMA mart');
END;
GO
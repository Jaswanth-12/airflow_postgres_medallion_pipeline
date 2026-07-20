CREATE SCHEMA IF NOT EXISTS silver;

-- Clean CRM Customers
DROP TABLE IF EXISTS silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info AS
SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) IN ('S', 'SINGLE') THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) IN ('M', 'MARRIED') THEN 'Married'
        ELSE 'N/A'
    END AS cst_marital_status,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'N/A'
    END AS cst_gndr,
    cst_create_date
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL;

-- Clean CRM Products
DROP TABLE IF EXISTS silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info AS
SELECT 
    prd_id,
    prd_key,
    TRIM(prd_nm) AS prd_nm,
    COALESCE(prd_cost, 0) AS prd_cost,
    UPPER(TRIM(prd_line)) AS prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info;

-- Clean CRM Sales Details
-- Clean CRM Sales Details
DROP TABLE IF EXISTS silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details AS
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE 
        WHEN LENGTH(sls_order_dt::TEXT) = 8 THEN TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD') 
        ELSE NULL 
    END AS sls_order_dt,
    CASE 
        WHEN LENGTH(sls_ship_dt::TEXT) = 8 THEN TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD') 
        ELSE NULL 
    END AS sls_ship_dt,
    CASE 
        WHEN LENGTH(sls_due_dt::TEXT) = 8 THEN TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD') 
        ELSE NULL 
    END AS sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE sls_ord_num IS NOT NULL;

-- Clean ERP Customers
DROP TABLE IF EXISTS silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12 AS
SELECT 
    CASE 
        WHEN LOWER(cid) LIKE 'nas%' THEN SUBSTRING(cid FROM 4) 
        ELSE cid 
    END AS cid,
    bdate,
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'N/A'
    END AS gen
FROM bronze.erp_cust_az12;

-- Clean ERP Locations
DROP TABLE IF EXISTS silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101 AS
SELECT 
    REPLACE(cid, '-', '') AS cid,
    TRIM(cntry) AS cntry
FROM bronze.erp_loc_a101;

-- Clean ERP Product Categories
DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2 AS
SELECT 
    id,
    TRIM(cat) AS cat,
    TRIM(subcat) AS subcat,
    TRIM(maintenance) AS maintenance
FROM bronze.erp_px_cat_g1v2;
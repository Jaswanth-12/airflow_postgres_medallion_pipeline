CREATE SCHEMA IF NOT EXISTS gold;

-- Dimension: Customers
DROP TABLE IF EXISTS gold.dim_customers;
CREATE TABLE gold.dim_customers AS
SELECT 
    c.cst_id AS customer_id,
    c.cst_key AS customer_key,
    c.cst_firstname || ' ' || c.cst_lastname AS full_name,
    c.cst_marital_status,
    c.cst_gndr AS gender,
    e.bdate AS birth_date,
    l.cntry AS country,
    c.cst_create_date AS created_date
FROM silver.crm_cust_info c
LEFT JOIN silver.erp_cust_az12 e ON c.cst_key = e.cid
LEFT JOIN silver.erp_loc_a101 l ON c.cst_key = l.cid;

-- Dimension: Products
DROP TABLE IF EXISTS gold.dim_products;
CREATE TABLE gold.dim_products AS
SELECT 
    p.prd_id AS product_id,
    p.prd_key AS product_key,
    p.prd_nm AS product_name,
    p.prd_cost AS cost,
    p.prd_line AS product_line,
    cat.cat AS category,
    cat.subcat AS subcategory,
    cat.maintenance
FROM silver.crm_prd_info p
LEFT JOIN silver.erp_px_cat_g1v2 cat ON p.prd_key = cat.id;

-- Fact: Sales Orders
DROP TABLE IF EXISTS gold.fact_sales;
CREATE TABLE gold.fact_sales AS
SELECT 
    s.sls_ord_num AS order_number,
    p.product_id,
    c.customer_id,
    s.sls_order_dt AS order_date,
    s.sls_ship_dt AS ship_date,
    s.sls_due_dt AS due_date,
    s.sls_sales AS sales_amount,
    s.sls_quantity AS quantity,
    s.sls_price AS price
FROM silver.crm_sales_details s
LEFT JOIN gold.dim_products p ON s.sls_prd_key = p.product_key
LEFT JOIN gold.dim_customers c ON s.sls_cust_id = c.customer_id;
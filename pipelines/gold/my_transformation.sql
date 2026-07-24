-- Databricks notebook source
-- Gold Layer Transformations
-- Business metrics and aggregations from Silver layer

-- COMMAND ----------

-- Customer Analytics Summary
CREATE OR REFRESH MATERIALIZED VIEW gold_customer_summary
COMMENT 'Gold layer: Customer analytics with counts and distributions'
AS
SELECT 
  COUNT(DISTINCT customer_key) AS total_customers,
  COUNT(DISTINCT country) AS countries_count,
  COUNT(DISTINCT CASE WHEN gender = 'Female' THEN customer_key END) AS female_customers,
  COUNT(DISTINCT CASE WHEN gender = 'Male' THEN customer_key END) AS male_customers,
  ROUND(AVG(YEAR(CURRENT_DATE()) - YEAR(TO_DATE(birthdate, 'dd/MM/yyyy'))), 2) AS avg_customer_age,
  MIN(TO_DATE(create_date, 'dd/MM/yyyy')) AS first_customer_date,
  MAX(TO_DATE(create_date, 'dd/MM/yyyy')) AS last_customer_date
FROM dataingestionproject.silver.silver_v2_dim_customers;

-- COMMAND ----------

-- Customer Distribution by Country
CREATE OR REFRESH MATERIALIZED VIEW gold_customers_by_country
COMMENT 'Gold layer: Customer counts and percentages by country'
AS
WITH country_counts AS (
  SELECT 
    country,
    COUNT(*) AS customer_count
  FROM dataingestionproject.silver.silver_v2_dim_customers
  GROUP BY ALL
),
total AS (
  SELECT SUM(customer_count) AS total_customers
  FROM country_counts
)
SELECT 
  c.country,
  c.customer_count,
  ROUND(100.0 * c.customer_count / t.total_customers, 2) AS percentage
FROM country_counts c
CROSS JOIN total t
ORDER BY c.customer_count DESC;

-- COMMAND ----------

-- Customer Demographics
CREATE OR REFRESH MATERIALIZED VIEW gold_customer_demographics
COMMENT 'Gold layer: Customer segmentation by gender and marital status'
AS
SELECT 
  gender,
  marital_status,
  COUNT(*) AS customer_count,
  ROUND(AVG(YEAR(CURRENT_DATE()) - YEAR(TO_DATE(birthdate, 'dd/MM/yyyy'))), 1) AS avg_age,
  MIN(YEAR(CURRENT_DATE()) - YEAR(TO_DATE(birthdate, 'dd/MM/yyyy'))) AS min_age,
  MAX(YEAR(CURRENT_DATE()) - YEAR(TO_DATE(birthdate, 'dd/MM/yyyy'))) AS max_age
FROM dataingestionproject.silver.silver_v2_dim_customers
GROUP BY ALL
ORDER BY customer_count DESC;

-- COMMAND ----------

-- Product Analytics Summary
CREATE OR REFRESH MATERIALIZED VIEW gold_product_summary
COMMENT 'Gold layer: Product analytics with counts and cost metrics'
AS
SELECT 
  COUNT(DISTINCT product_key) AS total_products,
  COUNT(DISTINCT category) AS categories_count,
  COUNT(DISTINCT subcategory) AS subcategories_count,
  COUNT(DISTINCT product_line) AS product_lines_count,
  ROUND(AVG(cost), 2) AS avg_product_cost,
  ROUND(MIN(cost), 2) AS min_product_cost,
  ROUND(MAX(cost), 2) AS max_product_cost,
  ROUND(SUM(cost), 2) AS total_inventory_cost
FROM dataingestionproject.silver.silver_v2_dim_products;

-- COMMAND ----------

-- Products by Category
CREATE OR REFRESH MATERIALIZED VIEW gold_products_by_category
COMMENT 'Gold layer: Product counts and cost metrics by category'
AS
SELECT 
  category,
  COUNT(*) AS product_count,
  COUNT(DISTINCT subcategory) AS subcategory_count,
  ROUND(AVG(cost), 2) AS avg_cost,
  ROUND(MIN(cost), 2) AS min_cost,
  ROUND(MAX(cost), 2) AS max_cost,
  ROUND(SUM(cost), 2) AS total_cost
FROM dataingestionproject.silver.silver_v2_dim_products
GROUP BY ALL
ORDER BY product_count DESC;

-- COMMAND ----------

-- Products by Subcategory (Top 20)
CREATE OR REFRESH MATERIALIZED VIEW gold_products_by_subcategory
COMMENT 'Gold layer: Product counts and metrics by subcategory'
AS
SELECT 
  category,
  subcategory,
  COUNT(*) AS product_count,
  ROUND(AVG(cost), 2) AS avg_cost,
  ROUND(SUM(cost), 2) AS total_cost
FROM dataingestionproject.silver.silver_v2_dim_products
GROUP BY ALL
ORDER BY product_count DESC
LIMIT 20;

-- COMMAND ----------

-- Sales Overview
CREATE OR REFRESH MATERIALIZED VIEW gold_sales_summary
COMMENT 'Gold layer: Overall sales metrics and KPIs'
AS
SELECT 
  COUNT(DISTINCT order_number) AS total_orders,
  COUNT(*) AS total_line_items,
  SUM(quantity) AS total_quantity_sold,
  ROUND(SUM(sales_amount), 2) AS total_sales_amount,
  ROUND(AVG(sales_amount), 2) AS avg_order_line_value,
  ROUND(AVG(quantity), 2) AS avg_quantity_per_line,
  ROUND(AVG(price), 2) AS avg_price,
  MIN(TO_DATE(order_date, 'dd/MM/yyyy')) AS first_order_date,
  MAX(TO_DATE(order_date, 'dd/MM/yyyy')) AS last_order_date,
  COUNT(DISTINCT customer_key) AS unique_customers,
  COUNT(DISTINCT product_key) AS unique_products_sold
FROM dataingestionproject.silver.silver_v2_fact_sales;

-- COMMAND ----------

-- Daily Sales Trends
CREATE OR REFRESH MATERIALIZED VIEW gold_daily_sales
COMMENT 'Gold layer: Daily sales aggregations for trend analysis'
AS
SELECT 
  TO_DATE(order_date, 'dd/MM/yyyy') AS order_date,
  COUNT(DISTINCT order_number) AS orders_count,
  COUNT(*) AS line_items_count,
  SUM(quantity) AS total_quantity,
  ROUND(SUM(sales_amount), 2) AS total_sales,
  ROUND(AVG(sales_amount), 2) AS avg_line_value,
  COUNT(DISTINCT customer_key) AS unique_customers,
  COUNT(DISTINCT product_key) AS unique_products
FROM dataingestionproject.silver.silver_v2_fact_sales
GROUP BY ALL
ORDER BY order_date;

-- COMMAND ----------

-- Monthly Sales Trends
CREATE OR REFRESH MATERIALIZED VIEW gold_monthly_sales
COMMENT 'Gold layer: Monthly sales aggregations for reporting'
AS
SELECT 
  YEAR(TO_DATE(order_date, 'dd/MM/yyyy')) AS year,
  MONTH(TO_DATE(order_date, 'dd/MM/yyyy')) AS month,
  DATE_FORMAT(TO_DATE(order_date, 'dd/MM/yyyy'), 'yyyy-MM') AS year_month,
  COUNT(DISTINCT order_number) AS orders_count,
  COUNT(*) AS line_items_count,
  SUM(quantity) AS total_quantity,
  ROUND(SUM(sales_amount), 2) AS total_sales,
  ROUND(AVG(sales_amount), 2) AS avg_line_value,
  COUNT(DISTINCT customer_key) AS unique_customers,
  COUNT(DISTINCT product_key) AS unique_products
FROM dataingestionproject.silver.silver_v2_fact_sales
GROUP BY ALL
ORDER BY year, month;

-- COMMAND ----------

-- Top Customers by Sales
CREATE OR REFRESH MATERIALIZED VIEW gold_top_customers
COMMENT 'Gold layer: Top customers ranked by total sales amount'
AS
SELECT 
  s.customer_key,
  c.first_name,
  c.last_name,
  c.country,
  c.gender,
  COUNT(DISTINCT s.order_number) AS total_orders,
  SUM(s.quantity) AS total_quantity,
  ROUND(SUM(s.sales_amount), 2) AS total_sales,
  ROUND(AVG(s.sales_amount), 2) AS avg_order_value,
  MIN(TO_DATE(s.order_date, 'dd/MM/yyyy')) AS first_order_date,
  MAX(TO_DATE(s.order_date, 'dd/MM/yyyy')) AS last_order_date
FROM dataingestionproject.silver.silver_v2_fact_sales s
LEFT JOIN dataingestionproject.silver.silver_v2_dim_customers c
  ON s.customer_key = c.customer_key
GROUP BY ALL
ORDER BY total_sales DESC
LIMIT 100;

-- COMMAND ----------

-- Top Products by Sales
CREATE OR REFRESH MATERIALIZED VIEW gold_top_products
COMMENT 'Gold layer: Top products ranked by total sales amount'
AS
SELECT 
  s.product_key,
  p.product_name,
  p.category,
  p.subcategory,
  p.product_line,
  COUNT(DISTINCT s.order_number) AS orders_count,
  SUM(s.quantity) AS total_quantity_sold,
  ROUND(SUM(s.sales_amount), 2) AS total_sales,
  ROUND(AVG(s.sales_amount), 2) AS avg_sale_value,
  ROUND(AVG(s.price), 2) AS avg_price,
  ROUND(MAX(p.cost), 2) AS product_cost,
  ROUND(SUM(s.sales_amount) - (SUM(s.quantity) * MAX(p.cost)), 2) AS total_profit
FROM dataingestionproject.silver.silver_v2_fact_sales s
LEFT JOIN dataingestionproject.silver.silver_v2_dim_products p
  ON s.product_key = p.product_key
GROUP BY ALL
ORDER BY total_sales DESC
LIMIT 100;

-- COMMAND ----------

-- Sales by Product Category
CREATE OR REFRESH MATERIALIZED VIEW gold_sales_by_category
COMMENT 'Gold layer: Sales performance by product category'
AS
SELECT 
  p.category,
  COUNT(DISTINCT s.order_number) AS orders_count,
  COUNT(DISTINCT s.product_key) AS products_sold,
  SUM(s.quantity) AS total_quantity,
  ROUND(SUM(s.sales_amount), 2) AS total_sales,
  ROUND(AVG(s.sales_amount), 2) AS avg_sale_value,
  COUNT(DISTINCT s.customer_key) AS unique_customers
FROM dataingestionproject.silver.silver_v2_fact_sales s
LEFT JOIN dataingestionproject.silver.silver_v2_dim_products p
  ON s.product_key = p.product_key
GROUP BY ALL
ORDER BY total_sales DESC;

-- COMMAND ----------

-- Sales by Country
CREATE OR REFRESH MATERIALIZED VIEW gold_sales_by_country
COMMENT 'Gold layer: Sales performance by customer country'
AS
SELECT 
  c.country,
  COUNT(DISTINCT s.order_number) AS orders_count,
  COUNT(DISTINCT s.customer_key) AS unique_customers,
  SUM(s.quantity) AS total_quantity,
  ROUND(SUM(s.sales_amount), 2) AS total_sales,
  ROUND(AVG(s.sales_amount), 2) AS avg_order_value,
  COUNT(DISTINCT s.product_key) AS unique_products
FROM dataingestionproject.silver.silver_v2_fact_sales s
LEFT JOIN dataingestionproject.silver.silver_v2_dim_customers c
  ON s.customer_key = c.customer_key
GROUP BY ALL
ORDER BY total_sales DESC;

-- COMMAND ----------

-- Customer Lifetime Value (CLV)
CREATE OR REFRESH MATERIALIZED VIEW gold_customer_lifetime_value
COMMENT 'Gold layer: Customer lifetime value with purchase patterns'
AS
SELECT 
  s.customer_key,
  c.first_name,
  c.last_name,
  c.country,
  c.gender,
  c.marital_status,
  COUNT(DISTINCT s.order_number) AS lifetime_orders,
  SUM(s.quantity) AS lifetime_quantity,
  ROUND(SUM(s.sales_amount), 2) AS lifetime_value,
  ROUND(AVG(s.sales_amount), 2) AS avg_transaction_value,
  MIN(TO_DATE(s.order_date, 'dd/MM/yyyy')) AS first_purchase_date,
  MAX(TO_DATE(s.order_date, 'dd/MM/yyyy')) AS last_purchase_date,
  DATEDIFF(MAX(TO_DATE(s.order_date, 'dd/MM/yyyy')), MIN(TO_DATE(s.order_date, 'dd/MM/yyyy'))) AS customer_tenure_days,
  CASE 
    WHEN DATEDIFF(MAX(TO_DATE(s.order_date, 'dd/MM/yyyy')), MIN(TO_DATE(s.order_date, 'dd/MM/yyyy'))) > 0
    THEN ROUND(COUNT(DISTINCT s.order_number) * 365.0 / DATEDIFF(MAX(TO_DATE(s.order_date, 'dd/MM/yyyy')), MIN(TO_DATE(s.order_date, 'dd/MM/yyyy'))), 2)
    ELSE NULL
  END AS annual_order_frequency
FROM dataingestionproject.silver.silver_v2_fact_sales s
LEFT JOIN dataingestionproject.silver.silver_v2_dim_customers c
  ON s.customer_key = c.customer_key
GROUP BY ALL
ORDER BY lifetime_value DESC;

-- COMMAND ----------

-- Order Fulfillment Metrics
CREATE OR REFRESH MATERIALIZED VIEW gold_order_fulfillment
COMMENT 'Gold layer: Order fulfillment and delivery performance metrics'
AS
SELECT 
  TO_DATE(order_date, 'dd/MM/yyyy') AS order_date,
  COUNT(DISTINCT order_number) AS orders_count,
  ROUND(AVG(DATEDIFF(TO_DATE(shipping_date, 'dd/MM/yyyy'), TO_DATE(order_date, 'dd/MM/yyyy'))), 2) AS avg_days_to_ship,
  ROUND(AVG(DATEDIFF(TO_DATE(due_date, 'dd/MM/yyyy'), TO_DATE(order_date, 'dd/MM/yyyy'))), 2) AS avg_days_to_due,
  SUM(CASE WHEN TO_DATE(shipping_date, 'dd/MM/yyyy') <= TO_DATE(due_date, 'dd/MM/yyyy') THEN 1 ELSE 0 END) AS on_time_shipments,
  SUM(CASE WHEN TO_DATE(shipping_date, 'dd/MM/yyyy') > TO_DATE(due_date, 'dd/MM/yyyy') THEN 1 ELSE 0 END) AS late_shipments,
  ROUND(100.0 * SUM(CASE WHEN TO_DATE(shipping_date, 'dd/MM/yyyy') <= TO_DATE(due_date, 'dd/MM/yyyy') THEN 1 ELSE 0 END) / COUNT(DISTINCT order_number), 2) AS on_time_percentage
FROM dataingestionproject.silver.silver_v2_fact_sales
GROUP BY ALL
ORDER BY order_date;

-- COMMAND ----------

-- ===========================================
-- SURVEY DATA ANALYTICS
-- ===========================================

-- Annual Enterprise Survey - Industry Analysis
CREATE OR REFRESH MATERIALIZED VIEW gold_enterprise_survey_by_industry
COMMENT 'Gold layer: Annual enterprise survey aggregated by industry'
AS
SELECT 
  Industry_name_NZSIOC,
  Industry_code_NZSIOC,
  Industry_aggregation_NZSIOC,
  COUNT(DISTINCT Variable_name) AS metrics_count,
  COUNT(DISTINCT Variable_category) AS categories_count,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY ALL
ORDER BY total_records DESC;

-- COMMAND ----------

-- Annual Enterprise Survey - Variable Category Analysis
CREATE OR REFRESH MATERIALIZED VIEW gold_enterprise_survey_by_category
COMMENT 'Gold layer: Enterprise survey metrics by variable category'
AS
SELECT 
  Variable_category,
  Variable_name,
  COUNT(DISTINCT Industry_name_NZSIOC) AS industries_count,
  COUNT(*) AS total_records,
  COUNT(DISTINCT Units) AS unit_types
FROM dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY ALL
ORDER BY total_records DESC;

-- COMMAND ----------

-- Annual Enterprise Survey - Year-over-Year Trends
CREATE OR REFRESH MATERIALIZED VIEW gold_enterprise_survey_trends
COMMENT 'Gold layer: Enterprise survey trends by year and industry'
AS
SELECT 
  `ï»¿Year` AS survey_year,
  Industry_aggregation_NZSIOC,
  COUNT(DISTINCT Industry_name_NZSIOC) AS industries_count,
  COUNT(DISTINCT Variable_name) AS variables_count,
  COUNT(*) AS total_observations
FROM dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY ALL
ORDER BY survey_year, total_observations DESC;

-- COMMAND ----------

-- Business Operations Survey 2022 - Finance Metrics by Industry
CREATE OR REFRESH MATERIALIZED VIEW gold_business_finance_2022_by_industry
COMMENT 'Gold layer: 2022 business finance metrics by industry'
AS
SELECT 
  industry,
  COUNT(DISTINCT description) AS metrics_count,
  COUNT(DISTINCT line_code) AS line_codes_count,
  SUM(value) AS total_value,
  ROUND(AVG(value), 2) AS avg_value,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY ALL
ORDER BY total_value DESC;

-- COMMAND ----------

-- Business Operations Survey 2022 - Finance by Business Size
CREATE OR REFRESH MATERIALIZED VIEW gold_business_finance_2022_by_size
COMMENT 'Gold layer: 2022 business finance by company size'
AS
SELECT 
  size,
  COUNT(DISTINCT industry) AS industries_count,
  COUNT(DISTINCT description) AS metrics_count,
  SUM(value) AS total_value,
  ROUND(AVG(value), 2) AS avg_value,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY ALL
ORDER BY total_value DESC;

-- COMMAND ----------

-- Business Operations Survey 2022 - Finance Matrix (Industry x Size)
CREATE OR REFRESH MATERIALIZED VIEW gold_business_finance_2022_matrix
COMMENT 'Gold layer: 2022 finance cross-tabulation by industry and size'
AS
SELECT 
  industry,
  size,
  COUNT(DISTINCT description) AS metrics_count,
  SUM(value) AS total_value,
  ROUND(AVG(value), 2) AS avg_value,
  COUNT(*) AS observations
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY ALL
ORDER BY industry, total_value DESC;

-- COMMAND ----------

-- Business Operations Survey 2023 - Practices by Industry
CREATE OR REFRESH MATERIALIZED VIEW gold_business_practices_2023_by_industry
COMMENT 'Gold layer: 2023 business practices adoption by industry'
AS
SELECT 
  industry,
  COUNT(DISTINCT description) AS practices_count,
  COUNT(DISTINCT line_code) AS line_codes_count,
  SUM(value) AS total_adoption_score,
  ROUND(AVG(value), 2) AS avg_adoption,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2023_business_practices
GROUP BY ALL
ORDER BY total_adoption_score DESC;

-- COMMAND ----------

-- Business Operations Survey 2023 - Practices by Size
CREATE OR REFRESH MATERIALIZED VIEW gold_business_practices_2023_by_size
COMMENT 'Gold layer: 2023 business practices by company size'
AS
SELECT 
  size,
  COUNT(DISTINCT industry) AS industries_count,
  COUNT(DISTINCT description) AS practices_count,
  SUM(value) AS total_adoption_score,
  ROUND(AVG(value), 2) AS avg_adoption,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2023_business_practices
GROUP BY ALL
ORDER BY total_adoption_score DESC;

-- COMMAND ----------

-- Business Operations Survey 2023 - Climate Change by Industry
CREATE OR REFRESH MATERIALIZED VIEW gold_climate_2023_by_industry
COMMENT 'Gold layer: 2023 climate change response by industry'
AS
SELECT 
  industry,
  COUNT(DISTINCT description) AS climate_metrics_count,
  COUNT(DISTINCT line_code) AS line_codes_count,
  SUM(value) AS total_response_score,
  ROUND(AVG(value), 2) AS avg_response,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2023_climate_change
GROUP BY ALL
ORDER BY total_response_score DESC;

-- COMMAND ----------

-- Business Operations Survey 2023 - Climate by Size
CREATE OR REFRESH MATERIALIZED VIEW gold_climate_2023_by_size
COMMENT 'Gold layer: 2023 climate change response by company size'
AS
SELECT 
  size,
  COUNT(DISTINCT industry) AS industries_count,
  COUNT(DISTINCT description) AS climate_metrics_count,
  SUM(value) AS total_response_score,
  ROUND(AVG(value), 2) AS avg_response,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2023_climate_change
GROUP BY ALL
ORDER BY total_response_score DESC;

-- COMMAND ----------

-- ===========================================
-- ALTERNATIVE CUSTOMER DATA ANALYTICS
-- ===========================================

-- Customer Info - Demographics Summary
CREATE OR REFRESH MATERIALIZED VIEW gold_cust_info_demographics
COMMENT 'Gold layer: Customer info demographics and distributions'
AS
SELECT 
  COUNT(DISTINCT cst_id) AS total_customers,
  COUNT(DISTINCT CASE WHEN cst_gender = 'Female' THEN cst_id END) AS female_count,
  COUNT(DISTINCT CASE WHEN cst_gender = 'Male' THEN cst_id END) AS male_count,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN cst_gender = 'Female' THEN cst_id END) / COUNT(DISTINCT cst_id), 2) AS female_percentage,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN cst_gender = 'Male' THEN cst_id END) / COUNT(DISTINCT cst_id), 2) AS male_percentage,
  COUNT(DISTINCT cst_marital_status) AS marital_status_count
FROM dataingestionproject.silver.silver_v2_cust_info;

-- COMMAND ----------

-- Customer Info - Segmentation by Gender and Marital Status
CREATE OR REFRESH MATERIALIZED VIEW gold_cust_info_segmentation
COMMENT 'Gold layer: Customer segmentation from cust_info'
AS
SELECT 
  cst_gender,
  cst_marital_status,
  COUNT(*) AS customer_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM dataingestionproject.silver.silver_v2_cust_info
GROUP BY ALL
ORDER BY customer_count DESC;

-- COMMAND ----------

-- Customer AZ12 - Demographics Analysis
CREATE OR REFRESH MATERIALIZED VIEW gold_cust_az12_demographics
COMMENT 'Gold layer: AZ12 customer demographics summary'
AS
SELECT 
  COUNT(DISTINCT CID) AS total_customers,
  COUNT(DISTINCT GEN) AS gender_types,
  COUNT(DISTINCT BDATE) AS unique_birthdates
FROM dataingestionproject.silver.silver_v2_cust_az12;

-- COMMAND ----------

-- Customer AZ12 - Gender Distribution
CREATE OR REFRESH MATERIALIZED VIEW gold_cust_az12_by_gender
COMMENT 'Gold layer: AZ12 customer distribution by gender'
AS
SELECT 
  GEN AS gender,
  COUNT(*) AS customer_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM dataingestionproject.silver.silver_v2_cust_az12
WHERE GEN IS NOT NULL
GROUP BY ALL
ORDER BY customer_count DESC;

-- COMMAND ----------

-- Location A101 - Geographic Distribution
CREATE OR REFRESH MATERIALIZED VIEW gold_loc_a101_by_country
COMMENT 'Gold layer: Customer geographic distribution from location A101'
AS
SELECT 
  CNTRY AS country,
  COUNT(DISTINCT CID) AS customer_count,
  ROUND(100.0 * COUNT(DISTINCT CID) / SUM(COUNT(DISTINCT CID)) OVER (), 2) AS percentage
FROM dataingestionproject.silver.silver_v2_loc_a101
WHERE CNTRY IS NOT NULL
GROUP BY ALL
ORDER BY customer_count DESC;

-- COMMAND ----------

-- ===========================================
-- ALTERNATIVE PRODUCT DATA ANALYTICS
-- ===========================================

-- Product Info - Summary Metrics
CREATE OR REFRESH MATERIALIZED VIEW gold_prd_info_summary
COMMENT 'Gold layer: Product info summary metrics'
AS
SELECT 
  COUNT(DISTINCT prd_id) AS total_products,
  COUNT(DISTINCT prd_line) AS product_lines_count,
  ROUND(AVG(prd_cost), 2) AS avg_cost,
  ROUND(MIN(prd_cost), 2) AS min_cost,
  ROUND(MAX(prd_cost), 2) AS max_cost,
  ROUND(SUM(prd_cost), 2) AS total_inventory_cost
FROM dataingestionproject.silver.silver_v2_prd_info
WHERE prd_cost IS NOT NULL;

-- COMMAND ----------

-- Product Info - Analysis by Product Line
CREATE OR REFRESH MATERIALIZED VIEW gold_prd_info_by_line
COMMENT 'Gold layer: Product metrics by product line'
AS
SELECT 
  prd_line,
  COUNT(DISTINCT prd_id) AS product_count,
  ROUND(AVG(prd_cost), 2) AS avg_cost,
  ROUND(MIN(prd_cost), 2) AS min_cost,
  ROUND(MAX(prd_cost), 2) AS max_cost,
  ROUND(SUM(prd_cost), 2) AS total_cost
FROM dataingestionproject.silver.silver_v2_prd_info
WHERE prd_line IS NOT NULL AND prd_cost IS NOT NULL
GROUP BY ALL
ORDER BY product_count DESC;

-- COMMAND ----------

-- Product Category - Category Analysis
CREATE OR REFRESH MATERIALIZED VIEW gold_px_cat_summary
COMMENT 'Gold layer: Product category summary'
AS
SELECT 
  COUNT(DISTINCT ID) AS total_products,
  COUNT(DISTINCT CAT) AS categories_count,
  COUNT(DISTINCT SUBCAT) AS subcategories_count,
  COUNT(DISTINCT MAINTENANCE) AS maintenance_types
FROM dataingestionproject.silver.silver_v2_px_cat_g1v2;

-- COMMAND ----------

-- Product Category - Distribution by Category
CREATE OR REFRESH MATERIALIZED VIEW gold_px_cat_by_category
COMMENT 'Gold layer: Product distribution by category'
AS
SELECT 
  CAT AS category,
  COUNT(DISTINCT ID) AS product_count,
  COUNT(DISTINCT SUBCAT) AS subcategory_count,
  ROUND(100.0 * COUNT(DISTINCT ID) / SUM(COUNT(DISTINCT ID)) OVER (), 2) AS percentage
FROM dataingestionproject.silver.silver_v2_px_cat_g1v2
WHERE CAT IS NOT NULL
GROUP BY ALL
ORDER BY product_count DESC;

-- COMMAND ----------

-- Product Category - By Subcategory
CREATE OR REFRESH MATERIALIZED VIEW gold_px_cat_by_subcategory
COMMENT 'Gold layer: Product distribution by category and subcategory'
AS
SELECT 
  CAT AS category,
  SUBCAT AS subcategory,
  COUNT(DISTINCT ID) AS product_count,
  ROUND(100.0 * COUNT(DISTINCT ID) / SUM(COUNT(DISTINCT ID)) OVER (), 2) AS percentage
FROM dataingestionproject.silver.silver_v2_px_cat_g1v2
WHERE CAT IS NOT NULL AND SUBCAT IS NOT NULL
GROUP BY ALL
ORDER BY product_count DESC
LIMIT 50;

-- COMMAND ----------

-- ===========================================
-- ALTERNATIVE SALES DATA ANALYTICS
-- ===========================================

-- Sales Details - Summary Metrics
CREATE OR REFRESH MATERIALIZED VIEW gold_sales_details_summary
COMMENT 'Gold layer: Sales details overall summary'
AS
SELECT 
  COUNT(DISTINCT sls_ord_num) AS total_orders,
  COUNT(*) AS total_line_items,
  COUNT(DISTINCT sls_prd_key) AS unique_products,
  COUNT(DISTINCT sls_cust_id) AS unique_customers,
  SUM(sls_quantity) AS total_quantity_sold,
  ROUND(SUM(sls_sales), 2) AS total_sales_amount,
  ROUND(AVG(sls_sales), 2) AS avg_sale_amount,
  ROUND(AVG(sls_quantity), 2) AS avg_quantity,
  ROUND(AVG(sls_price), 2) AS avg_price
FROM dataingestionproject.silver.silver_v2_sales_details;

-- COMMAND ----------

-- Sales Details - Top Customers
CREATE OR REFRESH MATERIALIZED VIEW gold_sales_details_top_customers
COMMENT 'Gold layer: Top customers from sales details'
AS
SELECT 
  sls_cust_id,
  COUNT(DISTINCT sls_ord_num) AS total_orders,
  COUNT(*) AS line_items_count,
  SUM(sls_quantity) AS total_quantity,
  ROUND(SUM(sls_sales), 2) AS total_sales,
  ROUND(AVG(sls_sales), 2) AS avg_order_value,
  COUNT(DISTINCT sls_prd_key) AS products_purchased
FROM dataingestionproject.silver.silver_v2_sales_details
GROUP BY ALL
ORDER BY total_sales DESC
LIMIT 100;

-- COMMAND ----------

-- Sales Details - Top Products
CREATE OR REFRESH MATERIALIZED VIEW gold_sales_details_top_products
COMMENT 'Gold layer: Top products from sales details'
AS
SELECT 
  sls_prd_key,
  COUNT(DISTINCT sls_ord_num) AS orders_count,
  COUNT(DISTINCT sls_cust_id) AS unique_customers,
  SUM(sls_quantity) AS total_quantity_sold,
  ROUND(SUM(sls_sales), 2) AS total_sales,
  ROUND(AVG(sls_sales), 2) AS avg_sale_value,
  ROUND(AVG(sls_price), 2) AS avg_price
FROM dataingestionproject.silver.silver_v2_sales_details
GROUP BY ALL
ORDER BY total_sales DESC
LIMIT 100;
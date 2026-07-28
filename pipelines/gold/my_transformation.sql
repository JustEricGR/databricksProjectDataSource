CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_business_finance_2022_by_industry` (
  industry STRING COLLATE UTF8_BINARY,
  metrics_count BIGINT,
  line_codes_count BIGINT,
  total_value BIGINT,
  avg_value DOUBLE,
  total_records BIGINT)
COMMENT 'Gold layer: 2022 business finance metrics by industry'
AS SELECT 
  industry,
  COUNT(DISTINCT description) AS metrics_count,
  COUNT(DISTINCT line_code) AS line_codes_count,
  SUM(value) AS total_value,
  ROUND(AVG(value), 2) AS avg_value,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY ALL
ORDER BY total_value DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_business_finance_2022_by_size` (
  size STRING COLLATE UTF8_BINARY,
  industries_count BIGINT,
  metrics_count BIGINT,
  total_value BIGINT,
  avg_value DOUBLE,
  total_records BIGINT)
COMMENT 'Gold layer: 2022 business finance by company size'
AS SELECT 
  size,
  COUNT(DISTINCT industry) AS industries_count,
  COUNT(DISTINCT description) AS metrics_count,
  SUM(value) AS total_value,
  ROUND(AVG(value), 2) AS avg_value,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY ALL
ORDER BY total_value DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_business_finance_2022_matrix` (
  industry STRING COLLATE UTF8_BINARY,
  size STRING COLLATE UTF8_BINARY,
  metrics_count BIGINT,
  total_value BIGINT,
  avg_value DOUBLE,
  observations BIGINT)
COMMENT 'Gold layer: 2022 finance cross-tabulation by industry and size'
AS SELECT 
  industry,
  size,
  COUNT(DISTINCT description) AS metrics_count,
  SUM(value) AS total_value,
  ROUND(AVG(value), 2) AS avg_value,
  COUNT(*) AS observations
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY ALL
ORDER BY industry, total_value DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_business_practices_2023_by_industry` (
  industry STRING COLLATE UTF8_BINARY,
  practices_count BIGINT,
  line_codes_count BIGINT,
  total_adoption_score BIGINT,
  avg_adoption DOUBLE,
  total_records BIGINT)
COMMENT 'Gold layer: 2023 business practices adoption by industry'
AS SELECT 
  industry,
  COUNT(DISTINCT description) AS practices_count,
  COUNT(DISTINCT line_code) AS line_codes_count,
  SUM(value) AS total_adoption_score,
  ROUND(AVG(value), 2) AS avg_adoption,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2023_business_practices
GROUP BY ALL
ORDER BY total_adoption_score DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_business_practices_2023_by_size` (
  size STRING COLLATE UTF8_BINARY,
  industries_count BIGINT,
  practices_count BIGINT,
  total_adoption_score BIGINT,
  avg_adoption DOUBLE,
  total_records BIGINT)
COMMENT 'Gold layer: 2023 business practices by company size'
AS SELECT 
  size,
  COUNT(DISTINCT industry) AS industries_count,
  COUNT(DISTINCT description) AS practices_count,
  SUM(value) AS total_adoption_score,
  ROUND(AVG(value), 2) AS avg_adoption,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2023_business_practices
GROUP BY ALL
ORDER BY total_adoption_score DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_climate_2023_by_industry` (
  industry STRING COLLATE UTF8_BINARY,
  climate_metrics_count BIGINT,
  line_codes_count BIGINT,
  total_response_score BIGINT,
  avg_response DOUBLE,
  total_records BIGINT)
COMMENT 'Gold layer: 2023 climate change response by industry'
AS SELECT 
  industry,
  COUNT(DISTINCT description) AS climate_metrics_count,
  COUNT(DISTINCT line_code) AS line_codes_count,
  SUM(value) AS total_response_score,
  ROUND(AVG(value), 2) AS avg_response,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2023_climate_change
GROUP BY ALL
ORDER BY total_response_score DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_climate_2023_by_size` (
  size STRING COLLATE UTF8_BINARY,
  industries_count BIGINT,
  climate_metrics_count BIGINT,
  total_response_score BIGINT,
  avg_response DOUBLE,
  total_records BIGINT)
COMMENT 'Gold layer: 2023 climate change response by company size'
AS SELECT 
  size,
  COUNT(DISTINCT industry) AS industries_count,
  COUNT(DISTINCT description) AS climate_metrics_count,
  SUM(value) AS total_response_score,
  ROUND(AVG(value), 2) AS avg_response,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_business_operations_survey_2023_climate_change
GROUP BY ALL
ORDER BY total_response_score DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_cust_az12_by_gender` (
  gender STRING COLLATE UTF8_BINARY,
  customer_count BIGINT,
  percentage DECIMAL(27,2))
COMMENT 'Gold layer: AZ12 customer distribution by gender'
AS SELECT 
  GEN AS gender,
  COUNT(*) AS customer_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM dataingestionproject.silver.silver_v2_cust_az12
WHERE GEN IS NOT NULL
GROUP BY ALL
ORDER BY customer_count DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_cust_az12_demographics` (
  total_customers BIGINT,
  gender_types BIGINT,
  unique_birthdates BIGINT)
COMMENT 'Gold layer: AZ12 customer demographics summary'
AS SELECT 
  COUNT(DISTINCT CID) AS total_customers,
  COUNT(DISTINCT GEN) AS gender_types,
  COUNT(DISTINCT BDATE) AS unique_birthdates
FROM dataingestionproject.silver.silver_v2_cust_az12;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_cust_info_demographics` (
  total_customers BIGINT,
  female_count BIGINT,
  male_count BIGINT,
  female_percentage DECIMAL(27,2),
  male_percentage DECIMAL(27,2),
  marital_status_count BIGINT)
COMMENT 'Gold layer: Customer info demographics and distributions'
AS SELECT 
  COUNT(DISTINCT cst_id) AS total_customers,
  COUNT(DISTINCT CASE WHEN cst_gender = 'Female' THEN cst_id END) AS female_count,
  COUNT(DISTINCT CASE WHEN cst_gender = 'Male' THEN cst_id END) AS male_count,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN cst_gender = 'Female' THEN cst_id END) / COUNT(DISTINCT cst_id), 2) AS female_percentage,
  ROUND(100.0 * COUNT(DISTINCT CASE WHEN cst_gender = 'Male' THEN cst_id END) / COUNT(DISTINCT cst_id), 2) AS male_percentage,
  COUNT(DISTINCT cst_marital_status) AS marital_status_count
FROM dataingestionproject.silver.silver_v2_cust_info;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_cust_info_segmentation` (
  cst_gender STRING COLLATE UTF8_BINARY,
  cst_marital_status STRING COLLATE UTF8_BINARY,
  customer_count BIGINT,
  percentage DECIMAL(27,2))
COMMENT 'Gold layer: Customer segmentation from cust_info'
AS SELECT 
  cst_gender,
  cst_marital_status,
  COUNT(*) AS customer_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM dataingestionproject.silver.silver_v2_cust_info
GROUP BY ALL
ORDER BY customer_count DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_customer_demographics` (
  gender STRING COLLATE UTF8_BINARY,
  marital_status STRING COLLATE UTF8_BINARY,
  customer_count BIGINT,
  avg_age DOUBLE,
  min_age INT,
  max_age INT)
COMMENT 'Gold layer: Customer segmentation by gender and marital status'
AS SELECT 
  gender,
  marital_status,
  COUNT(*) AS customer_count,
  ROUND(AVG(YEAR(CURRENT_DATE()) - YEAR(TO_DATE(birthdate, 'dd/MM/yyyy'))), 1) AS avg_age,
  MIN(YEAR(CURRENT_DATE()) - YEAR(TO_DATE(birthdate, 'dd/MM/yyyy'))) AS min_age,
  MAX(YEAR(CURRENT_DATE()) - YEAR(TO_DATE(birthdate, 'dd/MM/yyyy'))) AS max_age
FROM dataingestionproject.silver.silver_v2_dim_customers
GROUP BY ALL
ORDER BY customer_count DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_customer_lifetime_value` (
  customer_key BIGINT,
  first_name STRING COLLATE UTF8_BINARY,
  last_name STRING COLLATE UTF8_BINARY,
  country STRING COLLATE UTF8_BINARY,
  gender STRING COLLATE UTF8_BINARY,
  marital_status STRING COLLATE UTF8_BINARY,
  lifetime_orders BIGINT,
  lifetime_quantity BIGINT,
  lifetime_value BIGINT,
  avg_transaction_value DOUBLE,
  first_purchase_date DATE,
  last_purchase_date DATE,
  customer_tenure_days INT,
  annual_order_frequency DECIMAL(27,2))
COMMENT 'Gold layer: Customer lifetime value with purchase patterns'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_customer_summary` (
  total_customers BIGINT,
  countries_count BIGINT,
  female_customers BIGINT,
  male_customers BIGINT,
  avg_customer_age DOUBLE,
  first_customer_date DATE,
  last_customer_date DATE)
COMMENT 'Gold layer: Customer analytics with counts and distributions'
AS SELECT 
  COUNT(DISTINCT customer_key) AS total_customers,
  COUNT(DISTINCT country) AS countries_count,
  COUNT(DISTINCT CASE WHEN gender = 'Female' THEN customer_key END) AS female_customers,
  COUNT(DISTINCT CASE WHEN gender = 'Male' THEN customer_key END) AS male_customers,
  ROUND(AVG(YEAR(CURRENT_DATE()) - YEAR(TO_DATE(birthdate, 'dd/MM/yyyy'))), 2) AS avg_customer_age,
  MIN(TO_DATE(create_date, 'dd/MM/yyyy')) AS first_customer_date,
  MAX(TO_DATE(create_date, 'dd/MM/yyyy')) AS last_customer_date
FROM dataingestionproject.silver.silver_v2_dim_customers;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_customers_by_country` (
  country STRING COLLATE UTF8_BINARY,
  customer_count BIGINT,
  percentage DECIMAL(27,2))
COMMENT 'Gold layer: Customer counts and percentages by country'
AS WITH country_counts AS (
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_daily_sales` (
  order_date DATE,
  orders_count BIGINT,
  line_items_count BIGINT,
  total_quantity BIGINT,
  total_sales BIGINT,
  avg_line_value DOUBLE,
  unique_customers BIGINT,
  unique_products BIGINT)
COMMENT 'Gold layer: Daily sales aggregations for trend analysis'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_enterprise_survey_by_category` (
  Variable_category STRING COLLATE UTF8_BINARY,
  Variable_name STRING COLLATE UTF8_BINARY,
  industries_count BIGINT,
  total_records BIGINT,
  unit_types BIGINT)
COMMENT 'Gold layer: Enterprise survey metrics by variable category'
AS SELECT 
  Variable_category,
  Variable_name,
  COUNT(DISTINCT Industry_name_NZSIOC) AS industries_count,
  COUNT(*) AS total_records,
  COUNT(DISTINCT Units) AS unit_types
FROM dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY ALL
ORDER BY total_records DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_enterprise_survey_by_industry` (
  Industry_name_NZSIOC STRING COLLATE UTF8_BINARY,
  Industry_code_NZSIOC STRING COLLATE UTF8_BINARY,
  Industry_aggregation_NZSIOC STRING COLLATE UTF8_BINARY,
  metrics_count BIGINT,
  categories_count BIGINT,
  total_records BIGINT)
COMMENT 'Gold layer: Annual enterprise survey aggregated by industry'
AS SELECT 
  Industry_name_NZSIOC,
  Industry_code_NZSIOC,
  Industry_aggregation_NZSIOC,
  COUNT(DISTINCT Variable_name) AS metrics_count,
  COUNT(DISTINCT Variable_category) AS categories_count,
  COUNT(*) AS total_records
FROM dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY ALL
ORDER BY total_records DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_enterprise_survey_trends` (
  survey_year BIGINT,
  Industry_aggregation_NZSIOC STRING COLLATE UTF8_BINARY,
  industries_count BIGINT,
  variables_count BIGINT,
  total_observations BIGINT)
COMMENT 'Gold layer: Enterprise survey trends by year and industry'
AS SELECT 
  `Year` AS survey_year,
  Industry_aggregation_NZSIOC,
  COUNT(DISTINCT Industry_name_NZSIOC) AS industries_count,
  COUNT(DISTINCT Variable_name) AS variables_count,
  COUNT(*) AS total_observations
FROM dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY ALL
ORDER BY survey_year, total_observations DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_loc_a101_by_country` (
  country STRING COLLATE UTF8_BINARY,
  customer_count BIGINT,
  percentage DECIMAL(27,2))
COMMENT 'Gold layer: Customer geographic distribution from location A101'
AS SELECT 
  CNTRY AS country,
  COUNT(DISTINCT CID) AS customer_count,
  ROUND(100.0 * COUNT(DISTINCT CID) / SUM(COUNT(DISTINCT CID)) OVER (), 2) AS percentage
FROM dataingestionproject.silver.silver_v2_loc_a101
WHERE CNTRY IS NOT NULL
GROUP BY ALL
ORDER BY customer_count DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_order_fulfillment` (
  order_date DATE,
  orders_count BIGINT,
  avg_days_to_ship DOUBLE,
  avg_days_to_due DOUBLE,
  on_time_shipments BIGINT,
  late_shipments BIGINT,
  on_time_percentage DECIMAL(27,2))
COMMENT 'Gold layer: Order fulfillment and delivery performance metrics'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_prd_info_by_line` (
  prd_line STRING COLLATE UTF8_BINARY,
  product_count BIGINT,
  avg_cost DOUBLE,
  min_cost DOUBLE,
  max_cost DOUBLE,
  total_cost DOUBLE)
COMMENT 'Gold layer: Product metrics by product line'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_prd_info_summary` (
  total_products BIGINT,
  product_lines_count BIGINT,
  avg_cost DOUBLE,
  min_cost DOUBLE,
  max_cost DOUBLE,
  total_inventory_cost DOUBLE)
COMMENT 'Gold layer: Product info summary metrics'
AS SELECT 
  COUNT(DISTINCT prd_id) AS total_products,
  COUNT(DISTINCT prd_line) AS product_lines_count,
  ROUND(AVG(prd_cost), 2) AS avg_cost,
  ROUND(MIN(prd_cost), 2) AS min_cost,
  ROUND(MAX(prd_cost), 2) AS max_cost,
  ROUND(SUM(prd_cost), 2) AS total_inventory_cost
FROM dataingestionproject.silver.silver_v2_prd_info
WHERE prd_cost IS NOT NULL;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_product_summary` (
  total_products BIGINT,
  categories_count BIGINT,
  subcategories_count BIGINT,
  product_lines_count BIGINT,
  avg_product_cost DOUBLE,
  min_product_cost BIGINT,
  max_product_cost BIGINT,
  total_inventory_cost BIGINT)
COMMENT 'Gold layer: Product analytics with counts and cost metrics'
AS SELECT 
  COUNT(DISTINCT product_key) AS total_products,
  COUNT(DISTINCT category) AS categories_count,
  COUNT(DISTINCT subcategory) AS subcategories_count,
  COUNT(DISTINCT product_line) AS product_lines_count,
  ROUND(AVG(cost), 2) AS avg_product_cost,
  ROUND(MIN(cost), 2) AS min_product_cost,
  ROUND(MAX(cost), 2) AS max_product_cost,
  ROUND(SUM(cost), 2) AS total_inventory_cost
FROM dataingestionproject.silver.silver_v2_dim_products;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_products_by_category` (
  category STRING COLLATE UTF8_BINARY,
  product_count BIGINT,
  subcategory_count BIGINT,
  avg_cost DOUBLE,
  min_cost BIGINT,
  max_cost BIGINT,
  total_cost BIGINT)
COMMENT 'Gold layer: Product counts and cost metrics by category'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_products_by_subcategory` (
  category STRING COLLATE UTF8_BINARY,
  subcategory STRING COLLATE UTF8_BINARY,
  product_count BIGINT,
  avg_cost DOUBLE,
  total_cost BIGINT)
COMMENT 'Gold layer: Product counts and metrics by subcategory'
AS SELECT 
  category,
  subcategory,
  COUNT(*) AS product_count,
  ROUND(AVG(cost), 2) AS avg_cost,
  ROUND(SUM(cost), 2) AS total_cost
FROM dataingestionproject.silver.silver_v2_dim_products
GROUP BY ALL
ORDER BY product_count DESC
LIMIT 20;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_px_cat_by_category` (
  category STRING COLLATE UTF8_BINARY,
  product_count BIGINT,
  subcategory_count BIGINT,
  percentage DECIMAL(27,2))
COMMENT 'Gold layer: Product distribution by category'
AS SELECT 
  CAT AS category,
  COUNT(DISTINCT ID) AS product_count,
  COUNT(DISTINCT SUBCAT) AS subcategory_count,
  ROUND(100.0 * COUNT(DISTINCT ID) / SUM(COUNT(DISTINCT ID)) OVER (), 2) AS percentage
FROM dataingestionproject.silver.silver_v2_px_cat_g1v2
WHERE CAT IS NOT NULL
GROUP BY ALL
ORDER BY product_count DESC;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_px_cat_by_subcategory` (
  category STRING COLLATE UTF8_BINARY,
  subcategory STRING COLLATE UTF8_BINARY,
  product_count BIGINT,
  percentage DECIMAL(27,2))
COMMENT 'Gold layer: Product distribution by category and subcategory'
AS SELECT 
  CAT AS category,
  SUBCAT AS subcategory,
  COUNT(DISTINCT ID) AS product_count,
  ROUND(100.0 * COUNT(DISTINCT ID) / SUM(COUNT(DISTINCT ID)) OVER (), 2) AS percentage
FROM dataingestionproject.silver.silver_v2_px_cat_g1v2
WHERE CAT IS NOT NULL AND SUBCAT IS NOT NULL
GROUP BY ALL
ORDER BY product_count DESC
LIMIT 50;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_px_cat_summary` (
  total_products BIGINT,
  categories_count BIGINT,
  subcategories_count BIGINT,
  maintenance_types BIGINT)
COMMENT 'Gold layer: Product category summary'
AS SELECT 
  COUNT(DISTINCT ID) AS total_products,
  COUNT(DISTINCT CAT) AS categories_count,
  COUNT(DISTINCT SUBCAT) AS subcategories_count,
  COUNT(DISTINCT MAINTENANCE) AS maintenance_types
FROM dataingestionproject.silver.silver_v2_px_cat_g1v2;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_sales_by_category` (
  category STRING COLLATE UTF8_BINARY,
  orders_count BIGINT,
  products_sold BIGINT,
  total_quantity BIGINT,
  total_sales BIGINT,
  avg_sale_value DOUBLE,
  unique_customers BIGINT)
COMMENT 'Gold layer: Sales performance by product category'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_sales_by_country` (
  country STRING COLLATE UTF8_BINARY,
  orders_count BIGINT,
  unique_customers BIGINT,
  total_quantity BIGINT,
  total_sales BIGINT,
  avg_order_value DOUBLE,
  unique_products BIGINT)
COMMENT 'Gold layer: Sales performance by customer country'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_sales_details_summary` (
  total_orders BIGINT,
  total_line_items BIGINT,
  unique_products BIGINT,
  unique_customers BIGINT,
  total_quantity_sold BIGINT,
  total_sales_amount DOUBLE,
  avg_sale_amount DOUBLE,
  avg_quantity DOUBLE,
  avg_price DOUBLE)
COMMENT 'Gold layer: Sales details overall summary'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_sales_details_top_customers` (
  sls_cust_id BIGINT,
  total_orders BIGINT,
  line_items_count BIGINT,
  total_quantity BIGINT,
  total_sales DOUBLE,
  avg_order_value DOUBLE,
  products_purchased BIGINT)
COMMENT 'Gold layer: Top customers from sales details'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_sales_details_top_products` (
  sls_prd_key STRING COLLATE UTF8_BINARY,
  orders_count BIGINT,
  unique_customers BIGINT,
  total_quantity_sold BIGINT,
  total_sales DOUBLE,
  avg_sale_value DOUBLE,
  avg_price DOUBLE)
COMMENT 'Gold layer: Top products from sales details'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_sales_summary` (
  total_orders BIGINT,
  total_line_items BIGINT,
  total_quantity_sold BIGINT,
  total_sales_amount BIGINT,
  avg_order_line_value DOUBLE,
  avg_quantity_per_line DOUBLE,
  avg_price DOUBLE,
  first_order_date DATE,
  last_order_date DATE,
  unique_customers BIGINT,
  unique_products_sold BIGINT)
COMMENT 'Gold layer: Overall sales metrics and KPIs'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_top_customers` (
  customer_key BIGINT,
  first_name STRING COLLATE UTF8_BINARY,
  last_name STRING COLLATE UTF8_BINARY,
  country STRING COLLATE UTF8_BINARY,
  gender STRING COLLATE UTF8_BINARY,
  total_orders BIGINT,
  total_quantity BIGINT,
  total_sales BIGINT,
  avg_order_value DOUBLE,
  first_order_date DATE,
  last_order_date DATE)
COMMENT 'Gold layer: Top customers ranked by total sales amount'
AS SELECT 
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

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_top_products` (
  product_key BIGINT,
  product_name STRING COLLATE UTF8_BINARY,
  category STRING COLLATE UTF8_BINARY,
  subcategory STRING COLLATE UTF8_BINARY,
  product_line STRING COLLATE UTF8_BINARY,
  orders_count BIGINT,
  total_quantity_sold BIGINT,
  total_sales BIGINT,
  avg_sale_value DOUBLE,
  avg_price DOUBLE,
  product_cost BIGINT,
  total_profit BIGINT)
COMMENT 'Gold layer: Top products ranked by total sales amount'
AS SELECT 
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

-- ── AI Generated: silver_v2_annual_enterprise_survey_2025_financial_year_provisional ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_survey_totals AS
SELECT 
  COUNT(*) AS total_rows,
  SUM(CAST(Value AS DOUBLE)) AS total_value,
  AVG(CAST(Value AS DOUBLE)) AS average_value
FROM 
  dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_survey_by_industry AS
SELECT 
  Industry_name_NZSIOC,
  SUM(CAST(Value AS DOUBLE)) AS total_value,
  AVG(CAST(Value AS DOUBLE)) AS average_value,
  COUNT(*) AS total_rows
FROM 
  dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY 
  Industry_name_NZSIOC
ORDER BY 
  total_value DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_top_10_industries_by_value AS
SELECT 
  Industry_name_NZSIOC,
  SUM(CAST(Value AS DOUBLE)) AS total_value
FROM 
  dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY 
  Industry_name_NZSIOC
ORDER BY 
  total_value DESC
LIMIT 10;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_survey_summary AS
SELECT 
  variable, 
  SUM(CAST(value AS DOUBLE)) AS total_value, 
  AVG(CAST(value AS DOUBLE)) AS average_value, 
  COUNT(*) AS count
FROM 
  dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands
WHERE 
  unit = 'DOLLARS(millions)'
GROUP BY 
  variable;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gross_automobile_statistics AS
SELECT 
  COUNT(*) AS total_vehicles,
  SUM(Selling_Price) AS total_selling_price,
  AVG(Selling_Price) AS average_selling_price,
  SUM(Mileage) AS total_mileage,
  AVG(Mileage) AS average_mileage,
  SUM(Horsepower) AS total_horsepower,
  AVG(Horsepower) AS average_horsepower
FROM dataingestionproject.silver.silver_v2_automobile_dataset;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.automobiles_by_make AS
SELECT 
  Make,
  COUNT(*) AS vehicle_count,
  SUM(Selling_Price) AS total_selling_price,
  AVG(Selling_Price) AS average_selling_price,
  SUM(Mileage) AS total_mileage,
  AVG(Mileage) AS average_mileage
FROM dataingestionproject.silver.silver_v2_automobile_dataset
GROUP BY Make
ORDER BY vehicle_count DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_top_n_industries AS 
SELECT 
  industry, 
  SUM(value) as total_value
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY 
  industry
ORDER BY 
  total_value DESC
LIMIT 10;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_survey_by_size AS 
SELECT 
  size, 
  COUNT(*) as count, 
  SUM(value) as total_value, 
  AVG(value) as average_value
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY 
  size
ORDER BY 
  total_value DESC;

-- ── AI Generated: silver_v2_business_operations_survey_2023_business_practices ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_survey_top_10_industries AS
SELECT 
  industry, 
  SUM(value) AS total_value
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2023_climate_change
GROUP BY 
  industry
ORDER BY 
  total_value DESC
LIMIT 10;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_accessories_summary AS
SELECT 
  COUNT(ID) AS total_count, 
  COUNT(DISTINCT CAT) AS unique_cats, 
  COUNT(DISTINCT SUBCAT) AS unique_subcats, 
  SUM(CASE WHEN MAINTENANCE = 'Yes' THEN 1 ELSE 0 END) AS maintenance_count, 
  SUM(CASE WHEN MAINTENANCE = 'No' THEN 1 ELSE 0 END) AS no_maintenance_count, 
  AVG(CASE WHEN MAINTENANCE = 'Yes' THEN 1.0 ELSE 0 END) AS maintenance_avg
FROM 
  dataingestionproject.silver.silver_v2_px_cat_g1v2;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_accessories_by_category AS
SELECT 
  CAT, 
  COUNT(ID) AS count, 
  SUM(CASE WHEN MAINTENANCE = 'Yes' THEN 1 ELSE 0 END) AS maintenance_count, 
  SUM(CASE WHEN MAINTENANCE = 'No' THEN 1 ELSE 0 END) AS no_maintenance_count, 
  AVG(CASE WHEN MAINTENANCE = 'Yes' THEN 1.0 ELSE 0 END) AS maintenance_avg
FROM 
  dataingestionproject.silver.silver_v2_px_cat_g1v2
GROUP BY 
  CAT
ORDER BY 
  count DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_top_subcategories AS
SELECT 
  SUBCAT, 
  COUNT(ID) AS count, 
  SUM(CASE WHEN MAINTENANCE = 'Yes' THEN 1 ELSE 0 END) AS maintenance_count, 
  SUM(CASE WHEN MAINTENANCE = 'No' THEN 1 ELSE 0 END) AS no_maintenance_count, 
  AVG(CASE WHEN MAINTENANCE = 'Yes' THEN 1.0 ELSE 0 END) AS maintenance_avg,
  RANK() OVER (ORDER BY COUNT(ID) DESC) AS rank
FROM 
  dataingestionproject.silver.silver_v2_px_cat_g1v2
GROUP BY 
  SUBCAT
ORDER BY 
  rank ASC;

-- ── AI Generated: silver_v2_student_performance_dataset ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_student_performance_summary AS
SELECT 
  COUNT(student_id) AS total_students,
  SUM(final_exam_score) AS total_final_exam_score,
  AVG(study_time_hours) AS average_study_time_hours,
  AVG(attendance_percent) AS average_attendance_percent,
  AVG(sleep_hours) AS average_sleep_hours,
  AVG(previous_grade) AS average_previous_grade,
  AVG(final_exam_score) AS average_final_exam_score
FROM dataingestionproject.silver.silver_v2_student_performance_dataset;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_student_performance_by_gender AS
SELECT 
  gender,
  COUNT(student_id) AS total_students,
  AVG(study_time_hours) AS average_study_time_hours,
  AVG(attendance_percent) AS average_attendance_percent,
  AVG(sleep_hours) AS average_sleep_hours,
  AVG(previous_grade) AS average_previous_grade,
  AVG(final_exam_score) AS average_final_exam_score
FROM dataingestionproject.silver.silver_v2_student_performance_dataset
GROUP BY gender
ORDER BY gender;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_top_5_students_by_final_exam_score AS
SELECT 
  student_id,
  final_exam_score,
  previous_grade,
  study_time_hours,
  attendance_percent,
  sleep_hours,
  RANK() OVER (ORDER BY final_exam_score DESC) AS rank
FROM dataingestionproject.silver.silver_v2_student_performance_dataset
ORDER BY final_exam_score DESC
LIMIT 5;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_student_performance_by_parental_education AS
SELECT 
  parental_education,
  COUNT(student_id) AS total_students,
  AVG(study_time_hours) AS average_study_time_hours,
  AVG(attendance_percent) AS average_attendance_percent,
  AVG(sleep_hours) AS average_sleep_hours,
  AVG(previous_grade) AS average_previous_grade,
  AVG(final_exam_score) AS average_final_exam_score
FROM dataingestionproject.silver.silver_v2_student_performance_dataset
GROUP BY parental_education
ORDER BY parental_education;

-- ── AI Generated: silver_v2_annual_enterprise_survey_2025_financial_year_provisional ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_annual_enterprise_survey_2025_financial_year_provisional_summary AS
SELECT 
  Industry_aggregation_NZSIOC,
  Industry_name_NZSIOC,
  COUNT(*) as count,
  SUM(CAST(Value AS DOUBLE)) as total_value,
  AVG(CAST(Value AS DOUBLE)) as average_value
FROM 
  dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY 
  Industry_aggregation_NZSIOC,
  Industry_name_NZSIOC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_annual_enterprise_survey_2025_financial_year_provisional_by_industry AS
SELECT 
  Industry_name_NZSIOC,
  Variable_name,
  SUM(CAST(Value AS DOUBLE)) as total_value
FROM 
  dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY 
  Industry_name_NZSIOC,
  Variable_name
ORDER BY 
  Industry_name_NZSIOC,
  total_value DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_annual_enterprise_survey_2025_financial_year_provisional_top_10_variables AS
SELECT 
  Variable_name,
  SUM(CAST(Value AS DOUBLE)) as total_value
FROM 
  dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional
GROUP BY 
  Variable_name
ORDER BY 
  total_value DESC
LIMIT 10;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_annual_enterprise_survey_2025_financial_year_provisional_size_bands_summary AS
SELECT 
  industry_code_ANZSIC,
  industry_name_ANZSIC,
  rme_size_grp,
  COUNT(DISTINCT variable) AS num_variables,
  SUM(CASE WHEN unit = 'DOLLARS(millions)' THEN CAST(value AS DOUBLE) ELSE 0 END) AS total_dollars,
  AVG(CASE WHEN unit = 'COUNT' THEN CAST(value AS DOUBLE) ELSE NULL END) AS avg_count
FROM 
  dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands
GROUP BY 
  industry_code_ANZSIC,
  industry_name_ANZSIC,
  rme_size_grp;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_annual_enterprise_survey_2025_financial_year_provisional_size_bands_breakdown_by_industry AS
SELECT 
  industry_code_ANZSIC,
  industry_name_ANZSIC,
  variable,
  SUM(CASE WHEN unit = 'DOLLARS(millions)' THEN CAST(value AS DOUBLE) ELSE 0 END) AS total_dollars,
  AVG(CASE WHEN unit = 'COUNT' THEN CAST(value AS DOUBLE) ELSE NULL END) AS avg_count
FROM 
  dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands
GROUP BY 
  industry_code_ANZSIC,
  industry_name_ANZSIC,
  variable
ORDER BY 
  industry_code_ANZSIC,
  variable;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_annual_enterprise_survey_2025_financial_year_provisional_size_bands_top_industries_by_dollars AS
SELECT 
  industry_code_ANZSIC,
  industry_name_ANZSIC,
  SUM(CASE WHEN unit = 'DOLLARS(millions)' THEN CAST(value AS DOUBLE) ELSE 0 END) AS total_dollars
FROM 
  dataingestionproject.silver.silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands
GROUP BY 
  industry_code_ANZSIC,
  industry_name_ANZSIC
ORDER BY 
  total_dollars DESC
LIMIT 10;

-- ── AI Generated: silver_v2_automobile_dataset ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.automobile_dataset_summary AS
SELECT 
  COUNT(*) AS total_vehicles,
  SUM(Selling_Price) AS total_revenue,
  AVG(Selling_Price) AS average_selling_price,
  AVG(Mileage) AS average_mileage,
  AVG(Horsepower) AS average_horsepower,
  AVG(Fuel_Efficiency) AS average_fuel_efficiency
FROM dataingestionproject.silver.silver_v2_automobile_dataset;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.automobile_dataset_by_make AS
SELECT 
  Make,
  COUNT(*) AS vehicle_count,
  SUM(Selling_Price) AS total_revenue,
  AVG(Selling_Price) AS average_selling_price,
  AVG(Mileage) AS average_mileage,
  AVG(Horsepower) AS average_horsepower,
  AVG(Fuel_Efficiency) AS average_fuel_efficiency
FROM dataingestionproject.silver.silver_v2_automobile_dataset
GROUP BY Make
ORDER BY vehicle_count DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.business_operations_survey_2022_business_finance_summary AS
SELECT 
  COUNT(*) AS total_records,
  SUM(value) AS total_value,
  AVG(value) AS average_value
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.business_operations_survey_2022_business_finance_by_industry AS
SELECT 
  industry,
  COUNT(*) AS record_count,
  SUM(value) AS total_value,
  AVG(value) AS average_value
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY 
  industry
ORDER BY 
  total_value DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.business_operations_survey_2022_business_finance_top_10_industries AS
SELECT 
  industry,
  SUM(value) AS total_value
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY 
  industry
ORDER BY 
  total_value DESC
LIMIT 10;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.business_operations_survey_2022_business_finance_by_level AS
SELECT 
  level,
  COUNT(*) AS record_count,
  SUM(value) AS total_value,
  AVG(value) AS average_value
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2022_business_finance
GROUP BY 
  level
ORDER BY 
  level ASC;

-- ── AI Generated: silver_v2_business_operations_survey_2023_business_practices ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_business_operations_survey_2023_business_practices_summary AS 
SELECT 
  industry, 
  COUNT(*) as count, 
  SUM(value) as total_value, 
  AVG(value) as average_value 
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2023_business_practices 
GROUP BY 
  industry;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_business_operations_survey_2023_business_practices_by_industry AS 
SELECT 
  industry, 
  size, 
  SUM(value) as total_value 
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2023_business_practices 
GROUP BY 
  industry, 
  size 
ORDER BY 
  industry, 
  total_value DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_business_operations_survey_2023_business_practices_top_10_industries AS 
SELECT 
  industry, 
  SUM(value) as total_value 
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2023_business_practices 
GROUP BY 
  industry 
ORDER BY 
  total_value DESC 
LIMIT 10;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_business_operations_survey_2023_business_practices_size_distribution AS 
SELECT 
  size, 
  COUNT(*) as count, 
  SUM(value) as total_value 
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2023_business_practices 
GROUP BY 
  size 
ORDER BY 
  count DESC;

-- ── AI Generated: silver_v2_business_operations_survey_2023_climate_change ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_business_operations_survey_2023_climate_change_summary AS
SELECT 
  industry, 
  COUNT(value) as count_of_businesses, 
  SUM(value) as total_value, 
  AVG(value) as average_value
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2023_climate_change
GROUP BY 
  industry
ORDER BY 
  total_value DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_business_operations_survey_2023_climate_change_by_size AS
SELECT 
  size, 
  COUNT(value) as count_of_businesses, 
  SUM(value) as total_value
FROM 
  dataingestionproject.silver.silver_v2_business_operations_survey_2023_climate_change
GROUP BY 
  size
ORDER BY 
  total_value DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_business_operations_survey_2023_climate_change_top_industries AS
SELECT 
  industry, 
  value
FROM 
  (
    SELECT 
      industry, 
      value, 
      RANK() OVER (ORDER BY value DESC) as rank
    FROM 
      dataingestionproject.silver.silver_v2_business_operations_survey_2023_climate_change
  ) subquery
WHERE 
  rank <= 10
ORDER BY 
  value DESC;

-- ── AI Generated: silver_v2_dim_customers ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_dim_customers_summary AS
SELECT 
  COUNT(*) AS total_customers,
  SUM(CASE WHEN marital_status = 'Married' THEN 1 ELSE 0 END) AS married_customers,
  SUM(CASE WHEN marital_status = 'Single' THEN 1 ELSE 0 END) AS single_customers,
  AVG(LENGTH(first_name)) AS avg_first_name_length
FROM dataingestionproject.silver.silver_v2_dim_customers;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_dim_customers_by_marital_status AS
SELECT 
  marital_status,
  COUNT(*) AS customers_count,
  SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) AS male_customers,
  SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS female_customers
FROM dataingestionproject.silver.silver_v2_dim_customers
GROUP BY marital_status
ORDER BY customers_count DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_dim_customers_top_n_by_name_length AS
SELECT 
  first_name,
  last_name,
  LENGTH(first_name) + LENGTH(last_name) AS total_name_length
FROM dataingestionproject.silver.silver_v2_dim_customers
ORDER BY total_name_length DESC
LIMIT 10;

-- ── AI Generated: silver_v2_dim_products ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_dim_products_summary AS
SELECT 
  COUNT(product_key) AS total_products,
  SUM(cost) AS total_cost,
  AVG(cost) AS average_cost
FROM 
  dataingestionproject.silver.silver_v2_dim_products;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_dim_products_by_category AS
SELECT 
  category,
  COUNT(product_key) AS product_count,
  SUM(cost) AS total_cost,
  AVG(cost) AS average_cost
FROM 
  dataingestionproject.silver.silver_v2_dim_products
GROUP BY 
  category
ORDER BY 
  product_count DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_dim_products_time_series AS
SELECT 
  TO_DATE(start_date, 'MM/dd/yyyy') AS start_date,
  COUNT(product_key) AS products_added,
  SUM(cost) AS total_cost
FROM 
  dataingestionproject.silver.silver_v2_dim_products
GROUP BY 
  TO_DATE(start_date, 'MM/dd/yyyy')
ORDER BY 
  start_date ASC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_dim_products_top_cost AS
SELECT 
  product_name,
  product_number,
  cost,
  RANK() OVER (ORDER BY cost DESC) AS cost_rank
FROM 
  dataingestionproject.silver.silver_v2_dim_products
ORDER BY 
  cost DESC;

-- ── AI Generated: silver_v2_fact_sales ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_fact_sales_summary AS
SELECT 
  COUNT(order_number) AS total_orders,
  SUM(sales_amount) AS total_sales,
  AVG(sales_amount) AS average_sales
FROM 
  dataingestionproject.silver.silver_v2_fact_sales;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_fact_sales_by_customer AS
SELECT 
  customer_key,
  COUNT(order_number) AS num_orders,
  SUM(sales_amount) AS total_sales
FROM 
  dataingestionproject.silver.silver_v2_fact_sales
GROUP BY 
  customer_key
ORDER BY 
  total_sales DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_fact_sales_time_series AS
SELECT 
  TO_DATE(order_date, 'dd/MM/yyyy') AS order_date,
  SUM(sales_amount) AS daily_sales
FROM 
  dataingestionproject.silver.silver_v2_fact_sales
GROUP BY 
  order_date
ORDER BY 
  order_date;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_fact_sales_top_customers AS
SELECT 
  customer_key,
  SUM(sales_amount) AS total_sales
FROM 
  dataingestionproject.silver.silver_v2_fact_sales
GROUP BY 
  customer_key
ORDER BY 
  total_sales DESC
LIMIT 10;

-- ── AI Generated: silver_v2_px_cat_g1v2 ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_px_cat_g1v2_summary AS
SELECT 
  COUNT(ID) AS total_count,
  COUNT(DISTINCT CAT) AS category_count,
  COUNT(DISTINCT SUBCAT) AS subcategory_count,
  SUM(CASE WHEN MAINTENANCE = 'Yes' THEN 1 ELSE 0 END) AS maintenance_yes_count,
  SUM(CASE WHEN MAINTENANCE = 'No' THEN 1 ELSE 0 END) AS maintenance_no_count
FROM 
  dataingestionproject.silver.silver_v2_px_cat_g1v2;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_px_cat_g1v2_by_category AS
SELECT 
  CAT,
  COUNT(ID) AS count,
  COUNT(DISTINCT SUBCAT) AS subcategory_count,
  SUM(CASE WHEN MAINTENANCE = 'Yes' THEN 1 ELSE 0 END) AS maintenance_yes_count,
  SUM(CASE WHEN MAINTENANCE = 'No' THEN 1 ELSE 0 END) AS maintenance_no_count
FROM 
  dataingestionproject.silver.silver_v2_px_cat_g1v2
GROUP BY 
  CAT
ORDER BY 
  count DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_px_cat_g1v2_top_subcategories AS
SELECT 
  SUBCAT,
  COUNT(ID) AS count,
  SUM(CASE WHEN MAINTENANCE = 'Yes' THEN 1 ELSE 0 END) AS maintenance_yes_count,
  SUM(CASE WHEN MAINTENANCE = 'No' THEN 1 ELSE 0 END) AS maintenance_no_count
FROM 
  dataingestionproject.silver.silver_v2_px_cat_g1v2
GROUP BY 
  SUBCAT
ORDER BY 
  count DESC
LIMIT 10;

-- ── AI Generated: silver_v2_student_performance_dataset ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_student_performance_dataset_summary AS
SELECT 
  COUNT(*) AS total_students,
  AVG(study_time_hours) AS avg_study_time_hours,
  AVG(attendance_percent) AS avg_attendance_percent,
  AVG(sleep_hours) AS avg_sleep_hours,
  AVG(previous_grade) AS avg_previous_grade,
  AVG(final_exam_score) AS avg_final_exam_score
FROM dataingestionproject.silver.silver_v2_student_performance_dataset;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_student_performance_dataset_by_gender AS
SELECT 
  gender,
  COUNT(*) AS total_students,
  AVG(study_time_hours) AS avg_study_time_hours,
  AVG(attendance_percent) AS avg_attendance_percent,
  AVG(sleep_hours) AS avg_sleep_hours,
  AVG(previous_grade) AS avg_previous_grade,
  AVG(final_exam_score) AS avg_final_exam_score
FROM dataingestionproject.silver.silver_v2_student_performance_dataset
GROUP BY gender
ORDER BY total_students DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_top_5_student_performance_dataset_by_final_grade AS
SELECT 
  final_grade,
  AVG(study_time_hours) AS avg_study_time_hours,
  AVG(attendance_percent) AS avg_attendance_percent,
  AVG(sleep_hours) AS avg_sleep_hours,
  AVG(previous_grade) AS avg_previous_grade,
  AVG(final_exam_score) AS avg_final_exam_score,
  COUNT(*) AS total_students,
  RANK() OVER (ORDER BY AVG(final_exam_score) DESC) AS rank
FROM dataingestionproject.silver.silver_v2_student_performance_dataset
GROUP BY final_grade
ORDER BY rank
LIMIT 5;

CREATE OR REFRESH MATERIALIZED VIEW `dataingestionproject`.`gold`.`gold_monthly_sales` AS
SELECT
  YEAR(order_date)  AS year,
  MONTH(order_date) AS month,
  CONCAT(YEAR(order_date), '-', LPAD(MONTH(order_date), 2, '0')) AS year_month,
  COUNT(DISTINCT order_number) AS orders_count,
  COUNT(*) AS line_items_count,
  SUM(quantity) AS total_quantity,
  SUM(sales_amount) AS total_sales,
  ROUND(AVG(sales_amount), 2) AS avg_line_value,
  COUNT(DISTINCT customer_key) AS unique_customers,
  COUNT(DISTINCT product_key) AS unique_products
FROM dataingestionproject.silver.silver_v2_fact_sales
GROUP BY YEAR(order_date), MONTH(order_date);

-- ── AI Generated: silver_v2_fifa_world_cup_2026_player_performance ───────────────────────────────────
CREATE OR REFRESH MATERIALIZED VIEW gold_fifa_world_cup_2026_player_performance_summary AS
SELECT 
  COUNT(player_id) AS total_players,
  SUM(goals) AS total_goals,
  SUM(assists) AS total_assists,
  AVG(player_rating) AS average_player_rating,
  AVG(performance_score) AS average_performance_score
FROM 
  dataingestionproject.silver.silver_v2_fifa_world_cup_2026_player_performance;

CREATE OR REFRESH MATERIALIZED VIEW gold_fifa_world_cup_2026_player_performance_by_position AS
SELECT 
  position,
  COUNT(player_id) AS total_players,
  SUM(goals) AS total_goals,
  SUM(assists) AS total_assists,
  AVG(player_rating) AS average_player_rating,
  AVG(performance_score) AS average_performance_score
FROM 
  dataingestionproject.silver.silver_v2_fifa_world_cup_2026_player_performance
GROUP BY 
  position
ORDER BY 
  total_players DESC;

CREATE OR REFRESH MATERIALIZED VIEW gold_fifa_world_cup_2026_player_performance_by_match_date AS
SELECT 
  match_date,
  SUM(goals) AS total_goals,
  SUM(assists) AS total_assists,
  AVG(player_rating) AS average_player_rating,
  AVG(performance_score) AS average_performance_score
FROM 
  dataingestionproject.silver.silver_v2_fifa_world_cup_2026_player_performance
GROUP BY 
  match_date
ORDER BY 
  match_date;

CREATE OR REFRESH MATERIALIZED VIEW gold_fifa_world_cup_2026_top_players_by_performance_score AS
SELECT 
  player_id,
  player_name,
  performance_score,
  player_rating,
  ROW_NUMBER() OVER (ORDER BY performance_score DESC) AS rank
FROM 
  dataingestionproject.silver.silver_v2_fifa_world_cup_2026_player_performance
ORDER BY 
  performance_score DESC;

-- ── AI Generated: silver_v2_fifa_world_cup_2026_player_performance ───────────────────────────────────
CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.fifa_world_cup_2026_player_performance_summary AS
SELECT 
    COUNT(*) AS total_matches,
    SUM(goals) AS total_goals,
    SUM(assists) AS total_assists,
    AVG(player_rating) AS average_player_rating,
    AVG(performance_score) AS average_performance_score
FROM dataingestionproject.silver.silver_v2_fifa_world_cup_2026_player_performance;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.fifa_world_cup_2026_player_performance_by_team AS
SELECT 
    team,
    COUNT(*) AS total_matches,
    SUM(goals) AS total_goals,
    SUM(assists) AS total_assists,
    AVG(player_rating) AS average_player_rating,
    AVG(performance_score) AS average_performance_score
FROM dataingestionproject.silver.silver_v2_fifa_world_cup_2026_player_performance
GROUP BY team
ORDER BY total_matches DESC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.fifa_world_cup_2026_player_performance_time_series AS
SELECT 
    match_date,
    COUNT(*) AS total_matches,
    SUM(goals) AS total_goals,
    SUM(assists) AS total_assists,
    AVG(player_rating) AS average_player_rating,
    AVG(performance_score) AS average_performance_score
FROM dataingestionproject.silver.silver_v2_fifa_world_cup_2026_player_performance
GROUP BY match_date
ORDER BY match_date ASC;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.fifa_world_cup_2026_top_performers AS
SELECT 
    player_name,
    team,
    SUM(goals) AS total_goals,
    SUM(assists) AS total_assists,
    AVG(player_rating) AS average_player_rating,
    AVG(performance_score) AS average_performance_score,
    RANK() OVER (ORDER BY AVG(performance_score) DESC) AS performance_rank
FROM dataingestionproject.silver.silver_v2_fifa_world_cup_2026_player_performance
GROUP BY player_name, team
ORDER BY performance_rank ASC
LIMIT 10;

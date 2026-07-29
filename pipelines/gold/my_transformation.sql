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

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.automobile_dataset_summary AS
SELECT 
  COUNT(*) AS total_vehicles,
  SUM(Selling_Price) AS total_revenue,
  AVG(Selling_Price) AS average_selling_price,
  AVG(Mileage) AS average_mileage,
  AVG(Horsepower) AS average_horsepower,
  AVG(Fuel_Efficiency) AS average_fuel_efficiency
FROM dataingestionproject.silver.silver_v2_automobile_dataset;

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_fact_sales_summary AS
SELECT 
  COUNT(order_number) AS total_orders,
  SUM(sales_amount) AS total_sales,
  AVG(sales_amount) AS average_sales
FROM 
  dataingestionproject.silver.silver_v2_fact_sales;

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

-- ── AI Generated: silver_v2_meets ───────────────────────────────────

CREATE OR REFRESH MATERIALIZED VIEW dataingestionproject.gold.gold_meets_summary AS
SELECT 
  COUNT(MeetID) AS total_meets,
  COUNT(DISTINCT Federation) AS total_federations,
  COUNT(DISTINCT MeetCountry) AS total_countries,
  COUNT(DISTINCT MeetState) AS total_states,
  COUNT(DISTINCT MeetTown) AS total_towns
FROM 
  dataingestionproject.silver.silver_v2_meets;

;
;

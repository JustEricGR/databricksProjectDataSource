// Pre-defined analytics queries for every silver table.
// Each entry: { title, sql, chartType, xKey, yKey, description }
// chartType: 'bar' | 'line' | 'pie' | 'area' | 'table' | 'kpi'

const C = 'dataingestionproject.silver'

export const SILVER_QUERIES = {
  silver_v2_dim_customers: [
    {
      title: 'Customers by Country',
      description: 'Number of customers per country',
      chartType: 'bar', xKey: 'country', yKey: 'customer_count',
      sql: `SELECT country, COUNT(*) AS customer_count FROM ${C}.silver_v2_dim_customers GROUP BY country ORDER BY customer_count DESC LIMIT 20`
    },
    {
      title: 'Gender Distribution',
      chartType: 'pie', xKey: 'gender', yKey: 'count',
      sql: `SELECT gender, COUNT(*) AS count FROM ${C}.silver_v2_dim_customers GROUP BY gender`
    },
    {
      title: 'Marital Status Breakdown',
      chartType: 'bar', xKey: 'marital_status', yKey: 'count',
      sql: `SELECT marital_status, COUNT(*) AS count FROM ${C}.silver_v2_dim_customers GROUP BY marital_status ORDER BY count DESC`
    }
  ],
  silver_v2_fact_sales: [
    {
      title: 'Monthly Revenue',
      description: 'Total sales amount by month',
      chartType: 'area', xKey: 'month', yKey: 'total_sales',
      sql: `SELECT CONCAT(YEAR(order_date),'-',LPAD(MONTH(order_date),2,'0')) AS month, ROUND(SUM(sales_amount),0) AS total_sales FROM ${C}.silver_v2_fact_sales GROUP BY YEAR(order_date), MONTH(order_date) ORDER BY YEAR(order_date), MONTH(order_date)`
    },
    {
      title: 'Top 10 Products by Revenue',
      chartType: 'bar', xKey: 'product_key', yKey: 'revenue',
      sql: `SELECT CAST(product_key AS STRING) AS product_key, ROUND(SUM(sales_amount),0) AS revenue FROM ${C}.silver_v2_fact_sales GROUP BY product_key ORDER BY revenue DESC LIMIT 10`
    },
    {
      title: 'Orders per Month',
      chartType: 'line', xKey: 'month', yKey: 'orders',
      sql: `SELECT CONCAT(YEAR(order_date),'-',LPAD(MONTH(order_date),2,'0')) AS month, COUNT(DISTINCT order_number) AS orders FROM ${C}.silver_v2_fact_sales GROUP BY YEAR(order_date), MONTH(order_date) ORDER BY YEAR(order_date), MONTH(order_date)`
    }
  ],
  silver_v2_dim_products: [
    {
      title: 'Products by Category',
      chartType: 'bar', xKey: 'category', yKey: 'count',
      sql: `SELECT category, COUNT(*) AS count FROM ${C}.silver_v2_dim_products GROUP BY category ORDER BY count DESC`
    },
    {
      title: 'Products by Subcategory',
      chartType: 'bar', xKey: 'subcategory', yKey: 'count',
      sql: `SELECT subcategory, COUNT(*) AS count FROM ${C}.silver_v2_dim_products GROUP BY subcategory ORDER BY count DESC LIMIT 15`
    },
    {
      title: 'Average Cost by Category',
      chartType: 'bar', xKey: 'category', yKey: 'avg_cost',
      sql: `SELECT category, ROUND(AVG(cost),2) AS avg_cost FROM ${C}.silver_v2_dim_products GROUP BY category ORDER BY avg_cost DESC`
    }
  ],
  silver_v2_cust_info: [
    {
      title: 'Gender Split',
      chartType: 'pie', xKey: 'cst_gender', yKey: 'count',
      sql: `SELECT cst_gender, COUNT(*) AS count FROM ${C}.silver_v2_cust_info GROUP BY cst_gender`
    },
    {
      title: 'Marital Status',
      chartType: 'bar', xKey: 'cst_marital_status', yKey: 'count',
      sql: `SELECT cst_marital_status, COUNT(*) AS count FROM ${C}.silver_v2_cust_info GROUP BY cst_marital_status ORDER BY count DESC`
    }
  ],
  silver_v2_cust_az12: [
    {
      title: 'Customer AZ12 Overview',
      chartType: 'kpi',
      sql: `SELECT COUNT(*) AS total_records, COUNT(DISTINCT cst_key) AS unique_customers FROM ${C}.silver_v2_cust_az12`
    },
    {
      title: 'Sample Records',
      chartType: 'table',
      sql: `SELECT * FROM ${C}.silver_v2_cust_az12 LIMIT 20`
    }
  ],
  silver_v2_loc_a101: [
    {
      title: 'Locations by Country',
      chartType: 'bar', xKey: 'country', yKey: 'count',
      sql: `SELECT country, COUNT(*) AS count FROM ${C}.silver_v2_loc_a101 GROUP BY country ORDER BY count DESC LIMIT 20`
    }
  ],
  silver_v2_prd_info: [
    {
      title: 'Products by Line',
      chartType: 'bar', xKey: 'product_line', yKey: 'count',
      sql: `SELECT product_line, COUNT(*) AS count FROM ${C}.silver_v2_prd_info GROUP BY product_line ORDER BY count DESC`
    },
    {
      title: 'Products by Category',
      chartType: 'bar', xKey: 'cat', yKey: 'count',
      sql: `SELECT COALESCE(cat, 'Unknown') AS cat, COUNT(*) AS count FROM ${C}.silver_v2_prd_info GROUP BY cat ORDER BY count DESC LIMIT 15`
    }
  ],
  silver_v2_px_cat_g1v2: [
    {
      title: 'Category Hierarchy',
      chartType: 'table',
      sql: `SELECT * FROM ${C}.silver_v2_px_cat_g1v2 LIMIT 50`
    }
  ],
  silver_v2_sales_details: [
    {
      title: 'Top Products by Sales',
      chartType: 'bar', xKey: 'product_key', yKey: 'total',
      sql: `SELECT CAST(product_key AS STRING) AS product_key, ROUND(SUM(unit_price * order_quantity),0) AS total FROM ${C}.silver_v2_sales_details GROUP BY product_key ORDER BY total DESC LIMIT 15`
    },
    {
      title: 'Order Quantity Distribution',
      chartType: 'bar', xKey: 'order_quantity', yKey: 'count',
      sql: `SELECT CAST(order_quantity AS STRING) AS order_quantity, COUNT(*) AS count FROM ${C}.silver_v2_sales_details GROUP BY order_quantity ORDER BY CAST(order_quantity AS INT)`
    }
  ],
  silver_v2_annual_enterprise_survey_2025_financial_year_provisional: [
    {
      title: 'Survey Value by Industry',
      chartType: 'bar', xKey: 'industry_name_anzsic06', yKey: 'total_value',
      sql: `SELECT industry_name_anzsic06, ROUND(SUM(CAST(value AS DOUBLE)),0) AS total_value FROM ${C}.silver_v2_annual_enterprise_survey_2025_financial_year_provisional WHERE value IS NOT NULL GROUP BY industry_name_anzsic06 ORDER BY total_value DESC LIMIT 15`
    }
  ],
  silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands: [
    {
      title: 'Value by Size Band',
      chartType: 'bar', xKey: 'rme_size_grp', yKey: 'total',
      sql: `SELECT rme_size_grp, ROUND(SUM(CAST(value AS DOUBLE)),0) AS total FROM ${C}.silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands WHERE value IS NOT NULL GROUP BY rme_size_grp ORDER BY total DESC`
    }
  ],
  silver_v2_business_operations_survey_2022_business_finance: [
    {
      title: 'Finance Survey by Industry',
      chartType: 'bar', xKey: 'industry', yKey: 'count',
      sql: `SELECT industry, COUNT(*) AS count FROM ${C}.silver_v2_business_operations_survey_2022_business_finance GROUP BY industry ORDER BY count DESC LIMIT 15`
    }
  ],
  silver_v2_business_operations_survey_2023_business_practices: [
    {
      title: 'Practices Survey by Industry',
      chartType: 'bar', xKey: 'industry', yKey: 'count',
      sql: `SELECT industry, COUNT(*) AS count FROM ${C}.silver_v2_business_operations_survey_2023_business_practices GROUP BY industry ORDER BY count DESC LIMIT 15`
    }
  ],
  silver_v2_business_operations_survey_2023_climate_change: [
    {
      title: 'Climate Survey by Industry',
      chartType: 'bar', xKey: 'industry', yKey: 'count',
      sql: `SELECT industry, COUNT(*) AS count FROM ${C}.silver_v2_business_operations_survey_2023_climate_change GROUP BY industry ORDER BY count DESC LIMIT 15`
    }
  ],
  silver_v2_student_performance_dataset: [
    {
      title: 'Performance by Gender',
      chartType: 'bar', xKey: 'gender', yKey: 'avg_score',
      sql: `SELECT gender, ROUND(AVG(CAST(final_exam_score AS DOUBLE)),2) AS avg_score FROM ${C}.silver_v2_student_performance_dataset GROUP BY gender`
    },
    {
      title: 'Score Distribution',
      chartType: 'bar', xKey: 'score_range', yKey: 'students',
      sql: `SELECT CASE WHEN CAST(final_exam_score AS INT) < 50 THEN 'Below 50' WHEN CAST(final_exam_score AS INT) < 70 THEN '50-69' WHEN CAST(final_exam_score AS INT) < 85 THEN '70-84' ELSE '85+' END AS score_range, COUNT(*) AS students FROM ${C}.silver_v2_student_performance_dataset GROUP BY score_range ORDER BY score_range`
    }
  ],
  silver_v2_automobile_dataset: [
    {
      title: 'Cars by Make',
      chartType: 'bar', xKey: 'make', yKey: 'count',
      sql: `SELECT make, COUNT(*) AS count FROM ${C}.silver_v2_automobile_dataset GROUP BY make ORDER BY count DESC LIMIT 15`
    },
    {
      title: 'Average Price by Make',
      chartType: 'bar', xKey: 'make', yKey: 'avg_price',
      sql: `SELECT make, ROUND(AVG(CAST(price AS DOUBLE)),0) AS avg_price FROM ${C}.silver_v2_automobile_dataset WHERE price IS NOT NULL GROUP BY make ORDER BY avg_price DESC LIMIT 15`
    }
  ],
  silver_v2_meets: [
    {
      title: 'Meets Overview',
      chartType: 'table',
      sql: `SELECT * FROM ${C}.silver_v2_meets LIMIT 50`
    }
  ]
}

// Auto-generate a simple bar chart for any table not in the map
export function autoQuery(tableName, columns) {
  const strCol = columns.find(c => c.type === 'string')
  const numCol = columns.find(c => ['int','bigint','double','float','decimal','long'].some(t => c.type?.includes(t)))
  if (strCol && numCol) {
    return [{
      title: `${tableName.replace('silver_v2_','').replace(/_/g,' ')} Breakdown`,
      chartType: 'bar', xKey: strCol.name, yKey: 'metric',
      sql: `SELECT ${strCol.name}, SUM(${numCol.name}) AS metric FROM dataingestionproject.silver.${tableName} GROUP BY ${strCol.name} ORDER BY metric DESC LIMIT 20`
    }]
  }
  return [{
    title: 'Sample Data',
    chartType: 'table',
    sql: `SELECT * FROM dataingestionproject.silver.${tableName} LIMIT 50`
  }]
}

export const DOMAIN_MAP = {
  'Customer Analytics':  ['silver_v2_dim_customers', 'silver_v2_cust_info', 'silver_v2_cust_az12', 'silver_v2_loc_a101'],
  'Product Analytics':   ['silver_v2_dim_products', 'silver_v2_prd_info', 'silver_v2_px_cat_g1v2'],
  'Sales Analytics':     ['silver_v2_fact_sales', 'silver_v2_sales_details'],
  'Survey Analytics':    ['silver_v2_annual_enterprise_survey_2025_financial_year_provisional',
                          'silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands',
                          'silver_v2_business_operations_survey_2022_business_finance',
                          'silver_v2_business_operations_survey_2023_business_practices',
                          'silver_v2_business_operations_survey_2023_climate_change'],
  'Other Datasets':      ['silver_v2_student_performance_dataset', 'silver_v2_automobile_dataset', 'silver_v2_meets'],
}

const C = 'dataingestionproject.silver'

export const SILVER_QUERIES = {

  // ── Customers ──────────────────────────────────────────────────────────────
  silver_v2_dim_customers: [
    {
      title: 'Customers by Country',
      description: 'How many customers per country',
      chartType: 'bar', xKey: 'country', yKey: 'customers',
      sql: `SELECT country, COUNT(*) AS customers FROM ${C}.silver_v2_dim_customers GROUP BY country ORDER BY customers DESC LIMIT 15`
    },
    {
      title: 'Gender Split',
      chartType: 'pie', xKey: 'gender', yKey: 'count',
      sql: `SELECT gender, COUNT(*) AS count FROM ${C}.silver_v2_dim_customers GROUP BY gender`
    },
    {
      title: 'Marital Status',
      chartType: 'bar', xKey: 'marital_status', yKey: 'count',
      sql: `SELECT marital_status, COUNT(*) AS count FROM ${C}.silver_v2_dim_customers GROUP BY marital_status`
    }
  ],

  silver_v2_cust_info: [
    {
      title: 'Gender Distribution',
      chartType: 'pie', xKey: 'cst_gender', yKey: 'count',
      sql: `SELECT cst_gender, COUNT(*) AS count FROM ${C}.silver_v2_cust_info GROUP BY cst_gender`
    },
    {
      title: 'Marital Status Breakdown',
      chartType: 'bar', xKey: 'cst_marital_status', yKey: 'count',
      sql: `SELECT cst_marital_status, COUNT(*) AS count FROM ${C}.silver_v2_cust_info GROUP BY cst_marital_status`
    }
  ],

  silver_v2_cust_az12: [
    {
      title: 'Gender Distribution',
      chartType: 'pie', xKey: 'GEN', yKey: 'count',
      sql: `SELECT CASE WHEN GEN='M' THEN 'Male' WHEN GEN='F' THEN 'Female' ELSE GEN END AS GEN, COUNT(*) AS count FROM ${C}.silver_v2_cust_az12 GROUP BY GEN`
    },
    {
      title: 'Customer AZ12 Sample',
      chartType: 'table',
      sql: `SELECT CID AS customer_id, BDATE AS birth_date, GEN AS gender FROM ${C}.silver_v2_cust_az12 LIMIT 20`
    }
  ],

  silver_v2_loc_a101: [
    {
      title: 'Locations by Country',
      chartType: 'bar', xKey: 'CNTRY', yKey: 'count',
      sql: `SELECT CNTRY AS country, COUNT(*) AS count FROM ${C}.silver_v2_loc_a101 GROUP BY CNTRY ORDER BY count DESC LIMIT 20`
    }
  ],

  // ── Products ───────────────────────────────────────────────────────────────
  silver_v2_dim_products: [
    {
      title: 'Products by Category',
      chartType: 'bar', xKey: 'category', yKey: 'count',
      sql: `SELECT category, COUNT(*) AS count FROM ${C}.silver_v2_dim_products GROUP BY category ORDER BY count DESC`
    },
    {
      title: 'Average Cost by Category',
      chartType: 'bar', xKey: 'category', yKey: 'avg_cost',
      sql: `SELECT category, ROUND(AVG(cost),0) AS avg_cost FROM ${C}.silver_v2_dim_products GROUP BY category ORDER BY avg_cost DESC`
    },
    {
      title: 'Products by Subcategory',
      chartType: 'bar', xKey: 'subcategory', yKey: 'count',
      sql: `SELECT subcategory, COUNT(*) AS count FROM ${C}.silver_v2_dim_products GROUP BY subcategory ORDER BY count DESC LIMIT 15`
    }
  ],

  silver_v2_prd_info: [
    {
      title: 'Products by Line',
      chartType: 'bar', xKey: 'prd_line', yKey: 'count',
      sql: `SELECT prd_line AS product_line, COUNT(*) AS count FROM ${C}.silver_v2_prd_info GROUP BY prd_line ORDER BY count DESC`
    },
    {
      title: 'Average Cost by Product Line',
      chartType: 'bar', xKey: 'prd_line', yKey: 'avg_cost',
      sql: `SELECT prd_line AS product_line, ROUND(AVG(prd_cost),0) AS avg_cost FROM ${C}.silver_v2_prd_info WHERE prd_cost IS NOT NULL GROUP BY prd_line ORDER BY avg_cost DESC`
    }
  ],

  silver_v2_px_cat_g1v2: [
    {
      title: 'Products by Category',
      chartType: 'bar', xKey: 'CAT', yKey: 'count',
      sql: `SELECT CAT AS category, COUNT(*) AS count FROM ${C}.silver_v2_px_cat_g1v2 GROUP BY CAT ORDER BY count DESC`
    },
    {
      title: 'Products by Subcategory',
      chartType: 'bar', xKey: 'SUBCAT', yKey: 'count',
      sql: `SELECT SUBCAT AS subcategory, COUNT(*) AS count FROM ${C}.silver_v2_px_cat_g1v2 GROUP BY SUBCAT ORDER BY count DESC LIMIT 15`
    }
  ],

  // ── Sales ──────────────────────────────────────────────────────────────────
  silver_v2_fact_sales: [
    {
      title: 'Monthly Revenue Trend',
      description: 'Total sales by month',
      chartType: 'area', xKey: 'month', yKey: 'revenue',
      sql: `SELECT CONCAT(SUBSTRING(order_date,7,4),'-',SUBSTRING(order_date,4,2)) AS month, SUM(sales_amount) AS revenue FROM ${C}.silver_v2_fact_sales GROUP BY SUBSTRING(order_date,7,4), SUBSTRING(order_date,4,2) ORDER BY SUBSTRING(order_date,7,4), SUBSTRING(order_date,4,2)`
    },
    {
      title: 'Top 15 Products by Revenue',
      description: 'Product names joined from dim_products',
      chartType: 'bar', xKey: 'product_name', yKey: 'revenue',
      sql: `SELECT p.product_name, SUM(f.sales_amount) AS revenue FROM ${C}.silver_v2_fact_sales f JOIN ${C}.silver_v2_dim_products p ON f.product_key = p.product_key GROUP BY p.product_name ORDER BY revenue DESC LIMIT 15`
    },
    {
      title: 'Top 10 Customers by Revenue',
      chartType: 'bar', xKey: 'customer_name', yKey: 'revenue',
      sql: `SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name, SUM(f.sales_amount) AS revenue FROM ${C}.silver_v2_fact_sales f JOIN ${C}.silver_v2_dim_customers c ON f.customer_key = c.customer_key GROUP BY c.first_name, c.last_name ORDER BY revenue DESC LIMIT 10`
    }
  ],

  silver_v2_sales_details: [
    {
      title: 'Top 15 Products by Revenue',
      chartType: 'bar', xKey: 'product_name', yKey: 'revenue',
      sql: `SELECT p.product_name, ROUND(SUM(s.sls_sales),0) AS revenue FROM ${C}.silver_v2_sales_details s JOIN ${C}.silver_v2_dim_products p ON s.sls_prd_key = p.product_number GROUP BY p.product_name ORDER BY revenue DESC LIMIT 15`
    },
    {
      title: 'Total Quantity Sold by Product',
      chartType: 'bar', xKey: 'product_name', yKey: 'qty_sold',
      sql: `SELECT p.product_name, SUM(s.sls_quantity) AS qty_sold FROM ${C}.silver_v2_sales_details s JOIN ${C}.silver_v2_dim_products p ON s.sls_prd_key = p.product_number GROUP BY p.product_name ORDER BY qty_sold DESC LIMIT 15`
    }
  ],

  // ── FIFA World Cup ─────────────────────────────────────────────────────────
  silver_v2_fifa_world_cup_2026_player_performance: [
    {
      title: 'Top 15 Scorers',
      chartType: 'bar', xKey: 'player_name', yKey: 'total_goals',
      sql: `SELECT player_name, SUM(goals) AS total_goals FROM ${C}.silver_v2_fifa_world_cup_2026_player_performance GROUP BY player_name ORDER BY total_goals DESC LIMIT 15`
    },
    {
      title: 'Goals by Nationality',
      chartType: 'bar', xKey: 'nationality', yKey: 'goals',
      sql: `SELECT nationality, SUM(goals) AS goals FROM ${C}.silver_v2_fifa_world_cup_2026_player_performance GROUP BY nationality ORDER BY goals DESC LIMIT 15`
    },
    {
      title: 'Top Assist Providers',
      chartType: 'bar', xKey: 'player_name', yKey: 'total_assists',
      sql: `SELECT player_name, SUM(assists) AS total_assists FROM ${C}.silver_v2_fifa_world_cup_2026_player_performance GROUP BY player_name ORDER BY total_assists DESC LIMIT 12`
    },
    {
      title: 'Average Player Rating by Position',
      chartType: 'bar', xKey: 'position', yKey: 'avg_rating',
      sql: `SELECT position, ROUND(AVG(player_rating),2) AS avg_rating FROM ${C}.silver_v2_fifa_world_cup_2026_player_performance GROUP BY position ORDER BY avg_rating DESC`
    }
  ],

  // ── Meets (Powerlifting) ───────────────────────────────────────────────────
  silver_v2_meets: [
    {
      title: 'Meets by Federation',
      chartType: 'bar', xKey: 'Federation', yKey: 'meets',
      sql: `SELECT Federation, COUNT(*) AS meets FROM ${C}.silver_v2_meets GROUP BY Federation ORDER BY meets DESC LIMIT 15`
    },
    {
      title: 'Meets by Country',
      chartType: 'bar', xKey: 'MeetCountry', yKey: 'meets',
      sql: `SELECT MeetCountry, COUNT(*) AS meets FROM ${C}.silver_v2_meets GROUP BY MeetCountry ORDER BY meets DESC LIMIT 15`
    }
  ],

  // ── Student Performance ────────────────────────────────────────────────────
  silver_v2_student_performance_dataset: [
    {
      title: 'Average Score by Gender',
      chartType: 'bar', xKey: 'gender', yKey: 'avg_score',
      sql: `SELECT gender, ROUND(AVG(final_exam_score),2) AS avg_score FROM ${C}.silver_v2_student_performance_dataset GROUP BY gender`
    },
    {
      title: 'Score by Parental Education',
      chartType: 'bar', xKey: 'parental_education', yKey: 'avg_score',
      sql: `SELECT parental_education, ROUND(AVG(final_exam_score),2) AS avg_score FROM ${C}.silver_v2_student_performance_dataset GROUP BY parental_education ORDER BY avg_score DESC`
    },
    {
      title: 'Grade Distribution',
      chartType: 'pie', xKey: 'final_grade', yKey: 'count',
      sql: `SELECT final_grade, COUNT(*) AS count FROM ${C}.silver_v2_student_performance_dataset GROUP BY final_grade ORDER BY final_grade`
    },
    {
      title: 'Impact of Internet Access on Score',
      chartType: 'bar', xKey: 'internet_access', yKey: 'avg_score',
      sql: `SELECT internet_access, ROUND(AVG(final_exam_score),2) AS avg_score FROM ${C}.silver_v2_student_performance_dataset GROUP BY internet_access`
    }
  ],

  // ── Automobiles ────────────────────────────────────────────────────────────
  silver_v2_automobile_dataset: [
    {
      title: 'Average Selling Price by Make',
      description: 'Which brands command the highest prices?',
      chartType: 'bar', xKey: 'Make', yKey: 'avg_price',
      sql: `SELECT Make, ROUND(AVG(Selling_Price),0) AS avg_price FROM ${C}.silver_v2_automobile_dataset GROUP BY Make ORDER BY avg_price DESC LIMIT 15`
    },
    {
      title: 'Cars by Body Type',
      chartType: 'pie', xKey: 'Body_Type', yKey: 'count',
      sql: `SELECT Body_Type, COUNT(*) AS count FROM ${C}.silver_v2_automobile_dataset GROUP BY Body_Type ORDER BY count DESC`
    },
    {
      title: 'Average Horsepower by Make',
      description: 'Most powerful brands on average',
      chartType: 'bar', xKey: 'Make', yKey: 'avg_hp',
      sql: `SELECT Make, ROUND(AVG(Horsepower),0) AS avg_hp FROM ${C}.silver_v2_automobile_dataset WHERE Horsepower IS NOT NULL GROUP BY Make ORDER BY avg_hp DESC LIMIT 15`
    },
    {
      title: 'Cars by Fuel Type',
      chartType: 'pie', xKey: 'Fuel_Type', yKey: 'count',
      sql: `SELECT Fuel_Type, COUNT(*) AS count FROM ${C}.silver_v2_automobile_dataset GROUP BY Fuel_Type ORDER BY count DESC`
    }
  ],

  // ── Enterprise Surveys ─────────────────────────────────────────────────────
  silver_v2_annual_enterprise_survey_2025_financial_year_provisional: [
    {
      title: 'Total Reported Value by Industry',
      description: 'NZ enterprise survey — only numeric responses included (suppressed codes excluded)',
      chartType: 'bar', xKey: 'Industry_name_NZSIOC', yKey: 'total_value',
      sql: `SELECT Industry_name_NZSIOC, ROUND(SUM(TRY_CAST(Value AS DOUBLE)),0) AS total_value FROM ${C}.silver_v2_annual_enterprise_survey_2025_financial_year_provisional WHERE TRY_CAST(Value AS DOUBLE) IS NOT NULL GROUP BY Industry_name_NZSIOC ORDER BY total_value DESC LIMIT 15`
    },
    {
      title: 'Records by Variable Category',
      description: 'What types of metrics are measured in this survey?',
      chartType: 'bar', xKey: 'Variable_category', yKey: 'count',
      sql: `SELECT Variable_category, COUNT(*) AS count FROM ${C}.silver_v2_annual_enterprise_survey_2025_financial_year_provisional GROUP BY Variable_category ORDER BY count DESC`
    }
  ],

  silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands: [
    {
      title: 'Total Value by Enterprise Size Band',
      description: 'Small vs large enterprise comparison (suppressed codes excluded)',
      chartType: 'bar', xKey: 'rme_size_grp', yKey: 'total',
      sql: `SELECT rme_size_grp AS size_band, ROUND(SUM(TRY_CAST(value AS DOUBLE)),0) AS total FROM ${C}.silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands WHERE TRY_CAST(value AS DOUBLE) IS NOT NULL GROUP BY rme_size_grp ORDER BY total DESC`
    },
    {
      title: 'Top Industries by Report Coverage',
      chartType: 'bar', xKey: 'industry_name_ANZSIC', yKey: 'count',
      sql: `SELECT industry_name_ANZSIC AS industry, COUNT(*) AS count FROM ${C}.silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands GROUP BY industry_name_ANZSIC ORDER BY count DESC LIMIT 12`
    }
  ],

  silver_v2_business_operations_survey_2022_business_finance: [
    {
      title: 'Total Value by Industry',
      chartType: 'bar', xKey: 'industry', yKey: 'total_value',
      sql: `SELECT industry, SUM(value) AS total_value FROM ${C}.silver_v2_business_operations_survey_2022_business_finance GROUP BY industry ORDER BY total_value DESC LIMIT 15`
    },
    {
      title: 'Average Value by Size Band',
      chartType: 'bar', xKey: 'size', yKey: 'avg_value',
      sql: `SELECT size, ROUND(AVG(value),0) AS avg_value FROM ${C}.silver_v2_business_operations_survey_2022_business_finance GROUP BY size ORDER BY avg_value DESC`
    }
  ],

  silver_v2_business_operations_survey_2023_business_practices: [
    {
      title: 'Value by Industry',
      chartType: 'bar', xKey: 'industry', yKey: 'total_value',
      sql: `SELECT industry, SUM(value) AS total_value FROM ${C}.silver_v2_business_operations_survey_2023_business_practices GROUP BY industry ORDER BY total_value DESC LIMIT 15`
    },
    {
      title: 'Records by Size Band',
      chartType: 'bar', xKey: 'size', yKey: 'count',
      sql: `SELECT size, COUNT(*) AS count FROM ${C}.silver_v2_business_operations_survey_2023_business_practices GROUP BY size ORDER BY count DESC`
    }
  ],

  silver_v2_business_operations_survey_2023_climate_change: [
    {
      title: 'Climate Change Value by Industry',
      chartType: 'bar', xKey: 'industry', yKey: 'total_value',
      sql: `SELECT industry, SUM(value) AS total_value FROM ${C}.silver_v2_business_operations_survey_2023_climate_change GROUP BY industry ORDER BY total_value DESC LIMIT 15`
    },
    {
      title: 'Records by Size Band',
      chartType: 'bar', xKey: 'size', yKey: 'count',
      sql: `SELECT size, COUNT(*) AS count FROM ${C}.silver_v2_business_operations_survey_2023_climate_change GROUP BY size ORDER BY count DESC`
    }
  ],
}

// Auto-generate for any table not in the map above
export function autoQuery(tableName, columns) {
  const strCol = columns.find(c => c.type === 'string')
  const numCol = columns.find(c =>
    ['int','bigint','double','float','decimal','long'].some(t => c.type?.includes(t))
  )
  if (strCol && numCol) {
    return [{
      title: tableName.replace('silver_v2_', '').replace(/_/g, ' '),
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
  'Customer Analytics': ['silver_v2_dim_customers','silver_v2_cust_info','silver_v2_cust_az12','silver_v2_loc_a101'],
  'Product Analytics':  ['silver_v2_dim_products','silver_v2_prd_info','silver_v2_px_cat_g1v2'],
  'Sales Analytics':    ['silver_v2_fact_sales','silver_v2_sales_details'],
  'Survey Analytics':   [
    'silver_v2_annual_enterprise_survey_2025_financial_year_provisional',
    'silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands',
    'silver_v2_business_operations_survey_2022_business_finance',
    'silver_v2_business_operations_survey_2023_business_practices',
    'silver_v2_business_operations_survey_2023_climate_change',
  ],
  'Other Datasets':     ['silver_v2_student_performance_dataset','silver_v2_automobile_dataset',
                         'silver_v2_fifa_world_cup_2026_player_performance','silver_v2_meets'],
}

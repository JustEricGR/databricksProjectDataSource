# Databricks notebook source
from pyspark import pipelines as dp
from pyspark.sql import functions as F
from pyspark.sql.types import StringType

# COMMAND ----------

# COMMAND ----------

# Helper function to standardize dates to DD/MM/YYYY format
def standardize_date(date_col):
    return F.coalesce(
        F.date_format(F.to_date(date_col, 'yyyy-MM-dd'), 'dd/MM/yyyy'),
        F.date_format(F.to_date(date_col, 'MM/dd/yyyy'), 'dd/MM/yyyy'),
        F.when(F.to_date(date_col, 'dd/MM/yyyy').isNotNull(), date_col),
        F.lit(None)
    )

def standardize_gender(gender_col):
    return F.when(
        F.trim(F.upper(gender_col)).isin(['F', 'FEMALE']), 'Female'
    ).when(
        F.trim(F.upper(gender_col)).isin(['M', 'MALE']), 'Male'
    ).otherwise(None)

def clean_string(col):
    return F.trim(F.regexp_replace(col, r'\s+', ' '))

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_dim_customers",
    comment="Silver layer: Cleaned customer dimension with standardized formats"
)
def silver_dim_customers():
    return (
        spark.read.table("dataingestionproject.bronze.dim_customers")
        .filter(
            F.col("customer_key").isNotNull() &
            F.col("customer_id").isNotNull() &
            (F.trim(F.col("customer_number")) != "")
        )
        .select(
            F.col("customer_key"),
            F.col("customer_id"),
            clean_string(F.col("customer_number")).alias("customer_number"),
            clean_string(F.col("first_name")).alias("first_name"),
            clean_string(F.col("last_name")).alias("last_name"),
            clean_string(F.col("country")).alias("country"),
            clean_string(F.col("marital_status")).alias("marital_status"),
            standardize_gender(F.col("gender")).alias("gender"),
            standardize_date(F.col("birthdate")).alias("birthdate"),
            standardize_date(F.col("create_date")).alias("create_date")
        )
        .filter(F.col("gender").isNotNull())
    )

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_dim_products",
    comment="Silver layer: Cleaned product dimension with standardized formats"
)
def silver_dim_products():
    return (
        spark.read.table("dataingestionproject.bronze.dim_products")
        .filter(
            F.col("product_key").isNotNull() &
            F.col("product_id").isNotNull() &
            (F.trim(F.col("product_number")) != "")
        )
        .select(
            F.col("product_key"),
            F.col("product_id"),
            clean_string(F.col("product_number")).alias("product_number"),
            clean_string(F.col("product_name")).alias("product_name"),
            clean_string(F.col("category_id")).alias("category_id"),
            clean_string(F.col("category")).alias("category"),
            clean_string(F.col("subcategory")).alias("subcategory"),
            clean_string(F.col("maintenance")).alias("maintenance"),
            F.col("cost"),
            clean_string(F.col("product_line")).alias("product_line"),
            standardize_date(F.col("start_date")).alias("start_date")
        )
    )

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_fact_sales",
    comment="Silver layer: Cleaned sales fact table with standardized date formats"
)
def silver_fact_sales():
    return (
        spark.read.table("dataingestionproject.bronze.fact_sales")
        .filter(
            F.col("order_number").isNotNull() &
            (F.trim(F.col("order_number")) != "") &
            F.col("product_key").isNotNull() &
            F.col("customer_key").isNotNull() &
            F.col("sales_amount").isNotNull() &
            F.col("quantity").isNotNull() &
            F.col("price").isNotNull()
        )
        .select(
            clean_string(F.col("order_number")).alias("order_number"),
            F.col("product_key"),
            F.col("customer_key"),
            standardize_date(F.col("order_date")).alias("order_date"),
            standardize_date(F.col("shipping_date")).alias("shipping_date"),
            standardize_date(F.col("due_date")).alias("due_date"),
            F.col("sales_amount"),
            F.col("quantity"),
            F.col("price")
        )
        .filter(
            F.col("order_date").isNotNull() &
            F.col("shipping_date").isNotNull() &
            F.col("due_date").isNotNull()
        )
    )

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_cust_info",
    comment="Silver layer: Cleaned customer info with standardized gender and dates"
)
def silver_cust_info():
    return (
        spark.read.table("dataingestionproject.bronze.cust_info")
        .filter(
            F.col("cst_id").isNotNull() &
            F.col("cst_key").isNotNull() &
            (F.trim(F.col("cst_key")) != "")
        )
        .select(
            F.col("cst_id"),
            clean_string(F.col("cst_key")).alias("cst_key"),
            clean_string(F.col("cst_firstname")).alias("cst_firstname"),
            clean_string(F.col("cst_lastname")).alias("cst_lastname"),
            clean_string(F.col("cst_marital_status")).alias("cst_marital_status"),
            standardize_gender(F.col("cst_gndr")).alias("cst_gender"),
            standardize_date(F.col("cst_create_date")).alias("cst_create_date")
        )
        .filter(F.col("cst_gender").isNotNull())
    )

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_cust_az12",
    comment="Silver layer: Cleaned customer AZ12 data with standardized formats"
)
def silver_cust_az12():
    df = spark.read.table("dataingestionproject.bronze.cust_az12")
    for col_name in df.columns:
        if dict(df.dtypes)[col_name] == 'string':
            df = df.withColumn(col_name, clean_string(F.col(col_name)))
    return df

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_loc_a101",
    comment="Silver layer: Cleaned location A101 data with standardized formats"
)
def silver_loc_a101():
    df = spark.read.table("dataingestionproject.bronze.loc_a101")
    for col_name in df.columns:
        if dict(df.dtypes)[col_name] == 'string':
            df = df.withColumn(col_name, clean_string(F.col(col_name)))
    return df

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_prd_info",
    comment="Silver layer: Cleaned product info data with standardized formats"
)
def silver_prd_info():
    df = spark.read.table("dataingestionproject.bronze.prd_info")
    for col_name in df.columns:
        if dict(df.dtypes)[col_name] == 'string':
            df = df.withColumn(col_name, clean_string(F.col(col_name)))
    return df

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_px_cat_g1v2",
    comment="Silver layer: Cleaned product category data with standardized formats"
)
def silver_px_cat_g1v2():
    df = spark.read.table("dataingestionproject.bronze.px_cat_g1v2")
    for col_name in df.columns:
        if dict(df.dtypes)[col_name] == 'string':
            df = df.withColumn(col_name, clean_string(F.col(col_name)))
    return df

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_sales_details",
    comment="Silver layer: Cleaned sales details with standardized formats"
)
def silver_sales_details():
    df = spark.read.table("dataingestionproject.bronze.sales_details")
    for col_name in df.columns:
        if dict(df.dtypes)[col_name] == 'string':
            df = df.withColumn(col_name, clean_string(F.col(col_name)))
    return df

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_annual_enterprise_survey_2025_financial_year_provisional",
    comment="Silver layer: Cleaned annual enterprise survey 2025 data"
)
def silver_annual_enterprise_survey():
    df = spark.read.table("dataingestionproject.bronze.annual_enterprise_survey_2025_financial_year_provisional")
    for col_name in df.columns:
        if dict(df.dtypes)[col_name] == 'string':
            df = df.withColumn(col_name, clean_string(F.col(col_name)))
    return df

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_business_operations_survey_2022_business_finance",
    comment="Silver layer: Cleaned business operations survey 2022 finance data"
)
def silver_business_operations_2022_finance():
    df = spark.read.table("dataingestionproject.bronze.business_operations_survey_2022_business_finance")
    for col_name in df.columns:
        if dict(df.dtypes)[col_name] == 'string':
            df = df.withColumn(col_name, clean_string(F.col(col_name)))
    return df

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_business_operations_survey_2023_business_practices",
    comment="Silver layer: Cleaned business operations survey 2023 practices data"
)
def silver_business_operations_2023_practices():
    df = spark.read.table("dataingestionproject.bronze.business_operations_survey_2023_business_practices")
    for col_name in df.columns:
        if dict(df.dtypes)[col_name] == 'string':
            df = df.withColumn(col_name, clean_string(F.col(col_name)))
    return df

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_business_operations_survey_2023_climate_change",
    comment="Silver layer: Cleaned business operations survey 2023 climate change data"
)
def silver_business_operations_2023_climate():
    df = spark.read.table("dataingestionproject.bronze.business_operations_survey_2023_climate_change")
    for col_name in df.columns:
        if dict(df.dtypes)[col_name] == 'string':
            df = df.withColumn(col_name, clean_string(F.col(col_name)))
    return df

# COMMAND ----------

@dp.materialized_view(
    name="silver_v2_annual_enterprise_survey_2025_financial_year_provisional_size_bands",
    comment="Silver layer: Cleaned annual enterprise survey 2025 size bands data"
)
def silver_annual_enterprise_survey_size_bands():
    df = spark.read.table("dataingestionproject.bronze.annual_enterprise_survey_2025_financial_year_provisional_size_bands")
    for col_name in df.columns:
        if dict(df.dtypes)[col_name] == 'string':
            df = df.withColumn(col_name, clean_string(F.col(col_name)))
    return df

# COMMAND ----------

@dp.materialized_view(name="silver_v2_automobile_dataset", comment="Silver layer: cleaned automobile dataset")
def silver_v2_automobile_dataset():
    df = spark.read.table("dataingestionproject.bronze.automobile_dataset")

    # Apply cleaning rules
    df = df.withColumn("Make", clean_string("Make"))
    df = df.withColumn("Model", clean_string("Model"))
    df = df.withColumn("Fuel_Type", clean_string("Fuel_Type"))
    df = df.withColumn("Transmission", clean_string("Transmission"))
    df = df.withColumn("Service_History", clean_string("Service_History"))
    df = df.withColumn("Color", clean_string("Color"))
    df = df.withColumn("Body_Type", clean_string("Body_Type"))
    df = df.withColumn("Drivetrain", clean_string("Drivetrain"))
    df = df.withColumn("Location", clean_string("Location"))

    # Drop rows with null critical fields
    df = df.filter(df["Make"].isNotNull())
    df = df.filter(df["Model"].isNotNull())
    df = df.filter(df["Year"].isNotNull())
    df = df.filter(df["Selling_Price"].isNotNull())

    return df

# COMMAND ----------

@dp.materialized_view(name="silver_v2_student_performance_dataset", comment="Silver layer: cleaned student performance dataset")
def silver_v2_student_performance_dataset():
    return (
        spark.read.table("dataingestionproject.bronze.student_performance_dataset")
        .withColumn("gender", standardize_gender(F.col("gender")))
        .withColumn("gender", F.when(F.col("gender").isNotNull(), F.col("gender")).otherwise(F.lit(None)))
        .filter(F.col("gender").isNotNull())
        .withColumn("student_id", F.when(F.col("student_id").isNotNull(), F.col("student_id")).otherwise(F.lit(None)))
        .filter(F.col("student_id").isNotNull())
        .withColumn("study_time_hours", F.when(F.col("study_time_hours").isNotNull(), F.col("study_time_hours")).otherwise(F.lit(None)))
        .filter(F.col("study_time_hours").isNotNull())
        .withColumn("attendance_percent", F.when(F.col("attendance_percent").isNotNull(), F.col("attendance_percent")).otherwise(F.lit(None)))
        .filter(F.col("attendance_percent").isNotNull())
        .withColumn("sleep_hours", F.when(F.col("sleep_hours").isNotNull(), F.col("sleep_hours")).otherwise(F.lit(None)))
        .filter(F.col("sleep_hours").isNotNull())
        .withColumn("previous_grade", F.when(F.col("previous_grade").isNotNull(), F.col("previous_grade")).otherwise(F.lit(None)))
        .filter(F.col("previous_grade").isNotNull())
        .withColumn("final_exam_score", F.when(F.col("final_exam_score").isNotNull(), F.col("final_exam_score")).otherwise(F.lit(None)))
        .filter(F.col("final_exam_score").isNotNull())
        .withColumn("parental_education", clean_string(F.col("parental_education")))
        .withColumn("internet_access", clean_string(F.col("internet_access")))
        .withColumn("extracurricular_activities", clean_string(F.col("extracurricular_activities")))
        .withColumn("part_time_job", clean_string(F.col("part_time_job")))
        .withColumn("final_grade", clean_string(F.col("final_grade")))
    )


# COMMAND ----------

@dp.materialized_view(name="silver_v2_fifa_world_cup_2026_player_performance", comment="Silver layer: cleaned fifa world cup 2026 player performance data")
def silver_v2_fifa_world_cup_2026_player_performance():
    df = spark.read.table("dataingestionproject.bronze.fifa_world_cup_2026_player_performance")
    
    # Apply standardize_date on date columns
    date_columns = [col for col in df.columns if 'date' in col.lower()]
    for col in date_columns:
        df = df.withColumn(col, standardize_date(col))

    # Apply standardize_gender on gender columns
    # No columns suggest gender/sex in this dataset

    # Apply clean_string on string columns
    string_columns = [col for col in df.columns if df.schema[col].dataType.typeName() == 'StringType']
    for col in string_columns:
        df = df.withColumn(col, clean_string(col))

    # Filter nulls on primary-key columns
    primary_key_columns = [col for col in df.columns if any(keyword in col.lower() for keyword in ['id', 'key', 'number'])]
    for col in primary_key_columns:
        df = df.filter(df[col].isNotNull())

    # Filter nulls on critical numeric columns
    critical_numeric_columns = [col for col in df.columns if df.schema[col].dataType.typeName() in ['IntegerType', 'LongType', 'DoubleType'] and any(keyword in col.lower() for keyword in ['amount', 'quantity', 'goals', 'assists', 'minutes', 'rating', 'score', 'value', 'market_value_eur'])]
    for col in critical_numeric_columns:
        df = df.filter(df[col].isNotNull())

    return df

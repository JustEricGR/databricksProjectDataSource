# Databricks notebook source
import requests
from pyspark import pipelines as dp
import json
import os
import pandas as pd

# COMMAND ----------

GITHUB_REPO = "JustEricGR/databricksProjectDataSource"
GITHUB_API_URL = f"https://api.github.com/repos/{GITHUB_REPO}/contents/dataSource"

GITHUB_TOKEN = dbutils.secrets.get(scope="github", key="token")

# ── Quota guards ──────────────────────────────────────────────────────────────
# Metastore hard limit = 500 objects. Each CSV costs 4 objects:
#   1 bronze DLT table + 1 backing + 1 silver DLT MV + 1 backing.
# Fixed overhead (system/lakeview/info_schema): ~283 objects.
# Gold: 20 views × 2 = 40.  Available for data: 177 / 4 per CSV = 44 max.
# We cap at 40 bronze tables to leave a safety buffer.
BRONZE_TABLE_LIMIT = 40
METASTORE_SAFE_LIMIT = 490

_metastore_count = spark.sql(
    "SELECT COUNT(*) FROM system.information_schema.tables"
).collect()[0][0]
print(f"Metastore objects: {_metastore_count}/{METASTORE_SAFE_LIMIT}")
if _metastore_count >= METASTORE_SAFE_LIMIT:
    raise RuntimeError(
        f"Metastore near global limit ({_metastore_count}/500). "
        "Drop tables from bronze/silver/gold before adding new CSVs."
    )

_bronze_table_count = spark.sql(
    "SELECT COUNT(*) FROM dataingestionproject.information_schema.tables "
    "WHERE table_schema='bronze' AND table_type='MANAGED'"
).collect()[0][0]
print(f"Bronze tables: {_bronze_table_count}/{BRONZE_TABLE_LIMIT}")
if _bronze_table_count >= BRONZE_TABLE_LIMIT:
    raise RuntimeError(
        f"Bronze table limit reached ({_bronze_table_count}/{BRONZE_TABLE_LIMIT}). "
        f"With a 500-object metastore quota you can have at most {BRONZE_TABLE_LIMIT} "
        "CSV tables. Remove an existing CSV from dataSource/ to add a new one."
    )

# Support space-separated list of changed files from GitHub Actions
# e.g. "fileA.csv fileB.csv" when multiple CSVs change in one push
_changed_raw = spark.conf.get("changed_files", "").strip()
new_files = {os.path.basename(f) for f in _changed_raw.split() if f.strip()} if _changed_raw else set()

headers = {}
if GITHUB_TOKEN:
    headers["Authorization"] = f"token {GITHUB_TOKEN}"

try:
    response = requests.get(GITHUB_API_URL, headers=headers)
    response.raise_for_status()
    contents = response.json()

    all_csv_files = [item for item in contents if isinstance(item, dict) and item.get("name", "").endswith(".csv")]

    # Filter to only the newly committed files when triggered by a push;
    # fall back to all CSVs on manual runs (empty changed_files param)
    if new_files:
        csv_files = [f for f in all_csv_files if f["name"] in new_files]
        print(f"Incremental mode: processing {[f['name'] for f in csv_files]}")
    else:
        csv_files = all_csv_files
        print(f"Full mode candidate: {len(csv_files)} CSVs")

    # Skip tables that already exist in bronze — avoids re-ingestion on full runs
    # and prevents the retry-loop quota overflow that causes 14-min crashes.
    try:
        existing_bronze = {
            r.tableName for r in
            spark.sql("SHOW TABLES IN dataingestionproject.bronze").collect()
        }
    except Exception:
        existing_bronze = set()

    csv_files = [
        f for f in csv_files
        if f["name"].replace(".csv", "").replace("-", "_").lower()
        not in existing_bronze
    ]

    if not csv_files:
        print("All CSV tables already exist in bronze — nothing to ingest.")
        dbutils.notebook.exit("up-to-date")

    print(f"Will ingest {len(csv_files)} new/changed CSV(s): {[f['name'] for f in csv_files]}")

except requests.exceptions.HTTPError as e:
    error_msg = str(e)
    if "403" in error_msg and "rate limit" in error_msg.lower():
        raise RuntimeError("GitHub API rate limit exceeded.") from e
    else:
        raise RuntimeError(f"Failed to fetch from GitHub: {error_msg}") from e
except Exception as e:
    raise RuntimeError(f"Error discovering CSV files: {str(e)}") from e

def create_table_function(csv_info):
    table_name = csv_info["name"].replace(".csv", "").replace("-", "_").lower()
    download_url = csv_info["download_url"]

    @dp.table(
        name=table_name,
        comment=f"Ingested from GitHub: {csv_info['name']}"
    )
    def ingest_table():
        pdf = pd.read_csv(download_url, encoding='latin-1')
        pdf = pdf.loc[:, ~pdf.columns.str.startswith('Unnamed:')]
        # Strip UTF-8 BOM that appears as ï»¿ when latin-1 decoded
        pdf.columns = pdf.columns.str.replace(r'^ï»¿', '', regex=True).str.strip()
        return spark.createDataFrame(pdf)

    return ingest_table

for csv in csv_files:
    create_table_function(csv)

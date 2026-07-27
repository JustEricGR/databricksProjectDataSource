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


# Get the newly committed file passed from GitHub Actions (may include folder prefix)
new_file = os.path.basename(spark.conf.get("changed_files", ""))

headers = {}
if GITHUB_TOKEN:
    headers["Authorization"] = f"token {GITHUB_TOKEN}"

try:
    response = requests.get(GITHUB_API_URL, headers=headers)
    response.raise_for_status()
    contents = response.json()

    all_csv_files = [item for item in contents if isinstance(item, dict) and item.get("name", "").endswith(".csv")]

    # Filter to only the newly committed file if specified
    if new_file:
        csv_files = [f for f in all_csv_files if f["name"] == new_file]
    else:
        csv_files = all_csv_files

    if not csv_files:
        raise ValueError(f"No CSV files found in repository {GITHUB_REPO}")

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

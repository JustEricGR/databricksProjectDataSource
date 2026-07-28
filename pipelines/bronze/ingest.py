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
        print(f"Full mode: processing all {len(csv_files)} CSVs")

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

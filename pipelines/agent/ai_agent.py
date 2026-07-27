# Databricks notebook source
# AI Agent: Smart Silver & Gold Layer Orchestrator + Dashboard Generator
#
# Triggered as the "ai_agent" task in the dataProcessing job, after silver
# completes and before gold runs. Responsibilities:
#
#   1. Detect bronze tables that have no silver counterpart →
#      call Llama to generate smart DLT Python transforms →
#      append to the silver notebook → trigger & await silver pipeline refresh.
#
#   2. Detect silver tables that have no gold views →
#      call Llama to generate analytical SQL views →
#      append to the gold SQL file.
#
#   3. Smart-update Databricks Lakeview dashboards for all gold views →
#      group by domain → only add widgets for views not already present.
#
# The gold DLT pipeline runs after this task and picks up any new SQL.

# COMMAND ----------

import os, json, base64, time
import urllib.request, urllib.parse, urllib.error

# COMMAND ----------

# No extra SDK needed — Databricks serving endpoints are called via urllib directly

# COMMAND ----------

# ── Configuration ────────────────────────────────────────────────────────────
CATALOG            = "dataingestionproject"
# Databricks Foundation Model API — no external API key or endpoint setup needed
GATEWAY_ENDPOINT   = "databricks-meta-llama-3-3-70b-instruct"
MODEL              = "databricks-meta-llama-3-3-70b-instruct"
SILVER_PIPELINE_ID = "7c672251-9678-4b57-99ab-063b0e0ffe37"
GOLD_PIPELINE_ID   = "c5c43b5f-302b-4b55-a95f-4eb6aaf42cea"
SILVER_FILE_PATH   = "/Users/eric.ratiu@gmail.com/silver_transformations_e1ac5e72/transformations/silver_transformations"
GOLD_FILE_PATH     = "/Users/eric.ratiu@gmail.com/goldProcessing/transformations/my_transformation.sql"

# Databricks workspace host and token — no separate provider API key needed
HOST  = "https://" + spark.conf.get("spark.databricks.workspaceUrl")
TOKEN = dbutils.notebook.entry_point.getDbutils().notebook().getContext().apiToken().get()

# COMMAND ----------

# ── Databricks workspace helpers ─────────────────────────────────────────────

def _db_api(method, path, params=None, body=None):
    url = f"{HOST}{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, headers={
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type":  "application/json",
    }, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            resp = r.read()
            return json.loads(resp) if resp else {}
    except urllib.error.HTTPError as e:
        return {"error": e.read().decode()}
    except Exception as e:
        return {"error": str(e)}


def read_workspace_file(path):
    r = _db_api("GET", "/api/2.0/workspace/export",
                params={"path": path, "format": "SOURCE"})
    if "content" not in r:
        raise RuntimeError(f"Could not read {path}: {r}")
    return base64.b64decode(r["content"]).decode("utf-8")


def write_workspace_file(path, content, is_notebook=False):
    encoded = base64.b64encode(content.encode("utf-8")).decode("utf-8")
    if is_notebook:
        # NOTEBOOK type: overwrite in place with SOURCE format
        body = {"path": path, "format": "SOURCE", "language": "PYTHON",
                "content": encoded, "overwrite": True}
    else:
        # FILE type (.sql, .py raw file): delete then recreate with AUTO format
        _db_api("POST", "/api/2.0/workspace/delete",
                body={"path": path, "recursive": False})
        body = {"path": path, "format": "AUTO", "content": encoded}
    result = _db_api("POST", "/api/2.0/workspace/import", body=body)
    if "error" in result:
        raise RuntimeError(f"Could not write {path}: {result['error']}")


def trigger_pipeline(pipeline_id):
    r = _db_api("POST", f"/api/2.0/pipelines/{pipeline_id}/updates",
                body={"full_refresh": False})
    return r.get("update_id")


def wait_for_pipeline(pipeline_id, update_id, timeout_s=600):
    terminal = {"COMPLETED", "FAILED", "CANCELED"}
    for _ in range(timeout_s // 15):
        time.sleep(15)
        r = _db_api("GET", f"/api/2.0/pipelines/{pipeline_id}/updates/{update_id}")
        state = r.get("update", {}).get("state", "UNKNOWN")
        print(f"  Pipeline state: {state}")
        if state in terminal:
            return state
    return "TIMEOUT"

# COMMAND ----------

# ── Data helpers ─────────────────────────────────────────────────────────────

def list_tables(schema):
    return [r.tableName for r in
            spark.sql(f"SHOW TABLES IN {CATALOG}.{schema}").collect()]


def get_schema_and_sample(schema, table, n=8):
    cols = spark.sql(f"DESCRIBE TABLE {CATALOG}.{schema}.{table}").collect()
    schema_info = [{"name": r.col_name, "type": r.data_type}
                   for r in cols if not r.col_name.startswith("#")]
    rows = spark.sql(
        f"SELECT * FROM {CATALOG}.{schema}.{table} LIMIT {n}"
    ).collect()
    sample = [r.asDict() for r in rows]
    return schema_info, sample

# COMMAND ----------

# ── Claude helpers ────────────────────────────────────────────────────────────

def ask_claude(prompt, max_tokens=2048):
    body = json.dumps({
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
    }).encode()
    req = urllib.request.Request(
        f"{HOST}/serving-endpoints/{GATEWAY_ENDPOINT}/invocations",
        data=body,
        headers={
            "Authorization": f"Bearer {TOKEN}",
            "Content-Type":  "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as r:
        result = json.loads(r.read())
    return result["choices"][0]["message"]["content"].strip()

# COMMAND ----------

# ── Silver transform generator ────────────────────────────────────────────────

SILVER_HELPERS = """
Helpers already defined earlier in the notebook (do NOT redefine them):
  from pyspark.sql import functions as F
  from pyspark import pipelines as dp

  standardize_date(col)   → coalesces yyyy-MM-dd / MM/dd/yyyy / dd/MM/yyyy → dd/MM/yyyy string
  standardize_gender(col) → normalises F/Female→'Female', M/Male→'Male', else None
  clean_string(col)       → F.trim(F.regexp_replace(col, r'\\s+', ' '))
"""


def generate_silver_transform(table_name, schema_info, sample_rows):
    prompt = f"""You are a senior data engineer. Generate exactly ONE PySpark Delta Live Tables
materialized view for the silver cleaning layer. Output only the Python function — no prose,
no markdown fences, no imports.

Table: {table_name}
Schema:
{json.dumps(schema_info, indent=2)}
Sample data (up to 8 rows):
{json.dumps(sample_rows, indent=2, default=str)}

{SILVER_HELPERS}

Rules
-----
- Decorator: @dp.materialized_view(name="silver_v2_{table_name}", comment="Silver layer: ...")
- Read from: spark.read.table("{CATALOG}.bronze.{table_name}")
- Apply smart cleaning based on column names and sample values:
    * Columns whose name/values suggest a date        → standardize_date()
    * Columns whose name/values suggest gender/sex    → standardize_gender(), then filter nulls
    * All string columns                              → clean_string()
    * Primary-key columns (name contains id/key/number) → filter nulls
    * Critical numeric columns (amounts, quantities)  → filter nulls
- Drop rows only when a business-critical field is null
- If no meaningful cleaning is needed, still produce the view with at minimum clean_string on strings
- Return ONLY the Python function, starting with @dp.materialized_view
"""
    return ask_claude(prompt, max_tokens=1800)


# ── Gold view generator ───────────────────────────────────────────────────────

def generate_gold_views(table_name, schema_info, sample_rows):
    prompt = f"""You are a senior data engineer. Generate 2–4 Databricks SQL materialized views
for the gold analytics layer. Output only the SQL statements — no prose, no markdown fences.

Silver table: silver_v2_{table_name}
Schema:
{json.dumps(schema_info, indent=2)}
Sample data (up to 8 rows):
{json.dumps(sample_rows, indent=2, default=str)}

Rules
-----
- Syntax: CREATE OR REFRESH MATERIALIZED VIEW {CATALOG}.gold.<view_name> AS
- Prefix every view name with gold_ followed by a word from the table name, e.g. gold_{table_name}_summary
- The table name MUST appear in the view name so names stay unique across tables
- Read from: {CATALOG}.silver.silver_v2_{table_name}
- Create views that tell a coherent analytical story:
    * A summary/totals view  (counts, sums, averages)
    * A breakdown by the most meaningful categorical dimension
    * A time-series view     if date columns exist
    * A top-N ranking view   if numeric metrics exist
- Use proper GROUP BY, ORDER BY, COUNT/SUM/AVG/RANK
- Choose view names that describe what they answer (e.g. gold_survey_by_industry)
- Separate statements with a semicolon. Output only SQL.
"""
    return ask_claude(prompt, max_tokens=2000)

# COMMAND ----------

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Silver gap detection & smart transform generation
# ══════════════════════════════════════════════════════════════════════════════

bronze_tables = list_tables("bronze")
silver_stripped = {t.replace("silver_v2_", "") for t in list_tables("silver")}
new_for_silver  = [t for t in bronze_tables if t not in silver_stripped]

print(f"Bronze tables without silver transforms: {new_for_silver or 'None'}")

silver_blocks = []
for table in new_for_silver:
    print(f"\n→ Generating silver transform for: {table}")
    try:
        schema_info, sample_rows = get_schema_and_sample("bronze", table)
        code = generate_silver_transform(table, schema_info, sample_rows)
        silver_blocks.append(f"\n# COMMAND ----------\n\n{code}\n")
        print(f"  Done → silver_v2_{table}")
    except Exception as e:
        print(f"  ERROR generating silver transform for {table}: {e}")

if silver_blocks:
    current = read_workspace_file(SILVER_FILE_PATH)
    write_workspace_file(SILVER_FILE_PATH, current + "".join(silver_blocks), is_notebook=True)
    print(f"\nAppended {len(silver_blocks)} transform(s) to silver notebook")

    uid = trigger_pipeline(SILVER_PIPELINE_ID)
    print(f"Triggered silver pipeline — update: {uid}")
    state = wait_for_pipeline(SILVER_PIPELINE_ID, uid)
    print(f"Silver pipeline finished: {state}")
    if state != "COMPLETED":
        raise RuntimeError(f"Silver pipeline {state}. Aborting gold generation.")
else:
    print("No new silver transforms needed.")

# COMMAND ----------

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — Gold gap detection & smart SQL generation
# ══════════════════════════════════════════════════════════════════════════════

silver_tables_full = list_tables("silver")
gold_tables        = list_tables("gold")

# A silver table is "covered" if any gold view name contains its bare table name
silver_covered = set()
for gt in gold_tables:
    for st in silver_tables_full:
        if st.replace("silver_v2_", "") in gt:
            silver_covered.add(st)

new_for_gold = [t for t in silver_tables_full if t not in silver_covered]
print(f"\nSilver tables without gold views: {new_for_gold or 'None'}")

gold_blocks = []
for table in new_for_gold:
    print(f"\n→ Generating gold views for: {table}")
    try:
        schema_info, sample_rows = get_schema_and_sample("silver", table)
        sql = generate_gold_views(table.replace("silver_v2_", ""), schema_info, sample_rows)
        gold_blocks.append(
            f"\n-- ── AI Generated: {table} ───────────────────────────────────\n{sql}\n"
        )
        print("  Done")
    except Exception as e:
        print(f"  ERROR generating gold views for {table}: {e}")

if gold_blocks:
    current = read_workspace_file(GOLD_FILE_PATH)
    write_workspace_file(GOLD_FILE_PATH, current + "".join(gold_blocks))
    print(f"\nAppended {len(gold_blocks)} gold SQL block(s) to gold file")
    print("Gold DLT pipeline will pick up changes on its next run.")
else:
    print("No new gold views needed.")

# COMMAND ----------

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Smart Lakeview dashboard update
# ══════════════════════════════════════════════════════════════════════════════

WH_ID = spark.conf.get("spark.databricks.sqlWarehouseId", "")

DOMAIN_PATTERNS = {
    "Customer Analytics": ["gold_customer_", "gold_cust_", "gold_loc_"],
    "Product Analytics":  ["gold_product_", "gold_products_", "gold_prd_", "gold_px_"],
    "Sales Analytics":    ["gold_sales_", "gold_daily_", "gold_monthly_", "gold_order_", "gold_top_", "gold_fact_sales"],
    "Survey Analytics":   ["gold_enterprise_", "gold_business_", "gold_climate_", "gold_survey_", "gold_student_", "gold_automobile_"],
}

def classify_view(view_name):
    for domain, patterns in DOMAIN_PATTERNS.items():
        if any(view_name.startswith(p) for p in patterns):
            return domain
    return "Other"

def list_lakeview_dashboards():
    r = _db_api("GET", "/api/2.0/lakeview/dashboards", params={"page_size": 100})
    return r.get("results", [])

def get_lakeview_dashboard(dashboard_id):
    return _db_api("GET", f"/api/2.0/lakeview/dashboards/{dashboard_id}")

def create_lakeview_dashboard(display_name):
    empty_spec = json.dumps({
        "pages": [{"name": "Page_1", "displayName": display_name, "layout": []}],
        "datasets": []
    })
    body = {"display_name": display_name, "serialized_dashboard": empty_spec}
    if WH_ID:
        body["warehouse_id"] = WH_ID
    return _db_api("POST", "/api/2.0/lakeview/dashboards", body=body)

def update_lakeview_dashboard(dashboard_id, spec_dict):
    body = {"serialized_dashboard": json.dumps(spec_dict)}
    return _db_api("PUT", f"/api/2.0/lakeview/dashboards/{dashboard_id}", body=body)

def get_or_create_dashboard(display_name, existing_dashboards):
    for d in existing_dashboards:
        if d.get("display_name") == display_name:
            return d["dashboard_id"]
    created = create_lakeview_dashboard(display_name)
    return created.get("dashboard_id")

def make_dataset_name(view_name):
    return f"ds_{view_name}"[:64]

def make_widget(view_name, col_idx, schema_info):
    ds_name = make_dataset_name(view_name)
    label   = view_name.replace("_", " ").title()
    x = (col_idx % 2) * 6
    y = (col_idx // 2) * 6

    # Decide widget type from schema
    numeric_cols = [c for c in schema_info if c["type"] in ("int","bigint","double","float","decimal","long")]
    string_cols  = [c for c in schema_info if c["type"] == "string"]
    use_bar = len(string_cols) >= 1 and len(numeric_cols) >= 1

    if use_bar:
        spec = {
            "version": 2,
            "widgetType": "bar",
            "encodings": {
                "x": {"fieldName": string_cols[0]["name"], "displayName": string_cols[0]["name"]},
                "y": [{"fieldName": numeric_cols[0]["name"], "displayName": numeric_cols[0]["name"]}]
            }
        }
    else:
        spec = {
            "version": 2,
            "widgetType": "table",
            "encodings": {"columns": {"fieldName": "__query__"}}
        }

    return {
        "widget": {
            "name": f"w_{view_name}"[:64],
            "title": label,
            "queries": [{"name": "main_query", "query": {"datasetName": ds_name, "fields": []}}],
            "spec": spec
        },
        "position": {"x": x, "y": y, "width": 6, "height": 6}
    }

def smart_update_dashboard(dashboard_id, gold_views_in_domain):
    dash   = get_lakeview_dashboard(dashboard_id)
    raw    = dash.get("serialized_dashboard", "{}")
    spec   = json.loads(raw) if raw else {}
    if "pages" not in spec:
        spec["pages"] = [{"name": "Page_1", "displayName": "Main", "layout": []}]
    if "datasets" not in spec:
        spec["datasets"] = []

    # Views already in the dashboard
    existing_views = {ds["query"].split(".")[-1].strip() for ds in spec["datasets"]}

    new_views = [v for v in gold_views_in_domain if v not in existing_views]
    if not new_views:
        return 0

    page   = spec["pages"][0]
    layout = page.get("layout", [])
    widget_count = len(layout)

    for view_name in new_views:
        try:
            schema_info, _ = get_schema_and_sample("gold", view_name)
        except Exception:
            schema_info = []

        ds_name = make_dataset_name(view_name)
        spec["datasets"].append({
            "name":        ds_name,
            "displayName": view_name.replace("_", " ").title(),
            "query":       f"SELECT * FROM {CATALOG}.gold.{view_name} LIMIT 500"
        })

        widget_entry = make_widget(view_name, widget_count, schema_info)
        layout.append(widget_entry)
        widget_count += 1
        print(f"    + {view_name}")

    page["layout"] = layout
    update_lakeview_dashboard(dashboard_id, spec)
    return len(new_views)

# Group all gold views by domain
all_gold = list_tables("gold")
domain_map = {}
for view in all_gold:
    domain = classify_view(view)
    domain_map.setdefault(domain, []).append(view)

print(f"\nGold views by domain:")
for domain, views in domain_map.items():
    print(f"  {domain}: {len(views)} views")

# Get existing dashboards once
existing_dashboards = list_lakeview_dashboards()
total_widgets_added = 0

for domain, views in domain_map.items():
    print(f"\nUpdating dashboard: {domain}")
    try:
        dash_id = get_or_create_dashboard(domain, existing_dashboards)
        added   = smart_update_dashboard(dash_id, views)
        print(f"  Added {added} new widget(s)")
        total_widgets_added += added
    except Exception as e:
        print(f"  ERROR on {domain}: {e}")

# COMMAND ----------

print("\n✓ AI agent complete.")
print(f"  Silver transforms added : {len(silver_blocks)}")
print(f"  Gold view blocks added  : {len(gold_blocks)}")
print(f"  Dashboard widgets added : {total_widgets_added}")

# Databricks notebook source
# AI Agent: Smart Silver & Gold Layer Orchestrator + Dashboard Generator
#
# Triggered as the "ai_agent" task in the dataProcessing job (bronze → silver → ai_agent).
# Responsibilities:
#   1. Detect bronze tables without silver transforms → generate & apply selectively.
#   2. Detect silver tables without gold views → generate SQL → trigger SELECTIVE
#      gold DLT refresh (only new views, not all 90 → ~75% time saving).
#   2b. Cross-table join analysis: ask Llama if new + existing tables can be joined.
#   3. Smart-update Lakeview dashboards (budget-capped).
#   4. Sync changed files back to GitHub.
#
# Fast-path: if nothing new is detected, agent exits in <5s.

# COMMAND ----------

import os, re, json, base64, time
import urllib.request, urllib.parse, urllib.error

# COMMAND ----------

# No extra SDK needed — Databricks serving endpoints are called via urllib directly

# COMMAND ----------

# ── Configuration ────────────────────────────────────────────────────────────
CATALOG            = "dataingestionproject"
# Databricks Foundation Model API — no external API key or endpoint setup needed
GATEWAY_ENDPOINT   = "databricks-meta-llama-3-3-70b-instruct"
MODEL              = "databricks-meta-llama-3-3-70b-instruct"
SILVER_PIPELINE_ID  = "7c672251-9678-4b57-99ab-063b0e0ffe37"
GOLD_PIPELINE_ID    = "c5c43b5f-302b-4b55-a95f-4eb6aaf42cea"
SILVER_FILE_PATH    = "/Users/eric.ratiu@gmail.com/silver_transformations_e1ac5e72/transformations/silver_transformations"
GOLD_FILE_PATH      = "/Users/eric.ratiu@gmail.com/goldProcessing/transformations/my_transformation.sql"
UC_GOLD_VIEW_LIMIT  = 80   # each DLT MV = 2 UC objects; safe ceiling below ~200 quota

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

def trigger_gold_selective(view_names, timeout_s=600):
    """Refresh ONLY the specified new views — not all 90.  Massive time saving."""
    r = _db_api("POST", f"/api/2.0/pipelines/{GOLD_PIPELINE_ID}/updates",
                body={"full_refresh_selection": view_names})
    uid = r.get("update_id")
    if not uid:
        print(f"  Could not start selective gold refresh: {r}")
        return "FAILED"
    print(f"  Selective gold refresh triggered (update {uid[:8]}) for {len(view_names)} view(s)")
    return wait_for_pipeline(GOLD_PIPELINE_ID, uid, timeout_s)


def validate_gold_sql(block, existing_names):
    """Return list of error strings; empty = valid."""
    errors = []
    if not block.rstrip().endswith(";"):
        errors.append("Missing trailing semicolon")
    m = re.search(r'MATERIALIZED VIEW\s+[\w.`]+\.([\w`]+)', block, re.IGNORECASE)
    if m:
        name = m.group(1).strip("`")
        if name in existing_names:
            errors.append(f"Duplicate view name: {name}")
    # Detect lateral alias in WINDOW ORDER BY (common Llama mistake)
    aliases = re.findall(r'\bAS\s+(\w+)', block, re.IGNORECASE)
    for alias in aliases:
        if re.search(rf'ORDER\s+BY\s+[^)]*\b{re.escape(alias)}\b', block, re.IGNORECASE | re.DOTALL):
            errors.append(f"Possible lateral alias '{alias}' in WINDOW ORDER BY")
    return errors

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
    raw = result["choices"][0]["message"]["content"].strip()
    # Strip markdown code fences Llama sometimes wraps output in
    import re as _re
    raw = _re.sub(r'^```(?:python|sql)?\s*\n', '', raw, flags=_re.MULTILINE)
    raw = _re.sub(r'\n```\s*$', '', raw, flags=_re.MULTILINE)
    return raw.strip()

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

def generate_gold_views(table_name, schema_info, sample_rows, existing_view_names=None):
    existing_str = ", ".join(sorted(existing_view_names or [])[:30])
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
- Prefix every view name with gold_{table_name}_ so names are globally unique
- Do NOT use any of these already-existing view names: {existing_str}
- Read from: {CATALOG}.silver.silver_v2_{table_name}
- Create views that tell a coherent analytical story:
    * A summary/totals view  (counts, sums, averages)
    * A breakdown by the most meaningful categorical dimension
    * A time-series view     if date columns exist
    * A top-N ranking view   if numeric metrics exist

CRITICAL SQL QUALITY RULES — violations break the pipeline:
1. Every CREATE statement MUST end with a semicolon (;)
2. All GROUP BY columns MUST appear in SELECT
3. NEVER reference a column alias inside a WINDOW ORDER BY — repeat the full expression:
   BAD:  SUM(x) AS total, RANK() OVER (ORDER BY total DESC)
   GOOD: SUM(x) AS total, RANK() OVER (ORDER BY SUM(x) DESC)
4. Every column in SELECT must exist in the source table schema above
5. Separate multiple statements with a semicolon on its own line

Output only SQL, nothing else.
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

silver_tables_full  = list_tables("silver")
gold_tables_catalog = list_tables("gold")

# Union catalog + SQL file to detect already-covered views
_gold_sql   = read_workspace_file(GOLD_FILE_PATH)
gold_in_sql = {n.strip("`") for n in re.findall(
    r'MATERIALIZED VIEW\s+[\w.`]+\.([\w`]+)', _gold_sql, re.IGNORECASE)}
gold_all = set(gold_tables_catalog) | gold_in_sql

silver_covered = set()
for gt in gold_all:
    for st in silver_tables_full:
        if st.replace("silver_v2_", "") in gt:
            silver_covered.add(st)

new_for_gold = [t for t in silver_tables_full if t not in silver_covered]
print(f"\nSilver tables without gold views: {new_for_gold or 'None'}")

# ── Fast-path: nothing to do ──────────────────────────────────────────────────
if not new_for_silver and not new_for_gold:
    print("\nNothing new detected — skipping gold generation and refresh.")
    gold_blocks, new_gold_view_names = [], []
else:
    # ── Generate gold views ───────────────────────────────────────────────────
    gold_blocks, new_gold_view_names = [], []
    all_known_names = set(gold_all)   # passed to prompt to prevent duplicates

    for table in new_for_gold:
        print(f"\n→ Generating gold views for: {table}")
        try:
            schema_info, sample_rows = get_schema_and_sample("silver", table)
            sql = generate_gold_views(
                table.replace("silver_v2_", ""), schema_info, sample_rows,
                existing_view_names=all_known_names
            )
            # Enforce semicolons between and after statements
            sql = re.sub(r'(?<!;)\s*\n(?=CREATE OR REFRESH)', ';\n', sql, flags=re.IGNORECASE)
            if not sql.rstrip().endswith(";"):
                sql = sql.rstrip() + ";"

            # Validate before accepting
            errors = validate_gold_sql(sql, all_known_names)
            if errors:
                print(f"  SKIPPED (validation errors): {errors}")
                continue

            # Track new view names for selective refresh
            for m in re.finditer(r'MATERIALIZED VIEW\s+[\w.`]+\.([\w`]+)', sql, re.IGNORECASE):
                vname = m.group(1).strip("`")
                new_gold_view_names.append(vname)
                all_known_names.add(vname)

            gold_blocks.append(
                f"\n-- ── AI Generated: {table} ───────────────────────────────────\n{sql}\n"
            )
            print(f"  Done → {len(new_gold_view_names)} views so far")
        except Exception as e:
            print(f"  ERROR generating gold views for {table}: {e}")

    # ── Step 2b: Cross-table join analysis ───────────────────────────────────
    if new_for_gold and gold_tables_catalog:
        print("\n→ Analyzing cross-table join opportunities...")
        try:
            join_prompt = f"""You are a senior data engineer. Analyze if any of the new silver tables
can be meaningfully joined with existing gold catalog tables to produce useful cross-table analytics.

New silver tables: {[t.replace('silver_v2_', '') for t in new_for_gold]}
Sample of existing gold views: {sorted(gold_tables_catalog)[:25]}

Rules:
- Only suggest a join if there is a clear shared key (customer_key, product_key, order_number, etc.)
- Suggest at most 2 cross-table views
- If no meaningful join exists, output exactly: NO_JOIN
- View names must start with gold_cross_ and not duplicate existing names
- Follow all SQL quality rules: end with semicolon, no lateral alias in WINDOW ORDER BY
- Read from {CATALOG}.silver.* and {CATALOG}.gold.*
Output only valid SQL or NO_JOIN.
"""
            join_sql = ask_claude(join_prompt, max_tokens=1200)
            if join_sql.strip() != "NO_JOIN" and join_sql.strip():
                join_sql = join_sql.rstrip()
                if not join_sql.endswith(";"):
                    join_sql += ";"
                errors = validate_gold_sql(join_sql, all_known_names)
                if not errors:
                    gold_blocks.append(f"\n-- ── AI Cross-table joins ───────────────────────────────────\n{join_sql}\n")
                    for m in re.finditer(r'MATERIALIZED VIEW\s+[\w.`]+\.([\w`]+)', join_sql, re.IGNORECASE):
                        vname = m.group(1).strip("`")
                        new_gold_view_names.append(vname)
                    print(f"  Added cross-table join views")
                else:
                    print(f"  Cross-table SQL skipped (validation: {errors})")
            else:
                print("  No meaningful cross-table joins found")
        except Exception as e:
            print(f"  Cross-table analysis error (non-fatal): {e}")

    # ── UC quota guard + deduplication ───────────────────────────────────────
    if gold_blocks:
        uc_mv_count = len(gold_tables_catalog)
        uc_slots    = max(0, UC_GOLD_VIEW_LIMIT - uc_mv_count)
        if uc_slots == 0:
            print(f"\nUC quota reached ({uc_mv_count}/{UC_GOLD_VIEW_LIMIT}) — skipping append.")
            gold_blocks, new_gold_view_names = [], []
        elif len(new_gold_view_names) > uc_slots:
            print(f"\nUC quota: {uc_slots} slots, truncating.")
            gold_blocks = gold_blocks[:uc_slots]
            new_gold_view_names = new_gold_view_names[:uc_slots]

    if gold_blocks:
        current  = read_workspace_file(GOLD_FILE_PATH)
        combined = current + "".join(gold_blocks)

        # Deduplicate (first-write-wins)
        all_blks = re.split(r'(?=CREATE OR REFRESH MATERIALIZED VIEW)', combined, flags=re.IGNORECASE)
        all_blks = [b.strip() for b in all_blks if b.strip()]
        seen, deduped = {}, []
        for blk in all_blks:
            m = re.search(r'MATERIALIZED VIEW\s+[\w.`]+\.([\w`]+)', blk, re.IGNORECASE)
            n = m.group(1).strip("`") if m else None
            if n not in seen:
                seen[n] = True
                deduped.append(blk)
        combined = '\n\n'.join(deduped) + '\n'

        write_workspace_file(GOLD_FILE_PATH, combined)
        print(f"\nAppended {len(gold_blocks)} block(s), {len(deduped)} total unique views in file")

        # ── Selective gold refresh (only new views) — KEY TIME SAVING ────────
        if new_gold_view_names:
            print(f"\nSelective gold refresh: {new_gold_view_names}")
            gold_state = trigger_gold_selective(new_gold_view_names)
            print(f"Gold selective refresh: {gold_state}")
            if gold_state != "COMPLETED":
                print(f"Warning: gold selective refresh ended with {gold_state}")
    else:
        print("No new gold views to append.")

# COMMAND ----------

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Smart Lakeview dashboard update
# ══════════════════════════════════════════════════════════════════════════════

WH_ID = "3ac8cbd811e6e287"  # Serverless Starter Warehouse

# ── Workspace budget limits ───────────────────────────────────────────────────
MAX_WIDGETS_PER_DASHBOARD = 8   # max widgets shown per domain dashboard
MAX_TOTAL_WIDGETS         = 30  # hard cap across ALL dashboards combined
# UC_GOLD_VIEW_LIMIT defined in config section above

# Views whose name ends with these suffixes are high-value; others are skipped
# when the per-dashboard cap is reached. Order = priority (highest first).
PRIORITY_SUFFIXES = [
    "_summary", "_demographics", "_by_country", "_by_category",
    "_monthly_sales", "_by_industry", "_top_customers", "_top_products",
    "_by_gender", "_by_size", "_segmentation", "_lifetime_value",
]

def priority_score(view_name):
    for i, suffix in enumerate(PRIORITY_SUFFIXES):
        if view_name.endswith(suffix):
            return len(PRIORITY_SUFFIXES) - i  # higher = more important
    return 0  # not a priority view — only included if budget allows

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
    r = _db_api("GET", "/api/2.0/lakeview/dashboards",
                params={"page_size": 50, "filter_by.keyword": ""})
    return r.get("dashboards", r.get("results", []))

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
    return f"ds_{view_name}"[:63]

def make_widget(view_name, col_idx, schema_info):
    ds_name  = make_dataset_name(view_name)
    label    = view_name.replace("_", " ").title()
    x = (col_idx % 2) * 6
    y = (col_idx // 2) * 6

    numeric_cols = [c for c in schema_info if any(t in c["type"].lower()
                   for t in ("int","bigint","double","float","decimal","long"))]
    string_cols  = [c for c in schema_info if c["type"].lower() == "string"]
    use_bar = len(string_cols) >= 1 and len(numeric_cols) >= 1

    if use_bar:
        xc, yc = string_cols[0]["name"], numeric_cols[0]["name"]
        fields = [{"name": xc, "expression": f"`{xc}`"},
                  {"name": yc, "expression": f"`{yc}`"}]
        spec = {
            "version": 3,
            "widgetType": "bar",
            "encodings": {
                "x": {"fieldName": xc, "displayName": xc.replace("_"," ").title()},
                "y": [{"fieldName": yc, "displayName": yc.replace("_"," ").title()}]
            }
        }
        disagg = False
    else:
        fields = [{"name": c["name"], "expression": f"`{c['name']}`"}
                  for c in schema_info[:8]]
        spec   = {"version": 3, "widgetType": "table"}
        disagg = True

    return {
        "widget": {
            "name":  f"w_{view_name}"[:63],
            "title": label,
            "queries": [{"name": "main_query", "query": {
                "datasetName":   ds_name,
                "fields":        fields,
                "disaggregated": disagg,
            }}],
            "spec": spec
        },
        "position": {"x": x, "y": y, "width": 6, "height": 6}
    }

def smart_update_dashboard(dashboard_id, gold_views_in_domain, global_budget):
    """
    global_budget: dict with key 'remaining' — decremented as widgets are added.
    Returns number of widgets added.
    """
    dash   = get_lakeview_dashboard(dashboard_id)
    raw    = dash.get("serialized_dashboard", "{}")
    spec   = json.loads(raw) if raw else {}
    if "pages" not in spec:
        spec["pages"] = [{"name": "Page_1", "displayName": "Main", "layout": []}]
    if "datasets" not in spec:
        spec["datasets"] = []

    # Views already in this dashboard
    existing_views = {ds["query"].split(".")[-1].strip() for ds in spec["datasets"]}
    current_count  = len(spec["pages"][0].get("layout", []))

    # Filter to new views only, sorted by priority (highest first)
    new_views = [v for v in gold_views_in_domain if v not in existing_views]
    new_views.sort(key=priority_score, reverse=True)

    # Apply per-dashboard cap and global cap
    slots_in_dashboard = max(0, MAX_WIDGETS_PER_DASHBOARD - current_count)
    candidates = new_views[:slots_in_dashboard]

    page   = spec["pages"][0]
    layout = page.get("layout", [])
    added  = 0

    for view_name in candidates:
        if global_budget["remaining"] <= 0:
            print(f"    (global widget budget exhausted — skipping {view_name})")
            break

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

        widget_entry = make_widget(view_name, current_count + added, schema_info)
        layout.append(widget_entry)
        added += 1
        global_budget["remaining"] -= 1
        score = priority_score(view_name)
        print(f"    + {view_name}  (priority={score})")

    skipped = len(new_views) - added
    if skipped > 0:
        print(f"    Skipped {skipped} lower-priority views (budget/cap)")

    if added > 0:
        page["layout"] = layout
        update_lakeview_dashboard(dashboard_id, spec)
    return added

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
global_budget = {"remaining": MAX_TOTAL_WIDGETS}

print(f"\nDashboard budget: max {MAX_WIDGETS_PER_DASHBOARD} per domain, {MAX_TOTAL_WIDGETS} total")

for domain, views in domain_map.items():
    if global_budget["remaining"] <= 0:
        print(f"\nSkipping {domain} — global widget budget exhausted")
        continue
    print(f"\nUpdating dashboard: {domain}  ({len(views)} views, {global_budget['remaining']} slots left)")
    try:
        dash_id = get_or_create_dashboard(domain, existing_dashboards)
        added   = smart_update_dashboard(dash_id, views, global_budget)
        print(f"  Added {added} new widget(s)")
        total_widgets_added += added
    except Exception as e:
        print(f"  ERROR on {domain}: {e}")

# COMMAND ----------

# COMMAND ----------

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — Sync updated workspace files back to GitHub
# ══════════════════════════════════════════════════════════════════════════════

GITHUB_REPO  = "JustEricGR/databricksProjectDataSource"
GITHUB_TOKEN = dbutils.secrets.get(scope="github", key="token")

def github_api(method, path, body=None):
    url  = f"https://api.github.com/repos/{GITHUB_REPO}/{path}"
    data = json.dumps(body).encode() if body else None
    req  = urllib.request.Request(url, data=data, headers={
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept":        "application/vnd.github+json",
        "Content-Type":  "application/json",
    }, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            raw = r.read(); return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        return {"error": e.read().decode()}

def github_push_file(repo_path, content_str, commit_message):
    # Get current file SHA (needed for update)
    existing = github_api("GET", f"contents/{repo_path}")
    sha = existing.get("sha")  # None if file doesn't exist yet
    body = {
        "message": commit_message,
        "content": base64.b64encode(content_str.encode("utf-8")).decode("utf-8"),
    }
    if sha:
        body["sha"] = sha
    result = github_api("PUT", f"contents/{repo_path}", body=body)
    return "error" not in result

synced = []
if silver_blocks or gold_blocks:
    # Re-export the files as they now stand in Databricks workspace
    silver_latest = read_workspace_file(SILVER_FILE_PATH)
    gold_latest   = read_workspace_file(GOLD_FILE_PATH)

    if silver_blocks:
        ok = github_push_file(
            "pipelines/silver/silver_transformations.py",
            silver_latest,
            f"agent: add silver transforms for {[t for t in new_for_silver if t in [b for b in silver_blocks]]}"
        )
        if ok: synced.append("silver_transformations.py")

    if gold_blocks:
        ok = github_push_file(
            "pipelines/gold/my_transformation.sql",
            gold_latest,
            f"agent: add gold views for new silver tables"
        )
        if ok: synced.append("my_transformation.sql")

print(f"\nGitHub sync: {synced or 'nothing to push'}")

# COMMAND ----------

print("\n✓ AI agent complete.")
print(f"  Silver transforms added : {len(silver_blocks)}")
print(f"  Gold view blocks added  : {len(gold_blocks)}")
print(f"  Dashboard widgets added : {total_widgets_added}")
print(f"  Files synced to GitHub  : {synced or 'none'}")

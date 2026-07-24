#!/usr/bin/env python3
import json
import sys
import os
import urllib.request
import urllib.parse
import urllib.error
import base64
import configparser

def load_credentials():
    host = os.environ.get("DATABRICKS_HOST", "").rstrip("/")
    token = os.environ.get("DATABRICKS_TOKEN", "")

    if not host or not token:
        cfg_path = os.environ.get(
            "DATABRICKS_CONFIG_FILE",
            os.path.join(os.path.expanduser("~"), ".databrickscfg")
        )
        if os.path.exists(cfg_path):
            cfg = configparser.ConfigParser()
            cfg.read(cfg_path)
            section = "DEFAULT"
            host = host or cfg.get(section, "host", fallback="").rstrip("/")
            token = token or cfg.get(section, "token", fallback="")

    return host, token

DATABRICKS_HOST, DATABRICKS_TOKEN = load_credentials()

def databricks_api(method, path, params=None, body=None):
    url = f"{DATABRICKS_HOST}{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)

    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {DATABRICKS_TOKEN}",
            "Content-Type": "application/json"
        },
        method=method
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return {"error": e.read().decode()}
    except Exception as e:
        return {"error": str(e)}

TOOLS = [
    {
        "name": "list_jobs",
        "description": "List all Databricks jobs in the workspace",
        "inputSchema": {"type": "object", "properties": {}}
    },
    {
        "name": "run_job",
        "description": "Trigger a Databricks job run by job ID",
        "inputSchema": {
            "type": "object",
            "properties": {
                "job_id": {"type": "string", "description": "The job ID to trigger"}
            },
            "required": ["job_id"]
        }
    },
    {
        "name": "list_workspace",
        "description": "List files and folders at a Databricks workspace path",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Workspace path to list, e.g. /Workspace/Users/you@email.com"}
            },
            "required": ["path"]
        }
    },
    {
        "name": "export_file",
        "description": "Export a notebook or file from Databricks workspace and return its content",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "Workspace path to export"},
                "format": {
                    "type": "string",
                    "description": "Export format: SOURCE, HTML, JUPYTER, DBC",
                    "default": "SOURCE"
                }
            },
            "required": ["path"]
        }
    },
    {
        "name": "list_pipelines",
        "description": "List all Delta Live Tables (DLT) pipelines",
        "inputSchema": {"type": "object", "properties": {}}
    },
    {
        "name": "get_pipeline",
        "description": "Get details and status of a specific DLT pipeline",
        "inputSchema": {
            "type": "object",
            "properties": {
                "pipeline_id": {"type": "string", "description": "The pipeline ID"}
            },
            "required": ["pipeline_id"]
        }
    },
    {
        "name": "list_clusters",
        "description": "List all Databricks clusters and their state",
        "inputSchema": {"type": "object", "properties": {}}
    },
    {
        "name": "run_sql",
        "description": "Execute a SQL statement on a Databricks SQL warehouse",
        "inputSchema": {
            "type": "object",
            "properties": {
                "statement": {"type": "string", "description": "SQL statement to execute"},
                "warehouse_id": {"type": "string", "description": "SQL warehouse ID to run against"}
            },
            "required": ["statement", "warehouse_id"]
        }
    },
    {
        "name": "list_warehouses",
        "description": "List all SQL warehouses (needed to get warehouse_id for run_sql)",
        "inputSchema": {"type": "object", "properties": {}}
    },
    {
        "name": "get_job_run_status",
        "description": "Get the status of a specific job run",
        "inputSchema": {
            "type": "object",
            "properties": {
                "run_id": {"type": "string", "description": "The job run ID"}
            },
            "required": ["run_id"]
        }
    }
]

def call_tool(name, arguments):
    if name == "list_jobs":
        return databricks_api("GET", "/api/2.1/jobs/list", params={"limit": 25})

    elif name == "run_job":
        return databricks_api("POST", "/api/2.1/jobs/run-now", body={"job_id": int(arguments["job_id"])})

    elif name == "list_workspace":
        return databricks_api("GET", "/api/2.0/workspace/list", params={"path": arguments["path"]})

    elif name == "export_file":
        fmt = arguments.get("format", "SOURCE")
        result = databricks_api("GET", "/api/2.0/workspace/export", params={"path": arguments["path"], "format": fmt})
        if "content" in result:
            result["content"] = base64.b64decode(result["content"]).decode("utf-8", errors="replace")
        return result

    elif name == "list_pipelines":
        return databricks_api("GET", "/api/2.0/pipelines")

    elif name == "get_pipeline":
        return databricks_api("GET", f"/api/2.0/pipelines/{arguments['pipeline_id']}")

    elif name == "list_clusters":
        return databricks_api("GET", "/api/2.0/clusters/list")

    elif name == "run_sql":
        return databricks_api("POST", "/api/2.0/sql/statements", body={
            "statement": arguments["statement"],
            "warehouse_id": arguments["warehouse_id"],
            "wait_timeout": "30s"
        })

    elif name == "list_warehouses":
        return databricks_api("GET", "/api/2.0/sql/warehouses")

    elif name == "get_job_run_status":
        return databricks_api("GET", "/api/2.1/jobs/runs/get", params={"run_id": arguments["run_id"]})

    return {"error": f"Unknown tool: {name}"}

def handle_request(request):
    req_id = request.get("id")
    method = request.get("method")
    params = request.get("params", {})

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "databricks-mcp", "version": "1.0.0"}
            }
        }

    elif method == "notifications/initialized":
        return None

    elif method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {"tools": TOOLS}
        }

    elif method == "tools/call":
        tool_name = params.get("name")
        arguments = params.get("arguments", {})
        try:
            result = call_tool(tool_name, arguments)
        except Exception as e:
            result = {"error": str(e)}

        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "content": [{"type": "text", "text": json.dumps(result, indent=2)}]
            }
        }

    return {
        "jsonrpc": "2.0",
        "id": req_id,
        "error": {"code": -32601, "message": f"Method not found: {method}"}
    }

if __name__ == "__main__":
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            request = json.loads(line)
            response = handle_request(request)
            if response is not None:
                print(json.dumps(response), flush=True)
        except Exception as e:
            print(json.dumps({
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32700, "message": str(e)}
            }), flush=True)

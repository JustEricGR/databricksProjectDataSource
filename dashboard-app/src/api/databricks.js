// In dev:   calls go to /proxy/... → Vite proxies to Databricks (no CORS)
// In prod:  calls go to /proxy/... → Vercel serverless function proxies to Databricks
const TOKEN   = import.meta.env.VITE_DATABRICKS_TOKEN
const WH_ID   = import.meta.env.VITE_WAREHOUSE_ID || '3ac8cbd811e6e287'
const CATALOG = 'dataingestionproject'

async function pollStatement(statementId) {
  const terminal = new Set(['SUCCEEDED', 'FAILED', 'CANCELED', 'CLOSED'])
  for (let i = 0; i < 30; i++) {
    const r = await fetch(`/proxy/api/2.0/sql/statements/${statementId}`, {
      headers: { Authorization: `Bearer ${TOKEN}` }
    })
    const data = await r.json()
    if (terminal.has(data.status?.state)) return data
    await new Promise(res => setTimeout(res, 2000))
  }
  throw new Error('SQL statement timed out')
}

export async function runSQL(statement) {
  const r = await fetch('/proxy/api/2.0/sql/statements', {
    method:  'POST',
    headers: {
      Authorization:  `Bearer ${TOKEN}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ statement, warehouse_id: WH_ID, wait_timeout: '0s' })
  })
  if (!r.ok) throw new Error(`HTTP ${r.status}: ${await r.text()}`)
  const init = await r.json()
  const done = await pollStatement(init.statement_id)
  if (done.status?.state !== 'SUCCEEDED') {
    throw new Error(done.status?.error?.message || 'Query failed')
  }
  const cols = done.manifest?.schema?.columns?.map(c => c.name) || []
  const rows = done.result?.data_array || []
  return rows.map(row => Object.fromEntries(cols.map((c, i) => [c, row[i]])))
}

export async function listSilverTables() {
  return runSQL(`SHOW TABLES IN ${CATALOG}.silver`)
}

export async function listGoldTables() {
  return runSQL(`SHOW TABLES IN ${CATALOG}.gold`)
}

export { CATALOG }

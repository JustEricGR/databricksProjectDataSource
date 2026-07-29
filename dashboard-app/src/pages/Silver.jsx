import { useState, useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import { runSQL } from '../api/databricks'
import { SILVER_QUERIES, DOMAIN_MAP, autoQuery } from '../queries/silver'
import ChartWidget from '../components/ChartWidget'

function TableSection({ tableName, queries }) {
  const [open, setOpen] = useState(true)
  const label = tableName.replace('silver_v2_', '').replace(/_/g, ' ')

  return (
    <div className="bg-surface border border-border rounded-xl overflow-hidden mb-6">
      <button
        onClick={() => setOpen(o => !o)}
        className="w-full flex items-center justify-between px-5 py-4 text-left hover:bg-bg transition-colors"
      >
        <div>
          <span className="font-semibold text-white capitalize">{label}</span>
          <span className="ml-2 text-xs text-muted bg-bg px-2 py-0.5 rounded">{tableName}</span>
        </div>
        <span className="text-muted">{open ? '▲' : '▼'}</span>
      </button>

      {open && (
        <div className="border-t border-border">
          <div className={`grid gap-0 divide-x divide-border ${queries.length === 1 ? 'grid-cols-1' : queries.length === 2 ? 'grid-cols-2' : 'grid-cols-3'}`}>
            {queries.map((q, i) => (
              <div key={i} className="p-4">
                <div className="text-sm font-medium text-silver mb-1">{q.title}</div>
                {q.description && <div className="text-xs text-muted mb-3">{q.description}</div>}
                <ChartWidget query={q} />
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

export default function Silver() {
  const [params] = useSearchParams()
  const domainFilter = params.get('domain')

  const [allTables,    setAllTables]    = useState([])
  const [tableSchemas, setTableSchemas] = useState({})
  const [activeDomain, setActiveDomain] = useState(domainFilter || 'All')

  // Fetch all silver tables
  useEffect(() => {
    runSQL('SHOW TABLES IN dataingestionproject.silver')
      .then(rows => setAllTables(rows.map(r => r.tableName)))
      .catch(() => {})
  }, [])

  // Fetch schema for tables without pre-defined queries
  useEffect(() => {
    allTables.forEach(t => {
      if (!SILVER_QUERIES[t]) {
        runSQL(`DESCRIBE TABLE dataingestionproject.silver.${t}`)
          .then(rows => {
            const cols = rows.filter(r => !r.col_name?.startsWith('#'))
                             .map(r => ({ name: r.col_name, type: r.data_type }))
            setTableSchemas(prev => ({ ...prev, [t]: cols }))
          })
          .catch(() => {})
      }
    })
  }, [allTables])

  const domains = ['All', ...Object.keys(DOMAIN_MAP)]

  const filteredTables = allTables.filter(t => {
    if (activeDomain === 'All') return true
    return (DOMAIN_MAP[activeDomain] || []).includes(t)
  })

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <h1 className="text-2xl font-bold text-white mb-1">Silver Layer Analytics</h1>
      <p className="text-muted text-sm mb-5">All {allTables.length} silver tables — live queries from Databricks</p>

      {/* Domain filter tabs */}
      <div className="flex gap-2 flex-wrap mb-6">
        {domains.map(d => (
          <button
            key={d}
            onClick={() => setActiveDomain(d)}
            className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
              activeDomain === d
                ? 'bg-agent text-white'
                : 'bg-surface border border-border text-muted hover:text-white'
            }`}
          >
            {d}
            {d !== 'All' && (
              <span className="ml-1 text-xs opacity-60">({(DOMAIN_MAP[d] || []).length})</span>
            )}
          </button>
        ))}
      </div>

      {/* Table sections */}
      {filteredTables.length === 0 && (
        <div className="text-muted text-center py-12">Loading tables…</div>
      )}
      {filteredTables.map(tableName => {
        const queries = SILVER_QUERIES[tableName]
          || (tableSchemas[tableName] ? autoQuery(tableName, tableSchemas[tableName]) : null)
        if (!queries) return null
        return <TableSection key={tableName} tableName={tableName} queries={queries} />
      })}
    </div>
  )
}

import { useState, useEffect } from 'react'
import { runSQL } from '../api/databricks'
import ChartWidget from '../components/ChartWidget'

export default function Gold() {
  const [tables, setTables] = useState([])

  useEffect(() => {
    runSQL('SHOW TABLES IN dataingestionproject.gold')
      .then(rows => setTables(rows.map(r => r.tableName)))
      .catch(() => {})
  }, [])

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <h1 className="text-2xl font-bold text-white mb-1">Gold Summary Views</h1>
      <p className="text-muted text-sm mb-6">
        {tables.length} key summary materialized views — detailed analytics available in Silver Layer tab
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {tables.map(t => (
          <div key={t} className="bg-surface border border-border rounded-xl overflow-hidden">
            <div className="px-5 py-3 border-b border-border">
              <span className="font-medium text-white capitalize">{t.replace('gold_','').replace(/_/g,' ')}</span>
              <span className="ml-2 text-xs text-muted">{t}</span>
            </div>
            <div className="p-4">
              <ChartWidget query={{
                sql: `SELECT * FROM dataingestionproject.gold.${t} LIMIT 500`,
                chartType: 'table',
                title: t,
                xKey: null,
                yKey: null
              }} />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

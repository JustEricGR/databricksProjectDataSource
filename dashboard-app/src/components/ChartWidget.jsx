import { useState, useEffect } from 'react'
import {
  BarChart, Bar, LineChart, Line, AreaChart, Area,
  PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, Legend
} from 'recharts'
import { runSQL } from '../api/databricks'

const COLORS = ['#6e7bf0','#f0b429','#4ac9ff','#cd7f32','#a0a8c0','#f97316','#10b981','#ec4899']

function KPIDisplay({ data }) {
  if (!data?.length) return null
  const row = data[0]
  return (
    <div className="grid grid-cols-2 gap-4 p-4">
      {Object.entries(row).map(([k, v]) => (
        <div key={k} className="bg-bg rounded-lg p-4 text-center">
          <div className="text-2xl font-bold text-gold">{Number(v).toLocaleString()}</div>
          <div className="text-sm text-muted mt-1">{k.replace(/_/g,' ')}</div>
        </div>
      ))}
    </div>
  )
}

function TableDisplay({ data }) {
  if (!data?.length) return <div className="text-muted p-4">No data</div>
  const cols = Object.keys(data[0])
  return (
    <div className="overflow-x-auto max-h-64">
      <table className="w-full text-xs">
        <thead>
          <tr className="border-b border-border">
            {cols.map(c => <th key={c} className="text-left p-2 text-muted font-medium">{c}</th>)}
          </tr>
        </thead>
        <tbody>
          {data.slice(0, 20).map((row, i) => (
            <tr key={i} className="border-b border-border hover:bg-bg">
              {cols.map(c => <td key={c} className="p-2 text-silver truncate max-w-32">{row[c]}</td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export default function ChartWidget({ query }) {
  const [data,    setData]    = useState(null)
  const [loading, setLoading] = useState(true)
  const [error,   setError]   = useState(null)

  useEffect(() => {
    setLoading(true); setError(null)
    runSQL(query.sql)
      .then(rows => { setData(rows); setLoading(false) })
      .catch(e  => { setError(e.message); setLoading(false) })
  }, [query.sql])

  const h = 220

  if (loading) return (
    <div className="flex items-center justify-center h-40 text-muted animate-pulse">Loading…</div>
  )
  if (error) return (
    <div className="text-red-400 text-xs p-3 bg-bg rounded">{error}</div>
  )
  if (!data?.length) return (
    <div className="text-muted text-sm p-4 text-center">No data</div>
  )

  if (query.chartType === 'kpi')   return <KPIDisplay data={data} />
  if (query.chartType === 'table') return <TableDisplay data={data} />

  const numericData = data.map(r => ({
    ...r,
    [query.yKey]: parseFloat(r[query.yKey]) || 0
  }))

  const xLabel = (v) => {
    const s = String(v ?? '')
    return s.length > 14 ? s.slice(0, 12) + '…' : s
  }

  if (query.chartType === 'pie') return (
    <ResponsiveContainer width="100%" height={h}>
      <PieChart>
        <Pie data={numericData} dataKey={query.yKey} nameKey={query.xKey}
             cx="50%" cy="50%" outerRadius={80} label={e => xLabel(e[query.xKey])}>
          {numericData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
        </Pie>
        <Tooltip formatter={v => Number(v).toLocaleString()} />
      </PieChart>
    </ResponsiveContainer>
  )

  if (query.chartType === 'line') return (
    <ResponsiveContainer width="100%" height={h}>
      <LineChart data={numericData} margin={{ left: 10, right: 10 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#2e3350" />
        <XAxis dataKey={query.xKey} tick={{ fill: '#8b90a8', fontSize: 10 }} tickFormatter={xLabel} />
        <YAxis tick={{ fill: '#8b90a8', fontSize: 10 }} />
        <Tooltip formatter={v => Number(v).toLocaleString()} />
        <Line type="monotone" dataKey={query.yKey} stroke="#6e7bf0" strokeWidth={2} dot={false} />
      </LineChart>
    </ResponsiveContainer>
  )

  if (query.chartType === 'area') return (
    <ResponsiveContainer width="100%" height={h}>
      <AreaChart data={numericData} margin={{ left: 10, right: 10 }}>
        <defs>
          <linearGradient id="grad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%"  stopColor="#6e7bf0" stopOpacity={0.4} />
            <stop offset="95%" stopColor="#6e7bf0" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#2e3350" />
        <XAxis dataKey={query.xKey} tick={{ fill: '#8b90a8', fontSize: 10 }} tickFormatter={xLabel} />
        <YAxis tick={{ fill: '#8b90a8', fontSize: 10 }} />
        <Tooltip formatter={v => Number(v).toLocaleString()} />
        <Area type="monotone" dataKey={query.yKey} stroke="#6e7bf0" fill="url(#grad)" strokeWidth={2} />
      </AreaChart>
    </ResponsiveContainer>
  )

  // Default: bar
  return (
    <ResponsiveContainer width="100%" height={h}>
      <BarChart data={numericData} margin={{ left: 10, right: 10 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#2e3350" />
        <XAxis dataKey={query.xKey} tick={{ fill: '#8b90a8', fontSize: 10 }} tickFormatter={xLabel} />
        <YAxis tick={{ fill: '#8b90a8', fontSize: 10 }} />
        <Tooltip formatter={v => Number(v).toLocaleString()} />
        <Bar dataKey={query.yKey} radius={[4, 4, 0, 0]}>
          {numericData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  )
}

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

  const h = 260

  if (loading) return (
    <div className="flex items-center justify-center h-40 text-muted animate-pulse text-sm">Loading…</div>
  )
  if (error) {
    const isNotExist = error.includes('TABLE_DOES_NOT_EXIST') || error.includes('RESOURCE_DOES_NOT_EXIST')
    return (
      <div className="flex flex-col items-center justify-center h-28 gap-2 text-center p-3">
        <span className="text-2xl">{isNotExist ? '⏳' : '⚠️'}</span>
        <span className="text-sm text-muted">
          {isNotExist
            ? 'Pipeline refreshing — data available shortly'
            : 'Query unavailable'}
        </span>
        {!isNotExist && <span className="text-xs text-red-400 max-w-xs truncate">{error}</span>}
      </div>
    )
  }
  if (!data?.length) return (
    <div className="text-muted text-sm p-4 text-center">No data</div>
  )

  if (query.chartType === 'kpi')   return <KPIDisplay data={data} />
  if (query.chartType === 'table') return <TableDisplay data={data} />

  // Auto-detect keys if the configured ones don't match actual columns
  const actualCols = Object.keys(data[0])
  let xKey = query.xKey
  let yKey = query.yKey

  if (xKey && !actualCols.includes(xKey)) {
    // Pick first string-looking column as X
    xKey = actualCols.find(k => typeof data[0][k] === 'string') || actualCols[0]
  }
  if (yKey && !actualCols.includes(yKey)) {
    // Pick first numeric-looking column as Y
    yKey = actualCols.find(k => !isNaN(parseFloat(data[0][k])) && typeof data[0][k] !== 'boolean' && k !== xKey)
        || actualCols.find(k => k !== xKey)
  }
  // If still no match, fall back to table
  if (!xKey || !yKey || xKey === yKey) return <TableDisplay data={data} />

  const numericData = data.map(r => ({
    ...r,
    [yKey]: parseFloat(r[yKey]) || 0
  }))

  // Truncate only for tooltip labels; X axis gets full text rotated
  const shortLabel = (v) => {
    const s = String(v ?? '')
    return s.length > 18 ? s.slice(0, 16) + '…' : s
  }

  const fmtNum = v =>
    Number(v) >= 1000000 ? `${(Number(v)/1000000).toFixed(1)}M`
    : Number(v) >= 1000  ? `${(Number(v)/1000).toFixed(0)}K`
    : String(v)

  const tooltipStyle = {
    background: '#1a1d27', border: '1px solid #2e3350', borderRadius: 6, fontSize: 12
  }

  if (query.chartType === 'pie') return (
    <ResponsiveContainer width="100%" height={h}>
      <PieChart>
        <Pie data={numericData} dataKey={yKey} nameKey={xKey}
             cx="50%" cy="45%" outerRadius={90}
             label={({ cx, cy, midAngle, outerRadius, name, percent }) =>
               percent > 0.05 ? `${shortLabel(name)} ${(percent*100).toFixed(0)}%` : ''
             }
             labelLine={false}>
          {numericData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
        </Pie>
        <Tooltip formatter={v => Number(v).toLocaleString()} />
        <Legend formatter={shortLabel} />
      </PieChart>
    </ResponsiveContainer>
  )

  if (query.chartType === 'line') return (
    <ResponsiveContainer width="100%" height={h}>
      <LineChart data={numericData} margin={{ left: 0, right: 16, top: 4, bottom: 4 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#2e3350" />
        <XAxis dataKey={xKey} tick={{ fill: '#8b90a8', fontSize: 10 }} tickFormatter={shortLabel} />
        <YAxis tick={{ fill: '#8b90a8', fontSize: 10 }} tickFormatter={fmtNum} width={52} />
        <Tooltip formatter={v => Number(v).toLocaleString()} contentStyle={tooltipStyle} />
        <Line type="monotone" dataKey={yKey} stroke="#6e7bf0" strokeWidth={2} dot={false} />
      </LineChart>
    </ResponsiveContainer>
  )

  if (query.chartType === 'area') return (
    <ResponsiveContainer width="100%" height={h}>
      <AreaChart data={numericData} margin={{ left: 0, right: 16, top: 4, bottom: 4 }}>
        <defs>
          <linearGradient id="grad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%"  stopColor="#6e7bf0" stopOpacity={0.4} />
            <stop offset="95%" stopColor="#6e7bf0" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#2e3350" />
        <XAxis dataKey={xKey} tick={{ fill: '#8b90a8', fontSize: 10 }} tickFormatter={shortLabel} />
        <YAxis tick={{ fill: '#8b90a8', fontSize: 10 }} tickFormatter={fmtNum} width={52} />
        <Tooltip formatter={v => Number(v).toLocaleString()} contentStyle={tooltipStyle} />
        <Area type="monotone" dataKey={yKey} stroke="#6e7bf0" fill="url(#grad)" strokeWidth={2} />
      </AreaChart>
    </ResponsiveContainer>
  )

  // Horizontal bar — categories on Y axis, always readable regardless of label length
  const barH = Math.max(h, numericData.length * 28 + 40)
  return (
    <ResponsiveContainer width="100%" height={barH}>
      <BarChart
        data={numericData}
        layout="vertical"
        margin={{ left: 8, right: 32, top: 4, bottom: 4 }}
      >
        <CartesianGrid strokeDasharray="3 3" stroke="#2e3350" horizontal={false} />
        <XAxis
          type="number"
          tick={{ fill: '#8b90a8', fontSize: 10 }}
          tickFormatter={fmtNum}
        />
        <YAxis
          type="category"
          dataKey={xKey}
          width={160}
          tick={{ fill: '#a0a8c0', fontSize: 11 }}
          tickFormatter={v => {
            const s = String(v ?? '')
            return s.length > 22 ? s.slice(0, 20) + '…' : s
          }}
        />
        <Tooltip
          formatter={v => Number(v).toLocaleString()}
          labelFormatter={l => String(l)}
          contentStyle={tooltipStyle}
        />
        <Bar dataKey={yKey} radius={[0, 4, 4, 0]} maxBarSize={22}>
          {numericData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  )
}

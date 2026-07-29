import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { runSQL } from '../api/databricks'
import { DOMAIN_MAP } from '../queries/silver'
import { Users, ShoppingCart, BarChart3, FileText, Database } from 'lucide-react'

const DOMAIN_ICONS = {
  'Customer Analytics':  Users,
  'Product Analytics':   ShoppingCart,
  'Sales Analytics':     BarChart3,
  'Survey Analytics':    FileText,
  'Other Datasets':      Database,
}
const DOMAIN_COLORS = {
  'Customer Analytics':  'agent',
  'Product Analytics':   'bronze',
  'Sales Analytics':     'gold',
  'Survey Analytics':    'accent',
  'Other Datasets':      'silver',
}

function KpiCard({ label, value, color = 'gold' }) {
  const colorMap = { gold: 'text-gold', agent: 'text-agent', accent: 'text-accent', silver: 'text-silver' }
  return (
    <div className="bg-surface border border-border rounded-xl p-5">
      <div className={`text-3xl font-bold ${colorMap[color] || 'text-gold'}`}>
        {value ?? '…'}
      </div>
      <div className="text-sm text-muted mt-1">{label}</div>
    </div>
  )
}

export default function Home() {
  const [kpis, setKpis] = useState({})

  useEffect(() => {
    const queries = [
      ['customers',  `SELECT COUNT(*) AS n FROM dataingestionproject.silver.silver_v2_dim_customers`],
      ['products',   `SELECT COUNT(*) AS n FROM dataingestionproject.silver.silver_v2_dim_products`],
      ['orders',     `SELECT COUNT(DISTINCT order_number) AS n FROM dataingestionproject.silver.silver_v2_fact_sales`],
      ['revenue',    `SELECT ROUND(SUM(sales_amount)/1000000,1) AS n FROM dataingestionproject.silver.silver_v2_fact_sales`],
    ]
    queries.forEach(([key, sql]) => {
      runSQL(sql).then(rows => setKpis(prev => ({ ...prev, [key]: rows[0]?.n }))).catch(() => {})
    })
  }, [])

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <h1 className="text-2xl font-bold text-white mb-1">Pipeline Overview</h1>
      <p className="text-muted text-sm mb-6">Live analytics from the Databricks silver layer</p>

      {/* KPI row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <KpiCard label="Total Customers"    value={kpis.customers ? Number(kpis.customers).toLocaleString() : '…'} color="agent" />
        <KpiCard label="Total Products"     value={kpis.products  ? Number(kpis.products).toLocaleString()  : '…'} color="bronze" />
        <KpiCard label="Total Orders"       value={kpis.orders    ? Number(kpis.orders).toLocaleString()    : '…'} color="gold" />
        <KpiCard label="Revenue (M USD)"    value={kpis.revenue   ? `$${kpis.revenue}M`                    : '…'} color="accent" />
      </div>

      {/* Domain cards */}
      <h2 className="text-lg font-semibold text-white mb-4">Analytics Domains</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {Object.entries(DOMAIN_MAP).map(([domain, tables]) => {
          const Icon  = DOMAIN_ICONS[domain] || Database
          const color = DOMAIN_COLORS[domain] || 'silver'
          const colorMap = { agent: 'border-agent/40 text-agent', bronze: 'border-bronze/40 text-bronze',
                             gold: 'border-gold/40 text-gold', accent: 'border-accent/40 text-accent',
                             silver: 'border-silver/40 text-silver' }
          return (
            <Link key={domain} to={`/silver?domain=${encodeURIComponent(domain)}`}
                  className={`bg-surface border ${colorMap[color]?.split(' ')[0] || 'border-border'} rounded-xl p-5 hover:border-opacity-80 transition-all hover:scale-[1.01] block`}>
              <div className="flex items-center gap-3 mb-3">
                <Icon size={20} className={colorMap[color]?.split(' ')[1] || 'text-silver'} />
                <span className="font-semibold text-white">{domain}</span>
              </div>
              <div className="text-sm text-muted">{tables.length} silver table{tables.length > 1 ? 's' : ''}</div>
              <div className="mt-2 flex flex-wrap gap-1">
                {tables.map(t => (
                  <span key={t} className="text-xs bg-bg px-2 py-0.5 rounded text-muted">
                    {t.replace('silver_v2_', '')}
                  </span>
                ))}
              </div>
            </Link>
          )
        })}
      </div>
    </div>
  )
}

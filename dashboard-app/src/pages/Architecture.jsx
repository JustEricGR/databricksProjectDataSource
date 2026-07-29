import { Database, GitBranch, Cpu, BarChart3, Globe, Zap, Shield, RefreshCw } from 'lucide-react'

const BRONZE = '#cd7f32'
const SILVER = '#a0a8c0'
const GOLD   = '#f0b429'
const AGENT  = '#6e7bf0'
const ACCENT = '#4ac9ff'

function Section({ title, children }) {
  return (
    <div className="mb-10">
      <h2 className="text-xl font-bold text-white mb-4 border-b border-border pb-2">{title}</h2>
      {children}
    </div>
  )
}

function StepCard({ num, title, color, icon: Icon, items, badge }) {
  return (
    <div className="bg-surface border border-border rounded-xl overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-4 border-b border-border" style={{ borderLeftColor: color, borderLeftWidth: 4 }}>
        <div className="w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold text-bg"
             style={{ backgroundColor: color }}>{num}</div>
        {Icon && <Icon size={18} style={{ color }} />}
        <span className="font-semibold text-white">{title}</span>
        {badge && <span className="ml-auto text-xs px-2 py-0.5 rounded" style={{ background: color + '33', color }}>{badge}</span>}
      </div>
      <ul className="px-5 py-4 space-y-1.5">
        {items.map((item, i) => (
          <li key={i} className="text-sm text-muted flex items-start gap-2">
            <span style={{ color }} className="mt-0.5 shrink-0">▸</span>
            <span>{item}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}

function FlowArrow() {
  return <div className="flex justify-center items-center py-2 text-muted text-xl">↓</div>
}

function KpiRow({ items }) {
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
      {items.map(({ label, value, color }) => (
        <div key={label} className="bg-surface border border-border rounded-xl p-4 text-center">
          <div className="text-2xl font-bold" style={{ color }}>{value}</div>
          <div className="text-xs text-muted mt-1">{label}</div>
        </div>
      ))}
    </div>
  )
}

export default function Architecture() {
  return (
    <div className="p-6 max-w-6xl mx-auto">
      {/* Hero */}
      <div className="mb-10">
        <h1 className="text-3xl font-bold text-white mb-2">Pipeline Architecture</h1>
        <p className="text-muted max-w-3xl">
          End-to-end data platform on Databricks — from raw CSV files on GitHub through a
          Bronze → Silver → Gold medallion architecture, orchestrated by an AI agent and
          visualized in this React dashboard.
        </p>
      </div>

      {/* Key metrics */}
      <KpiRow items={[
        { label: 'Source CSV files',      value: '17+',   color: ACCENT  },
        { label: 'Silver tables',         value: '17',    color: SILVER  },
        { label: 'Gold summary views',    value: '20',    color: GOLD    },
        { label: 'Typical job time',      value: '~5 min',color: AGENT   },
      ]} />

      {/* End-to-end flow */}
      <Section title="End-to-End Data Flow">
        <div className="grid grid-cols-1 md:grid-cols-5 gap-3 items-center">
          {[
            { label: 'GitHub\nCSV Files', color: '#8b90a8', icon: GitBranch },
            { label: 'Bronze\nDLT Pipeline', color: BRONZE, icon: Database },
            { label: 'Silver\nDLT Pipeline', color: SILVER, icon: Database },
            { label: 'AI Agent\n(Llama 3.3)', color: AGENT,  icon: Cpu },
            { label: 'Gold Views\n+ React', color: GOLD,   icon: BarChart3 },
          ].map(({ label, color, icon: Icon }, i) => (
            <div key={i} className="flex md:contents items-center gap-2">
              <div className="flex-1 bg-surface border rounded-xl p-4 text-center" style={{ borderColor: color + '60' }}>
                <Icon size={22} className="mx-auto mb-2" style={{ color }} />
                <div className="text-xs font-medium text-white whitespace-pre-line leading-tight">{label}</div>
              </div>
              {i < 4 && <div className="hidden md:block text-muted text-xl px-1">→</div>}
            </div>
          ))}
        </div>
        <div className="mt-4 bg-surface border border-border rounded-lg px-4 py-2 text-sm text-muted">
          <span className="text-white font-medium">Databricks Job:</span>
          {' '}bronze → silver → ai_agent&nbsp;&nbsp;·&nbsp;&nbsp;Agent triggers gold selectively (only new views)
        </div>
      </Section>

      {/* Step by step */}
      <Section title="Step-by-Step Pipeline Explanation">
        <div className="space-y-3">

          <StepCard num="1" title="Data Ingestion — Bronze Layer" color={BRONZE} icon={Database}
            badge="DLT · incremental"
            items={[
              'GitHub Actions detects pushed CSV files in dataSource/ and triggers the Databricks job',
              'ingest.py fetches the file list from the GitHub Contents API (authenticated)',
              'Incremental mode: only new/changed CSVs are processed; existing bronze tables are skipped',
              'Full manual run: all CSVs checked — tables already in bronze are skipped automatically',
              'Each CSV is read with pandas (latin-1 encoding), Unnamed: columns dropped, BOM stripped',
              'A DLT @dp.table is registered per CSV → Unity Catalog: dataingestionproject.bronze',
              'Quota guard: stops if metastore reaches 490 objects (limit = 500)',
            ]}
          />

          <StepCard num="2" title="Data Cleaning — Silver Layer" color={SILVER} icon={Database}
            badge="DLT · materialized views"
            items={[
              'silver_transformations DLT pipeline reads from bronze and applies quality rules',
              'Date standardization: coalesces yyyy-MM-dd / MM/dd/yyyy / dd/MM/yyyy → dd/MM/yyyy',
              'Gender normalization: F/Female → "Female", M/Male → "Male", else NULL (rows filtered)',
              'String cleaning: trim + collapse whitespace on all string columns',
              'Null key filtering: rows with NULL in primary-key columns are dropped',
              'All views named silver_v2_<tablename> in dataingestionproject.silver',
              'DLT runs incrementally — only refreshes tables whose source data changed',
            ]}
          />

          <StepCard num="3" title="AI Agent — Smart Orchestrator" color={AGENT} icon={Cpu}
            badge="Llama 3.3 70B · Databricks Foundation Model"
            items={[
              'Step 1: Detects bronze tables with no silver counterpart → Llama generates @dp.materialized_view cleaning code → appends to silver notebook → triggers silver DLT refresh',
              'Step 2: Detects silver tables with no gold views → Llama generates 2-4 SQL views per table with quality validation (semicolons, unique names, no lateral alias in WINDOW ORDER BY)',
              'Step 2b: Cross-table join analysis — Llama checks if new tables share a key with existing gold views and suggests up to 2 join views',
              'Selective gold refresh: uses full_refresh_selection to refresh only newly added views (2-5) instead of all 20 → saves ~90% of gold refresh time',
              'Step 3: Smart-updates Lakeview dashboards (budget-capped: 8 widgets/domain, 30 total)',
              'Step 4: Commits updated silver/gold files back to GitHub automatically',
              'Early exit: if no new tables detected, exits in <5 seconds (zero wasted compute)',
            ]}
          />

          <StepCard num="4" title="Analytics — Hybrid Gold Architecture" color={GOLD} icon={BarChart3}
            badge="20 DLT summary views · React handles the rest"
            items={[
              'Only 20 key summary materialized views kept in DLT gold (was 80) → saves ~120 UC objects',
              'Each DLT materialized view = 2 Unity Catalog objects (the view + a managed backing table)',
              'Domains: Customer, Product, Sales, Survey — one summary view per domain plus KPI views',
              'Detailed analytics (breakdowns, time-series, rankings) live in React SQL queries',
              'This hybrid approach keeps the metastore at ~240 objects, well under the 500-table limit',
              'React queries silver tables directly via the Databricks SQL Warehouse REST API',
            ]}
          />

          <StepCard num="5" title="React Dashboard — This App" color={ACCENT} icon={Globe}
            badge="Vite · React 18 · Recharts · Vercel"
            items={[
              'Vite proxy (dev) / Vercel serverless function (prod) routes all API calls server-side — no CORS',
              'Reads from dataingestionproject.silver.* and dataingestionproject.gold.*',
              'Pre-defined queries for all 17 silver tables (bar, line, pie, area, table charts)',
              'Auto-detects new silver tables not in the query map and generates bar charts dynamically',
              'Overview KPIs (customers, products, orders, revenue) loaded on startup',
              'Domain filtering: Customer / Product / Sales / Survey / Other tabs in Silver Layer page',
              'Deployed to Vercel — auto-deploys on every push to main branch',
            ]}
          />
        </div>
      </Section>

      {/* Safeguards */}
      <Section title="Safeguards & Optimizations">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {[
            { icon: Shield, color: GOLD, title: 'Metastore Quota Guard',
              desc: 'Both bronze ingest and the AI agent check system.information_schema.tables at startup. If the count reaches 490 (limit = 500), the operation stops cleanly instead of crashing mid-run.' },
            { icon: Zap, color: AGENT, title: 'Selective Gold Refresh',
              desc: 'The agent uses full_refresh_selection to refresh only the 2-5 newly created views, not all 20. Reduces gold DLT execution from ~10 minutes to ~60 seconds.' },
            { icon: RefreshCw, color: SILVER, title: 'Incremental Bronze',
              desc: 'Tables already in bronze are skipped unconditionally. A full manual run with 17 existing tables exits in ~5 seconds instead of re-ingesting everything and hitting quota limits.' },
            { icon: GitBranch, color: ACCENT, title: 'GitHub Auto-Sync',
              desc: 'After the agent modifies silver transforms or gold SQL in the Databricks workspace, it commits those files back to GitHub via the API so the local repo stays in sync automatically.' },
          ].map(({ icon: Icon, color, title, desc }) => (
            <div key={title} className="bg-surface border border-border rounded-xl p-5">
              <div className="flex items-center gap-2 mb-2">
                <Icon size={16} style={{ color }} />
                <span className="font-semibold text-white text-sm">{title}</span>
              </div>
              <p className="text-sm text-muted leading-relaxed">{desc}</p>
            </div>
          ))}
        </div>
      </Section>

      {/* Timing */}
      <Section title="Job Timing">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-left">
                <th className="py-2 pr-6 text-muted font-medium">Task</th>
                <th className="py-2 pr-6 text-muted font-medium">Typical time</th>
                <th className="py-2 text-muted font-medium">Notes</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {[
                ['Bronze', '~30–70s', 'DLT cluster boot + only new CSVs ingested'],
                ['Silver', '~2 min',  'DLT incremental — skips unchanged tables'],
                ['AI Agent', '~2–6 min','Llama calls + selective gold refresh of 2-5 views'],
                ['Gold (inside agent)', '~60s', 'full_refresh_selection on new views only (not all 20)'],
                ['Total', '~5–10 min', 'vs ~18 min before optimization (≥60% reduction)'],
              ].map(([task, time, note]) => (
                <tr key={task} className={task === 'Total' ? 'font-semibold' : ''}>
                  <td className="py-2.5 pr-6 text-white">{task}</td>
                  <td className="py-2.5 pr-6" style={{ color: task === 'Total' ? GOLD : ACCENT }}>{time}</td>
                  <td className="py-2.5 text-muted">{note}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Section>

      {/* Tech stack */}
      <Section title="Technology Stack">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {[
            { label: 'Databricks DLT',        desc: 'Bronze & Silver pipelines' },
            { label: 'Unity Catalog',          desc: 'Table governance & quota' },
            { label: 'Llama 3.3 70B',          desc: 'AI transform generation' },
            { label: 'GitHub Actions',         desc: 'CI/CD & change detection' },
            { label: 'React 18 + Vite',        desc: 'Frontend framework' },
            { label: 'Recharts',               desc: 'Chart visualizations' },
            { label: 'TailwindCSS',            desc: 'Styling & dark theme' },
            { label: 'Vercel',                 desc: 'Hosting & serverless proxy' },
          ].map(({ label, desc }) => (
            <div key={label} className="bg-surface border border-border rounded-lg p-3">
              <div className="text-white text-sm font-medium">{label}</div>
              <div className="text-muted text-xs mt-0.5">{desc}</div>
            </div>
          ))}
        </div>
      </Section>
    </div>
  )
}

import { useState } from 'react'
import { ChevronLeft, ChevronRight, Maximize2 } from 'lucide-react'

const BRONZE = '#cd7f32'
const SILVER = '#a0a8c0'
const GOLD   = '#f0b429'
const AGENT  = '#6e7bf0'
const ACCENT = '#4ac9ff'
const MUTED  = '#8b90a8'
const BG     = '#0f1117'
const SURF   = '#1a1d27'

// ── Shared slide wrapper ──────────────────────────────────────────────────────
function Slide({ children, className = '' }) {
  return (
    <div className={`w-full h-full flex flex-col p-10 ${className}`}
         style={{ background: BG, minHeight: 0 }}>
      {children}
    </div>
  )
}

function Bar({ color = AGENT }) {
  return <div className="absolute left-0 top-0 bottom-0 w-2 rounded-r" style={{ background: color }} />
}

function Tag({ color, label }) {
  return (
    <span className="text-xs font-semibold px-3 py-1 rounded-full"
          style={{ background: color + '33', color }}>
      {label}
    </span>
  )
}

function Row({ items }) {
  return (
    <div className="grid gap-4" style={{ gridTemplateColumns: `repeat(${items.length},1fr)` }}>
      {items.map(({ val, lbl, color }) => (
        <div key={lbl} className="rounded-xl p-4 text-center" style={{ background: SURF, border: `1px solid ${color}33` }}>
          <div className="text-2xl font-bold" style={{ color }}>{val}</div>
          <div className="text-xs mt-1" style={{ color: MUTED }}>{lbl}</div>
        </div>
      ))}
    </div>
  )
}

// ── Slide 1 — Title ───────────────────────────────────────────────────────────
function Slide1() {
  return (
    <Slide className="relative justify-center">
      <Bar color={AGENT} />
      <div className="ml-6">
        <div className="text-5xl font-bold text-white leading-tight mb-3">
          DataProcessing Pipeline
        </div>
        <div className="text-3xl mb-6" style={{ color: SILVER }}>Architecture &amp; Data Flow</div>
        <div className="w-24 h-0.5 mb-6" style={{ background: AGENT }} />
        <div className="text-sm" style={{ color: MUTED }}>
          Databricks DLT &nbsp;·&nbsp; Unity Catalog &nbsp;·&nbsp; AI Agent &nbsp;·&nbsp; React Dashboard
        </div>
        <div className="mt-10 text-xs italic" style={{ color: MUTED }}>JustEricGR / databricksProjectDataSource</div>
      </div>
    </Slide>
  )
}

// ── Slide 2 — Pipeline Overview ───────────────────────────────────────────────
function Slide2() {
  const nodes = [
    { label: 'GitHub\nCSV Files',    color: MUTED   },
    { label: 'Bronze\nDLT Pipeline', color: BRONZE  },
    { label: 'Silver\nDLT Pipeline', color: SILVER  },
    { label: 'AI Agent\n(Llama 3.3)',color: AGENT   },
    { label: 'Gold\nDLT Views',      color: GOLD    },
    { label: 'React\nDashboard',     color: ACCENT  },
  ]
  return (
    <Slide>
      <h2 className="text-3xl font-bold text-white mb-1">End-to-End Pipeline Overview</h2>
      <div className="h-0.5 mb-6 w-full" style={{ background: '#2e3350' }} />

      <div className="flex items-center justify-between mb-6">
        {nodes.map((n, i) => (
          <div key={i} className="flex items-center">
            <div className="flex flex-col items-center">
              <div className="rounded-xl px-4 py-3 text-center text-sm font-bold whitespace-pre-line"
                   style={{ background: n.color + '22', border: `2px solid ${n.color}`, color: n.color, minWidth: 100 }}>
                {n.label}
              </div>
            </div>
            {i < nodes.length - 1 && (
              <div className="text-2xl mx-2 font-bold" style={{ color: MUTED }}>→</div>
            )}
          </div>
        ))}
      </div>

      <div className="rounded-lg px-4 py-2 text-sm mb-6"
           style={{ background: SURF, border: '1px solid #2e3350', color: MUTED }}>
        <span className="text-white font-medium">Databricks Job: </span>
        bronze → silver → ai_agent &nbsp;·&nbsp; Agent triggers selective gold refresh
      </div>

      <Row items={[
        { val: '17+', lbl: 'Source CSVs',      color: ACCENT  },
        { val: '17',  lbl: 'Silver Tables',    color: SILVER  },
        { val: '20',  lbl: 'Gold Views',       color: GOLD    },
        { val: '~5m', lbl: 'Typical Job Time', color: AGENT   },
        { val: '40',  lbl: 'Max Bronze Tables',color: BRONZE  },
        { val: '<500',lbl: 'UC Objects Used',  color: MUTED   },
      ]} />
    </Slide>
  )
}

// ── Slide 3 — Bronze ──────────────────────────────────────────────────────────
function Slide3() {
  const steps = [
    'GitHub Actions detects pushed CSV(s) in dataSource/ and triggers the Databricks job',
    'ingest.py fetches the file list from GitHub Contents API (authenticated via secret)',
    'Incremental mode: only new/changed CSVs processed — existing bronze tables skipped',
    'Full manual run: ALL CSVs checked — tables already in bronze are skipped automatically',
    'pandas.read_csv (latin-1) → drop Unnamed: columns → strip UTF-8 BOM from headers',
    '@dp.table decorator creates a DLT managed table per CSV in dataingestionproject.bronze',
    'Quota guards: stops if metastore ≥ 490 objects OR bronze tables ≥ 40',
  ]
  const safeguards = [
    ['Bronze table cap', '40 tables max (500-obj metastore limit)'],
    ['Multi-file push', 'Space-separated changed_files handled'],
    ['BOM stripping', 'ï»¿ prefix removed from column names'],
    ['Unnamed: columns', 'Pandas trailing empty columns dropped'],
  ]
  return (
    <Slide className="relative">
      <Bar color={BRONZE} />
      <div className="ml-4">
        <div className="flex items-center gap-3 mb-1">
          <h2 className="text-3xl font-bold text-white">Data Ingestion — Bronze Layer</h2>
          <Tag color={BRONZE} label="DLT · incremental" />
        </div>
        <div className="text-sm mb-4" style={{ color: MUTED }}>
          Pipeline: data_ingestion_git &nbsp;·&nbsp; dataingestionproject.bronze
        </div>
        <div className="h-px mb-4" style={{ background: '#2e3350' }} />
        <div className="grid grid-cols-2 gap-6">
          <div>
            <div className="text-sm font-bold mb-3" style={{ color: BRONZE }}>How It Works</div>
            <div className="space-y-2">
              {steps.map((s, i) => (
                <div key={i} className="flex gap-2 items-start">
                  <div className="shrink-0 w-5 h-5 rounded flex items-center justify-center text-xs font-bold mt-0.5"
                       style={{ background: BRONZE, color: BG }}>{i + 1}</div>
                  <div className="text-xs leading-relaxed" style={{ color: MUTED }}>{s}</div>
                </div>
              ))}
            </div>
          </div>
          <div>
            <div className="text-sm font-bold mb-3" style={{ color: BRONZE }}>Safeguards</div>
            <div className="space-y-2">
              {safeguards.map(([k, v]) => (
                <div key={k} className="rounded-lg p-3" style={{ background: SURF }}>
                  <div className="text-xs font-bold" style={{ color: GOLD }}>✓ {k}</div>
                  <div className="text-xs mt-0.5" style={{ color: MUTED }}>{v}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </Slide>
  )
}

// ── Slide 4 — Silver ──────────────────────────────────────────────────────────
function Slide4() {
  const rules = [
    { color: GOLD,   title: 'Date Standardization',   desc: 'standardize_date() — coalesces yyyy-MM-dd / MM/dd/yyyy / dd/MM/yyyy → dd/MM/yyyy' },
    { color: ACCENT, title: 'Gender Normalization',    desc: 'standardize_gender() — F/Female → "Female", M/Male → "Male", else NULL (rows dropped)' },
    { color: BRONZE, title: 'String Cleaning',         desc: 'clean_string() — F.trim(F.regexp_replace(col, r\'\\s+\', \' \')) on all string columns' },
    { color: AGENT,  title: 'Null Key Filtering',      desc: 'Rows with NULL in primary-key columns (id, key, number) are dropped' },
    { color: SILVER, title: 'AI-Generated Transforms', desc: 'New tables without a silver counterpart → Llama 3.3 generates @dp.materialized_view code' },
  ]
  return (
    <Slide className="relative">
      <Bar color={SILVER} />
      <div className="ml-4">
        <div className="flex items-center gap-3 mb-1">
          <h2 className="text-3xl font-bold text-white">Silver Transformations</h2>
          <Tag color={SILVER} label="DLT Materialized Views" />
        </div>
        <div className="text-sm mb-4" style={{ color: MUTED }}>
          Pipeline: silver_transformations &nbsp;·&nbsp; dataingestionproject.silver
        </div>
        <div className="h-px mb-4" style={{ background: '#2e3350' }} />
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-3">
            {rules.map(({ color, title, desc }) => (
              <div key={title} className="flex gap-3 items-start">
                <div className="w-1 shrink-0 rounded mt-1" style={{ background: color, height: 36 }} />
                <div>
                  <div className="text-xs font-bold" style={{ color }}>{title}</div>
                  <div className="text-xs mt-0.5 leading-relaxed" style={{ color: MUTED }}>{desc}</div>
                </div>
              </div>
            ))}
          </div>
          <div>
            <div className="text-sm font-bold mb-3" style={{ color: SILVER }}>Data Quality Impact</div>
            {[
              ['dim_customers',  '18,484 → 18,469', '15 null gender removed'],
              ['fact_sales',     '60,398 → 60,379', '19 bad dates removed'],
              ['dim_products',   '295 → 295',        'No issues found'],
            ].map(([tbl, change, note]) => (
              <div key={tbl} className="rounded-lg p-3 mb-2" style={{ background: SURF }}>
                <div className="text-xs font-medium text-white">{tbl}</div>
                <div className="text-sm font-bold mt-0.5" style={{ color: GOLD }}>{change}</div>
                <div className="text-xs" style={{ color: MUTED }}>{note}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Slide>
  )
}

// ── Slide 5 — AI Agent ────────────────────────────────────────────────────────
function Slide5() {
  const steps = [
    { num: '1',  color: BRONZE, title: 'Silver Gap Detection',
      desc: 'Finds bronze tables with no silver counterpart → calls Llama to write @dp.materialized_view cleaning code → appends to silver notebook → triggers silver DLT refresh' },
    { num: '2',  color: GOLD,   title: 'Gold Gap Detection',
      desc: 'Checks catalog + SQL file for uncovered silver tables → Llama generates 2-4 gold SQL views per table with quality validation (semicolons, TRY_CAST, no lateral alias, unique names)' },
    { num: '2b', color: ACCENT, title: 'Cross-Table Join Analysis',
      desc: 'Asks Llama if new tables share a key with existing gold views → suggests up to 2 cross-table analytical views (e.g. sales joined to customer demographics)' },
    { num: '3',  color: AGENT,  title: 'Selective Gold Refresh',
      desc: 'full_refresh_selection API refreshes ONLY the newly added views (2-5) instead of all 20 → reduces gold refresh from ~10 min to ~60 sec (90% time saving)' },
    { num: '4',  color: SILVER, title: 'GitHub Auto-Sync',
      desc: 'Exports updated silver notebook + gold SQL from Databricks workspace → commits to GitHub via API so the repo stays in sync automatically' },
  ]
  return (
    <Slide>
      <div className="flex items-center gap-3 mb-1">
        <h2 className="text-3xl font-bold text-white">AI Agent — Smart Orchestrator</h2>
        <Tag color={AGENT} label="Llama 3.3 70B" />
      </div>
      <div className="text-sm mb-4" style={{ color: MUTED }}>
        No external API key — Databricks Foundation Model API &nbsp;·&nbsp; Early exit if nothing new detected (&lt;5s)
      </div>
      <div className="h-px mb-4" style={{ background: '#2e3350' }} />
      <div className="grid grid-cols-2 gap-3">
        {steps.map(({ num, color, title, desc }) => (
          <div key={num} className="rounded-xl p-4" style={{ background: SURF, borderLeft: `4px solid ${color}` }}>
            <div className="flex items-center gap-2 mb-1">
              <div className="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold"
                   style={{ background: color, color: BG }}>{num}</div>
              <span className="text-sm font-semibold" style={{ color }}>{title}</span>
            </div>
            <div className="text-xs leading-relaxed" style={{ color: MUTED }}>{desc}</div>
          </div>
        ))}
      </div>
    </Slide>
  )
}

// ── Slide 6 — Gold ────────────────────────────────────────────────────────────
function Slide6() {
  const domains = [
    { name: 'Customer Analytics', color: AGENT,  views: ['gold_customer_summary','gold_customer_demographics','gold_customers_by_country','gold_customer_lifetime_value','gold_top_customers'] },
    { name: 'Product Analytics',  color: BRONZE, views: ['gold_product_summary','gold_products_by_category','gold_fact_sales_summary','gold_top_products'] },
    { name: 'Sales Analytics',    color: GOLD,   views: ['gold_monthly_sales','gold_sales_by_country','gold_sales_by_category','gold_order_fulfillment'] },
    { name: 'Survey Analytics',   color: ACCENT, views: ['gold_enterprise_survey_by_industry','gold_business_finance_2022_by_industry','gold_climate_2023_by_industry','+ new table summaries'] },
  ]
  return (
    <Slide>
      <div className="flex items-center gap-3 mb-1">
        <h2 className="text-3xl font-bold text-white">Gold Analytics Layer</h2>
        <Tag color={GOLD} label="20 Summary Views · Hybrid Architecture" />
      </div>
      <div className="text-sm mb-4" style={{ color: MUTED }}>
        DLT keeps only 20 key summary views — React handles detailed analytics directly from silver
      </div>
      <div className="h-px mb-4" style={{ background: '#2e3350' }} />
      <div className="grid grid-cols-2 gap-4">
        {domains.map(({ name, color, views }) => (
          <div key={name} className="rounded-xl overflow-hidden" style={{ background: SURF }}>
            <div className="px-4 py-2 text-sm font-bold" style={{ background: color + '33', color }}>
              {name}
            </div>
            <div className="px-4 py-3 space-y-1">
              {views.map(v => (
                <div key={v} className="text-xs flex items-center gap-1.5" style={{ color: MUTED }}>
                  <span style={{ color }}>▸</span> {v}
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
      <div className="mt-4 text-xs text-center" style={{ color: MUTED }}>
        Selective refresh: only newly added views refreshed per run &nbsp;·&nbsp; UC quota guard: stops at 490 objects
      </div>
    </Slide>
  )
}

// ── Slide 7 — Performance ─────────────────────────────────────────────────────
function Slide7() {
  const timing = [
    ['Bronze',             '~120s', '~30-70s', BRONZE],
    ['Silver',             '~172s', '~2 min',  SILVER],
    ['AI Agent + Gold',    '~775s', '~2-6 min',AGENT ],
    ['Total',              '~18 min','~5-10 min',GOLD ],
  ]
  const decisions = [
    { color: GOLD,   title: 'Selective gold refresh', desc: 'full_refresh_selection: only 2-5 new views, not all 20 → saves ~90% of gold time' },
    { color: AGENT,  title: 'Agent controls gold',    desc: 'Gold DLT task removed from job; agent triggers internally and waits for completion' },
    { color: BRONZE, title: 'Incremental bronze',     desc: 'Existing tables skipped — full manual run completes in ~5s instead of 14+ minutes' },
    { color: SILVER, title: 'Early exit',             desc: 'Agent exits in <5s if no new tables detected — zero wasted compute' },
    { color: MUTED,  title: 'Metastore quota guard',  desc: 'Both bronze and agent check system.information_schema.tables before creating objects' },
    { color: ACCENT, title: 'Hybrid gold + React',    desc: 'DLT keeps 20 summaries; React queries silver directly for all detailed analytics' },
  ]
  return (
    <Slide>
      <h2 className="text-3xl font-bold text-white mb-1">Performance &amp; Architecture Decisions</h2>
      <div className="h-px mb-4" style={{ background: '#2e3350' }} />
      <div className="grid grid-cols-2 gap-6">
        <div>
          <div className="text-sm font-bold mb-3" style={{ color: ACCENT }}>Job Timing — Before vs After</div>
          <table className="w-full text-xs">
            <thead>
              <tr style={{ color: MUTED }}>
                <th className="text-left py-1 pr-4">Task</th>
                <th className="text-left py-1 pr-4">Before</th>
                <th className="text-left py-1">After</th>
              </tr>
            </thead>
            <tbody>
              {timing.map(([task, before, after, color]) => (
                <tr key={task} className="border-t" style={{ borderColor: '#2e3350' }}>
                  <td className="py-1.5 pr-4 font-medium" style={{ color: task === 'Total' ? WHITE : '#e8eaf0' }}>{task}</td>
                  <td className="py-1.5 pr-4" style={{ color: MUTED }}>{before}</td>
                  <td className="py-1.5 font-bold" style={{ color: task === 'Total' ? GOLD : color }}>{after}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="mt-3 rounded-lg px-3 py-2 text-xs" style={{ background: GOLD + '22', color: GOLD }}>
            ≥60% total time reduction
          </div>
        </div>
        <div>
          <div className="text-sm font-bold mb-3" style={{ color: ACCENT }}>Key Architecture Decisions</div>
          <div className="space-y-2">
            {decisions.map(({ color, title, desc }) => (
              <div key={title} className="flex gap-2 items-start">
                <div className="w-1 shrink-0 rounded mt-1" style={{ background: color, height: 32 }} />
                <div>
                  <div className="text-xs font-bold" style={{ color }}>{title}</div>
                  <div className="text-xs" style={{ color: MUTED }}>{desc}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Slide>
  )
}

const WHITE = '#ffffff'
const SLIDES = [
  { title: 'Title',             Component: Slide1 },
  { title: 'Pipeline Overview', Component: Slide2 },
  { title: 'Bronze Layer',      Component: Slide3 },
  { title: 'Silver Layer',      Component: Slide4 },
  { title: 'AI Agent',          Component: Slide5 },
  { title: 'Gold Layer',        Component: Slide6 },
  { title: 'Performance',       Component: Slide7 },
]

export default function Presentation() {
  const [current, setCurrent] = useState(0)
  const [fullscreen, setFullscreen] = useState(false)

  const prev = () => setCurrent(i => Math.max(0, i - 1))
  const next = () => setCurrent(i => Math.min(SLIDES.length - 1, i + 1))

  const { Component } = SLIDES[current]

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h1 className="text-2xl font-bold text-white">Pipeline Presentation</h1>
          <p className="text-sm" style={{ color: MUTED }}>Slide {current + 1} of {SLIDES.length} — {SLIDES[current].title}</p>
        </div>
        <div className="flex gap-2">
          {SLIDES.map((s, i) => (
            <button key={i} onClick={() => setCurrent(i)}
                    className="w-2.5 h-2.5 rounded-full transition-all"
                    style={{ background: i === current ? AGENT : '#2e3350' }}
                    title={s.title} />
          ))}
        </div>
      </div>

      {/* Slide canvas — 16:9 aspect ratio */}
      <div className="relative w-full rounded-2xl overflow-hidden shadow-2xl"
           style={{ aspectRatio: '16/9', border: '1px solid #2e3350' }}>
        <Component />
      </div>

      {/* Navigation */}
      <div className="flex items-center justify-between mt-4">
        <button onClick={prev} disabled={current === 0}
                className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all disabled:opacity-30"
                style={{ background: SURF, color: WHITE }}>
          <ChevronLeft size={16} /> Previous
        </button>

        {/* Slide thumbnails */}
        <div className="flex gap-1 text-xs" style={{ color: MUTED }}>
          {SLIDES.map((s, i) => (
            <button key={i} onClick={() => setCurrent(i)}
                    className="px-2 py-1 rounded transition-all"
                    style={{ background: i === current ? AGENT + '33' : 'transparent',
                             color: i === current ? AGENT : MUTED }}>
              {i + 1}
            </button>
          ))}
        </div>

        <button onClick={next} disabled={current === SLIDES.length - 1}
                className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all disabled:opacity-30"
                style={{ background: SURF, color: WHITE }}>
          Next <ChevronRight size={16} />
        </button>
      </div>

      {/* Keyboard hint */}
      <p className="text-center text-xs mt-3" style={{ color: MUTED }}>
        Use the arrows or click the slide numbers to navigate
      </p>
    </div>
  )
}

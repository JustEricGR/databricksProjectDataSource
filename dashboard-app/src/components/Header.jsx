import { Link, useLocation } from 'react-router-dom'
import { Database, LayoutDashboard, Table2, GitBranch, MonitorPlay } from 'lucide-react'

export default function Header() {
  const loc = useLocation()
  const active = (path) =>
    loc.pathname === path
      ? 'text-accent border-b-2 border-accent'
      : 'text-muted hover:text-silver'

  return (
    <header className="bg-surface border-b border-border px-6 py-3 flex items-center gap-6 sticky top-0 z-50">
      <div className="flex items-center gap-2 shrink-0">
        <Database className="text-agent" size={20} />
        <span className="font-semibold text-white">Databricks Analytics</span>
      </div>
      <nav className="flex gap-5 ml-6">
        <Link to="/"             className={`flex items-center gap-1 pb-1 text-sm font-medium transition-colors ${active('/')}`}>
          <LayoutDashboard size={14} /> Overview
        </Link>
        <Link to="/silver"       className={`flex items-center gap-1 pb-1 text-sm font-medium transition-colors ${active('/silver')}`}>
          <Table2 size={14} /> Silver Layer
        </Link>
        <Link to="/gold"         className={`flex items-center gap-1 pb-1 text-sm font-medium transition-colors ${active('/gold')}`}>
          <Table2 size={14} /> Gold Summaries
        </Link>
        <Link to="/architecture" className={`flex items-center gap-1 pb-1 text-sm font-medium transition-colors ${active('/architecture')}`}>
          <GitBranch size={14} /> Architecture
        </Link>
        <Link to="/presentation" className={`flex items-center gap-1 pb-1 text-sm font-medium transition-colors ${active('/presentation')}`}>
          <MonitorPlay size={14} /> Slides
        </Link>
      </nav>
      <div className="ml-auto flex items-center gap-2">
        <span className="w-2 h-2 rounded-full bg-green-400 animate-pulse" />
        <span className="text-xs text-muted">Live</span>
      </div>
    </header>
  )
}

import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Header       from './components/Header'
import Home         from './pages/Home'
import Silver       from './pages/Silver'
import Gold         from './pages/Gold'
import Architecture from './pages/Architecture'
import Presentation from './pages/Presentation'

export default function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen bg-bg text-white">
        <Header />
        <Routes>
          <Route path="/"              element={<Home />} />
          <Route path="/silver"        element={<Silver />} />
          <Route path="/gold"          element={<Gold />} />
          <Route path="/architecture"  element={<Architecture />} />
          <Route path="/presentation"  element={<Presentation />} />
        </Routes>
      </div>
    </BrowserRouter>
  )
}

// Vercel serverless function — proxies /proxy/* requests to Databricks server-side.
// This eliminates CORS because the call is made from Vercel's servers, not the browser.
export default async function handler(req, res) {
  const host  = process.env.VITE_DATABRICKS_HOST
  const token = process.env.VITE_DATABRICKS_TOKEN

  if (!host || !token) {
    res.status(500).json({ error: 'Missing VITE_DATABRICKS_HOST or VITE_DATABRICKS_TOKEN env vars' })
    return
  }

  const path   = req.url.replace(/^\/proxy/, '') || '/'
  const target = `${host}${path}`

  const upstream = await fetch(target, {
    method:  req.method,
    headers: {
      Authorization:  `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: req.method !== 'GET' && req.method !== 'HEAD'
            ? JSON.stringify(req.body)
            : undefined,
  })

  const body = await upstream.text()
  res.status(upstream.status)
  res.setHeader('Content-Type', upstream.headers.get('content-type') || 'application/json')
  res.end(body)
}

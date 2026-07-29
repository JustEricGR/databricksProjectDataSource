// Vercel serverless proxy — forwards /proxy/* to Databricks (no CORS).
// Requires env vars: VITE_DATABRICKS_HOST and VITE_DATABRICKS_TOKEN

export const config = { api: { bodyParser: true } }

export default async function handler(req, res) {
  const host  = process.env.VITE_DATABRICKS_HOST
  const token = process.env.VITE_DATABRICKS_TOKEN

  // Diagnose missing env vars clearly
  if (!host) {
    res.status(500).json({ error: 'VITE_DATABRICKS_HOST environment variable is not set in Vercel.' })
    return
  }
  if (!token) {
    res.status(500).json({ error: 'VITE_DATABRICKS_TOKEN environment variable is not set in Vercel.' })
    return
  }

  // Strip /proxy prefix to get the actual Databricks path
  const path   = req.url.replace(/^\/proxy/, '') || '/'
  const target = `${host.replace(/\/$/, '')}${path}`

  try {
    const upstream = await fetch(target, {
      method:  req.method,
      headers: {
        Authorization:  `Bearer ${token}`,
        'Content-Type': 'application/json',
        Accept:         'application/json',
      },
      // body is already parsed as object by Vercel; re-stringify it
      body: ['POST', 'PUT', 'PATCH'].includes(req.method)
              ? JSON.stringify(req.body ?? {})
              : undefined,
    })

    const text = await upstream.text()
    res.status(upstream.status)
    res.setHeader('Content-Type', upstream.headers.get('content-type') || 'application/json')
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.end(text)
  } catch (err) {
    res.status(500).json({
      error:   'Proxy failed to reach Databricks',
      details: err.message,
      target,
    })
  }
}

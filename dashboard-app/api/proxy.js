export const config = { api: { bodyParser: true } }

export default async function handler(req, res) {
  const host  = process.env.VITE_DATABRICKS_HOST
  const token = process.env.VITE_DATABRICKS_TOKEN

  if (!host) {
    res.status(500).json({ error: 'VITE_DATABRICKS_HOST not set in Vercel environment variables.' })
    return
  }
  if (!token) {
    res.status(500).json({ error: 'VITE_DATABRICKS_TOKEN not set in Vercel environment variables.' })
    return
  }

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
    res.status(500).json({ error: 'Proxy error', details: err.message, target })
  }
}

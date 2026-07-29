// Vercel serverless function — proxies all /proxy/* requests to Databricks.
// Runs server-side so there is no CORS issue.
export default async function handler(req, res) {
  const databricksHost  = process.env.VITE_DATABRICKS_HOST
  const databricksToken = process.env.VITE_DATABRICKS_TOKEN

  // Strip the /proxy prefix to get the real Databricks path
  const path   = req.url.replace(/^\/proxy/, '') || '/'
  const target = `${databricksHost}${path}`

  const headers = {
    Authorization:  `Bearer ${databricksToken}`,
    'Content-Type': 'application/json',
  }

  const upstream = await fetch(target, {
    method:  req.method,
    headers,
    body:    req.method !== 'GET' && req.method !== 'HEAD'
               ? JSON.stringify(req.body)
               : undefined,
  })

  const body = await upstream.text()
  res.status(upstream.status)
  res.setHeader('Content-Type', upstream.headers.get('content-type') || 'application/json')
  res.end(body)
}

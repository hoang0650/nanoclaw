/**
 * Aimarkets edge for NanoClaw dashboard:
 * - GET /login?token=&autoLogin=&next=  → set cookie, redirect
 * - Proxy /dashboard and /api/* to upstream with Authorization: Bearer
 *
 * Env:
 *   PORT=3200
 *   DASHBOARD_UPSTREAM=http://127.0.0.1:3100
 *   DASHBOARD_SECRET=<same as NanoClaw DASHBOARD_SECRET / API NANOCLAW_DASHBOARD_SECRET>
 *   COOKIE_NAME=nc_aimarkets_token
 */
const http = require('http');
const https = require('https');
const { URL } = require('url');

const PORT = Number(process.env.PORT || 3200);
const UPSTREAM = String(process.env.DASHBOARD_UPSTREAM || 'http://127.0.0.1:3100').replace(
  /\/$/,
  '',
);
const EXPECTED = String(process.env.DASHBOARD_SECRET || '').trim();
const COOKIE = String(process.env.COOKIE_NAME || 'nc_aimarkets_token');

function parseCookies(header) {
  const out = {};
  String(header || '')
    .split(';')
    .forEach((part) => {
      const i = part.indexOf('=');
      if (i < 0) return;
      const k = part.slice(0, i).trim();
      const v = part.slice(i + 1).trim();
      if (k) out[k] = decodeURIComponent(v);
    });
  return out;
}

function loginPage({ token, nextPath, error }) {
  const safeNext = nextPath || '/dashboard';
  const safeToken = token || '';
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>NanoClaw · AI Markets</title>
  <style>
    :root { color-scheme: light; --ink:#0f172a; --muted:#64748b; --accent:#0d9488; --bg:#f0fdfa; }
    * { box-sizing: border-box; }
    body { margin:0; min-height:100vh; font-family: "Segoe UI", system-ui, sans-serif;
      background: radial-gradient(1200px 600px at 10% -10%, #ccfbf1, transparent),
                  linear-gradient(160deg, #f8fafc, var(--bg));
      color: var(--ink); display:grid; place-items:center; padding:24px; }
    form { width:min(420px,100%); background:#fff; border:1px solid #e2e8f0; border-radius:16px;
      padding:28px 24px; box-shadow: 0 18px 50px rgba(15,23,42,.08); }
    h1 { margin:0 0 6px; font-size:1.35rem; letter-spacing:-.02em; }
    p { margin:0 0 18px; color:var(--muted); font-size:.95rem; line-height:1.45; }
    label { display:block; font-size:.8rem; font-weight:600; margin:0 0 6px; }
    input { width:100%; padding:12px 14px; border:1px solid #cbd5e1; border-radius:10px; font-size:1rem; }
    button { margin-top:16px; width:100%; padding:12px 14px; border:0; border-radius:10px;
      background:var(--accent); color:#fff; font-weight:600; font-size:1rem; cursor:pointer; }
    .err { color:#b91c1c; font-size:.85rem; margin:0 0 12px; }
  </style>
</head>
<body>
  <form method="POST" action="/login" id="f">
    <h1>NanoClaw</h1>
    <p>AI Markets dashboard — sign in with your Launch token.</p>
    ${error ? `<p class="err">${error}</p>` : ''}
    <label for="token">Dashboard token</label>
    <input id="token" name="token" type="password" autocomplete="current-password" value="${safeToken.replace(/"/g, '&quot;')}" required />
    <input type="hidden" name="next" value="${safeNext.replace(/"/g, '&quot;')}" />
    <button type="submit">Continue</button>
  </form>
  <script>
    (function () {
      var params = new URLSearchParams(location.search);
      var token = params.get('token') || '';
      var auto = /^(1|true|yes)$/i.test(String(params.get('autoLogin') || ''));
      var next = params.get('next') || '/dashboard';
      var input = document.getElementById('token');
      if (token && input && !input.value) input.value = token;
      if (auto && token) {
        var form = document.getElementById('f');
        var nextInput = form.querySelector('input[name="next"]');
        if (nextInput) nextInput.value = next;
        form.submit();
      }
    })();
  </script>
</body>
</html>`;
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

function proxy(req, res, token) {
  const target = new URL(req.url, UPSTREAM);
  const lib = target.protocol === 'https:' ? https : http;
  const headers = { ...req.headers, host: target.host };
  if (token) headers.authorization = `Bearer ${token}`;
  delete headers['content-length'];

  const upstream = lib.request(
    target,
    { method: req.method, headers },
    (up) => {
      res.writeHead(up.statusCode || 502, up.headers);
      up.pipe(res);
    },
  );
  upstream.on('error', (err) => {
    res.writeHead(502, { 'content-type': 'text/plain; charset=utf-8' });
    res.end(`Upstream error: ${err.message}`);
  });
  req.pipe(upstream);
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  const cookies = parseCookies(req.headers.cookie);
  const cookieToken = String(cookies[COOKIE] || '').trim();

  if (url.pathname === '/login' && req.method === 'GET') {
    const token = String(url.searchParams.get('token') || '');
    const nextPath = String(url.searchParams.get('next') || '/dashboard');
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    res.end(loginPage({ token, nextPath }));
    return;
  }

  if (url.pathname === '/login' && req.method === 'POST') {
    const raw = (await readBody(req)).toString('utf8');
    const params = new URLSearchParams(raw);
    const token = String(params.get('token') || '').trim();
    const nextPath = String(params.get('next') || '/dashboard');
    if (!token) {
      res.writeHead(400, { 'content-type': 'text/html; charset=utf-8' });
      res.end(loginPage({ token: '', nextPath, error: 'Token is required.' }));
      return;
    }
    if (EXPECTED && token !== EXPECTED) {
      res.writeHead(401, { 'content-type': 'text/html; charset=utf-8' });
      res.end(loginPage({ token: '', nextPath, error: 'Invalid dashboard token.' }));
      return;
    }
    const secure = String(req.headers['x-forwarded-proto'] || '').includes('https') || false;
    res.writeHead(302, {
      location: nextPath.startsWith('/') ? nextPath : '/dashboard',
      'set-cookie': `${COOKIE}=${encodeURIComponent(token)}; Path=/; HttpOnly; SameSite=Lax${secure ? '; Secure' : ''}`,
    });
    res.end();
    return;
  }

  if (url.pathname === '/' || url.pathname === '') {
    res.writeHead(302, { location: cookieToken ? '/dashboard' : '/login' });
    res.end();
    return;
  }

  if (!cookieToken && EXPECTED) {
    const next = encodeURIComponent(url.pathname + url.search);
    res.writeHead(302, { location: `/login?next=${next}` });
    res.end();
    return;
  }

  proxy(req, res, cookieToken || EXPECTED);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[nanoclaw-aimarkets-proxy] :${PORT} → ${UPSTREAM}`);
});

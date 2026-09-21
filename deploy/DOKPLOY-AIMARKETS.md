# NanoClaw on AI Markets

Public Launch = **`https://{userId}.nanoclaw.aimarkets.vn`** (cùng pattern Hermes/OpenClaw).  
Apex `nanoclaw.aimarkets.vn` chỉ health/shared.  
Không dùng `*.tunnel.phgrouptechs.com` hay ProxVN làm Launch host.

**Deploy:** [DOKPLOY.md](./DOKPLOY.md) · Traefik: `dokploy-dynamic-nanoclaw-aimarkets-wildcard.yml`

## Kiến trúc

```
Buyer browser
    → https://{userId}.nanoclaw.aimarkets.vn/dashboard?session=market-{userId}…
    → Traefik → aimarketplace-nanoclaw:3100
```

- **Mức 1:** dashboard-only ([DOKPLOY.md](./DOKPLOY.md))
- **Mức 2:** full host + Docker socket + pusher ([DOKPLOY-LEVEL2.md](./DOKPLOY-LEVEL2.md))

## API env (`aimarketplace-api`)

```env
NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://{userId}.nanoclaw.aimarkets.vn
NANOCLAW_SSH_HOST_TEMPLATE={userId}.nanoclaw.aimarkets.vn
NANOCLAW_DASHBOARD_SECRET=<same as DASHBOARD_SECRET>
```

## Launch

`POST /v1/nanoclaw/launch` →  
`https://{userId}.nanoclaw.aimarkets.vn/dashboard?session=market-{userId}&audience=aimarkets…#token=…`

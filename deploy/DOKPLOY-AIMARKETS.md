# NanoClaw on AI Markets

Public Launch = **[https://nanoclaw.aimarkets.vn](https://nanoclaw.aimarkets.vn/)** (Traefik → NanoClaw `:3100`).  
Wildcard: **`*.nanoclaw.aimarkets.vn`** (SSH / per-user hosts).  
Không dùng `*.tunnel.phgrouptechs.com` hay `*.bacsycay.click`.

ProxVN Control Center (nếu cần): https://proxvn.phgrouptechs.com

**Deploy:** [DOKPLOY.md](./DOKPLOY.md) · Traefik file: `dokploy-dynamic-nanoclaw-aimarkets-wildcard.yml`

## Kiến trúc

```
Buyer browser
    → https://nanoclaw.aimarkets.vn/dashboard?session=market-{userId}…
    → Traefik → aimarketplace-nanoclaw:3100
```

## API env (`aimarketplace-api`)

```env
NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://nanoclaw.aimarkets.vn
NANOCLAW_SSH_HOST_TEMPLATE={userId}.nanoclaw.aimarkets.vn
NANOCLAW_DASHBOARD_SECRET=<same as DASHBOARD_SECRET>
```

## Launch

`POST /v1/nanoclaw/launch` →  
`https://nanoclaw.aimarkets.vn/dashboard?session=market-{userId}&audience=aimarkets…#token=…`

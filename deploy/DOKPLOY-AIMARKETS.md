# NanoClaw on AI Markets (aimarkets.vn)

## DNS (Mắt Bão)

| Host | Type | Value |
|------|------|-------|
| `nanoclaw` | A | `72.62.72.165` |
| `*.nanoclaw` | A | `72.62.72.165` |

## Launch flow (Hermes-style)

Marketplace `POST /v1/nanoclaw/launch` →

`https://{userId}.nanoclaw.aimarkets.vn/login?token=…&autoLogin=true&next=/dashboard?session=market-{userId}…`

The **aimarkets-proxy** (`deploy/aimarkets-proxy`) sets an HttpOnly cookie and proxies `/dashboard` + `/api/*` to `@nanoco/nanoclaw-dashboard` with `Authorization: Bearer`.

## Dokploy apps

1. **NanoClaw host** — run NanoClaw + dashboard (`DASHBOARD_PORT=3100`, `DASHBOARD_SECRET=<shared>`).
2. **aimarkets-proxy** — image from `deploy/aimarkets-proxy`, port **3200**:
   ```env
   PORT=3200
   DASHBOARD_UPSTREAM=http://<nanoclaw-dashboard-service>:3100
   DASHBOARD_SECRET=<same shared secret>
   ```
3. Traefik file: `deploy/dokploy-dynamic-nanoclaw-aimarkets-wildcard.yml` → proxy `:3200`.

## API env (`aimarketplace-api`)

```env
NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://{userId}.nanoclaw.aimarkets.vn
NANOCLAW_SSH_HOST_TEMPLATE={userId}.nanoclaw.aimarkets.vn
NANOCLAW_DASHBOARD_SECRET=<same as DASHBOARD_SECRET>
```

Must match OpenClaw/Hermes pattern: Launch embeds the shared secret; wrong/missing secret → login 401.

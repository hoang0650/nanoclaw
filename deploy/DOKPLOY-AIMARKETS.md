# NanoClaw on AI Markets via ProxVN

Public edge = **[https://proxvn.phgrouptechs.com](https://proxvn.phgrouptechs.com/)** (`proxvn_tunnel_full`) — không dùng `*.bacsycay.click`.

## Kiến trúc

```
Buyer browser
    → https://proxvn.phgrouptechs.com/dashboard?session=market-{userId}…
    → ProxVN → localhost:3100 (NanoClaw dashboard)
```

## Chạy tunnel (máy/VPS chạy NanoClaw)

```bash
# Dashboard NanoClaw listen :3100 — trỏ client về server ProxVN của bạn
proxvn --server <PROXVN_HOST>:8882 --proto http 3100 --id nanoclaw-aimarkets --ui=false
```

Cấu hình server ProxVN (`HTTP_DOMAIN` / landing) phải phục vụ app trên **proxvn.phgrouptechs.com** (không cấp subdomain bacsycay.click cho Aimarkets).

## API env (`aimarketplace-api`)

```env
NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://proxvn.phgrouptechs.com
NANOCLAW_SSH_HOST_TEMPLATE={userId}.nanoclaw.aimarkets.vn
# Optional — khi dashboard bật DASHBOARD_SECRET
NANOCLAW_DASHBOARD_SECRET=<same as DASHBOARD_SECRET>
# Optional — expose aimarkets-proxy :3200 thay vì dashboard :3100
# NANOCLAW_USE_LOGIN_PROXY=1
```

## Launch

`POST /v1/nanoclaw/launch` →

- Mặc định: `https://proxvn.phgrouptechs.com/dashboard?session=market-{userId}&audience=aimarkets…#token=…`
- `NANOCLAW_USE_LOGIN_PROXY=1`: `…/login?token&autoLogin&next=/dashboard…`

## aimarkets-proxy (tuỳ chọn)

Chỉ khi cần cookie → `Authorization: Bearer`. Vẫn public qua cùng host ProxVN.

## Traefik `*.nanoclaw.aimarkets.vn`

Không bắt buộc. Xem `dokploy-dynamic-nanoclaw-aimarkets-wildcard.yml` nếu vẫn muốn DNS Aimarkets.

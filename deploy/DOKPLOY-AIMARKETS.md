# NanoClaw on AI Markets via ProxVN

Public edge = **[ProxVN](https://proxvn.phgrouptechs.com/)** (`proxvn_tunnel_full`) — không cần Traefik `*.nanoclaw.aimarkets.vn` hay custom Node proxy làm mặc định.

ProxVN cấp HTTPS subdomain (vd `https://abc123.bacsycay.click`) trỏ về process local. Landing/docs: https://proxvn.phgrouptechs.com/

## Kiến trúc

```
Buyer browser
    → https://{sub}.bacsycay.click     (ProxVN server bạn đã host)
    → tunnel → localhost:3100          (NanoClaw dashboard)
```

Tuỳ chọn Bearer login bridge: tunnel **port 3200** (aimarkets-proxy) thay vì 3100, rồi set `NANOCLAW_USE_LOGIN_PROXY=1` trên API.

## Chạy tunnel (máy/VPS chạy NanoClaw)

Server công cộng (hoặc self-host): xem [proxvn.phgrouptechs.com](https://proxvn.phgrouptechs.com/)

```bash
# Dashboard NanoClaw đang listen :3100
proxvn --server 103.77.246.196:8882 --proto http 3100 --id nanoclaw-aimarkets --ui=false
# → Public URL: https://<sub>.bacsycay.click
```

Ghi URL đó vào API:

```env
# Shared tunnel (một URL cho mọi buyer) — khuyến nghị lúc đầu
NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://<sub>.bacsycay.click

# Hoặc per-buyer nếu bạn reserve subdomain = Mongo userId trên ProxVN
# NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://{userId}.bacsycay.click
```

## API env (`aimarketplace-api`)

```env
NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://<sub>.bacsycay.click
NANOCLAW_SSH_HOST_TEMPLATE={userId}.nanoclaw.aimarkets.vn
# Optional — chỉ khi dashboard bật DASHBOARD_SECRET
NANOCLAW_DASHBOARD_SECRET=<same as DASHBOARD_SECRET>
# Optional — tunnel aimarkets-proxy :3200 thay vì dashboard :3100
# NANOCLAW_USE_LOGIN_PROXY=1
```

## Launch

`POST /v1/nanoclaw/launch` →

- Mặc định: `https://<proxvn>/dashboard?session=market-{userId}&audience=aimarkets…#token=…`
- `NANOCLAW_USE_LOGIN_PROXY=1`: `…/login?token&autoLogin&next=/dashboard…`

## aimarkets-proxy (tuỳ chọn)

Thư mục `deploy/aimarkets-proxy` chỉ cần khi muốn cookie → `Authorization: Bearer`. Public vẫn qua ProxVN:

```bash
# proxy :3200 → dashboard :3100
node deploy/aimarkets-proxy/server.js
proxvn --proto http 3200 --id nanoclaw-login
```

## Traefik `*.nanoclaw.aimarkets.vn`

Không bắt buộc nữa. File `dokploy-dynamic-nanoclaw-aimarkets-wildcard.yml` giữ cho ai vẫn muốn DNS Aimarkets thay vì ProxVN.

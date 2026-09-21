# Deploy NanoClaw trên Dokploy (AI Markets)

Dokploy: `deploy.phgrouptechs.com` · VPS `72.62.72.165`  
Public Launch: **`https://{userId}.nanoclaw.aimarkets.vn`** (giống Hermes/OpenClaw)  
Apex: `nanoclaw.aimarkets.vn` · Wildcard DNS: `*.nanoclaw`  
Không dùng `*.tunnel.phgrouptechs.com` / ProxVN làm Launch host.

Có **2 mức** deploy. Aimarkets Launch chỉ cần **mức 1**.

---

## Mức 1 — Dashboard only (khuyến nghị lúc đầu)

Buyer mở Launch → dashboard monitoring. Chưa chạy agent container.

### 1. Tạo Application trên Dokploy

| Field | Value |
|--------|--------|
| Source | GitHub `hoang0650/nanoclaw` · branch `main` |
| Build type | **Dockerfile** |
| **Docker File** | `Dockerfile` (ở root repo) |
| **Docker Context Path** | `/` (thư mục, **không** phải path tới file) |
| Port | **3100** |

> Lỗi `cd: can't cd to .../deploy/Dockerfile.dokploy` = bạn đã điền **Context Path** = file Dockerfile.  
> Đúng: Context = `/`, Docker File = `Dockerfile` (hoặc `deploy/Dockerfile.dokploy`).

### 2. Environment

```env
NODE_ENV=production
DASHBOARD_PORT=3100
DASHBOARD_HOST=0.0.0.0
DASHBOARD_SECRET=nc-<random-hex>
```

### 3. Domain — `*.nanoclaw.aimarkets.vn`

DNS + Traefik giống `ai.aimarkets.vn` (denglish): **web + websecure**, `certResolver: letsencrypt`, `domains.main` trên apex.

| Name | Type | Value |
|------|------|--------|
| `nanoclaw` | A | `72.62.72.165` |
| `*.nanoclaw` | A | `72.62.72.165` |

Copy `deploy/dokploy-dynamic-nanoclaw-aimarkets-wildcard.yml` → `/etc/dokploy/traefik/dynamic/`.  
Upstream `http://aimarketplace-nanoclaw-hsnvyh:3100`. Tenant = `{userId}.nanoclaw.aimarkets.vn` (24-hex).

**Cert buyer (bắt buộc):** `HostRegexp` alone → `TRAEFIK DEFAULT CERT`. Giống `ai.aimarkets.vn` (denglish), thêm exact `Host()` + `domains.main` trong `dynamic/aimarkets-user-certs.yml` (`ai-marketplace-api/deploy/dokploy-dynamic-aimarkets-user-certs.yml`), hoặc:

```bash
python3 openclaw/deploy/_apply-aimarkets-user-certs.py <userId>
```

### 4. API marketplace

```env
NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://{userId}.nanoclaw.aimarkets.vn
NANOCLAW_DASHBOARD_SECRET=<cùng DASHBOARD_SECRET ở trên>
NANOCLAW_SSH_HOST_TEMPLATE={userId}.nanoclaw.aimarkets.vn
```

Redeploy API + web. Launch mở:

`https://{userId}.nanoclaw.aimarkets.vn/dashboard?session=market-{userId}…`

### 5. Kiểm tra

```bash
curl -sI https://nanoclaw.aimarkets.vn/dashboard
curl -s -H "Authorization: Bearer $DASHBOARD_SECRET" https://nanoclaw.aimarkets.vn/api/overview
curl -sI https://6a69f224e6032a3f00de977f.nanoclaw.aimarkets.vn/dashboard
```

---

## Mức 2 — Full NanoClaw host (agent + Docker)

Xem skill / docs upstream NanoClaw. Aimarkets Launch mức 1 đủ cho marketplace.

Wire dashboard pusher theo skill `add-dashboard` nếu cần agent live feed.

**Lưu ý:** nested Docker trên Swarm/Dokploy đôi khi bị chặn; ưu tiên mức 1 trước.

---

## aimarkets-proxy (tuỳ chọn)

Chỉ khi cần `/login?token&autoLogin` → cookie Bearer:

1. Deploy `deploy/aimarkets-proxy` (port **3200**)
2. Env: `DASHBOARD_UPSTREAM=http://<nanoclaw-service>:3100`, `DASHBOARD_SECRET=…`
3. Đổi Traefik upstream sang `:3200`
4. API: `NANOCLAW_USE_LOGIN_PROXY=1`

---

## Checklist nhanh

1. [x] Dokploy NanoClaw · port 3100 · `DASHBOARD_SECRET`  
2. [x] Traefik `nanoclaw.aimarkets.vn` + `*.nanoclaw.aimarkets.vn` → `:3100`  
3. [x] API `NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://{userId}.nanoclaw.aimarkets.vn`  
4. [ ] Launch Nano Claw trên marketplace  

Chi tiết: [DOKPLOY-AIMARKETS.md](./DOKPLOY-AIMARKETS.md).

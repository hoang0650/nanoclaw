# Deploy NanoClaw trên Dokploy (AI Markets)

Dokploy: `deploy.phgrouptechs.com` · VPS `72.62.72.165`  
Public Launch: **https://proxvn.phgrouptechs.com** (ProxVN) — không dùng `*.bacsycay.click`.

Có **2 mức** deploy. Aimarkets Launch chỉ cần **mức 1**.

---

## Mức 1 — Dashboard only (khuyến nghị lúc đầu)

Buyer mở Launch → dashboard monitoring. Chưa chạy agent container.

### 1. Tạo Application trên Dokploy

| Field | Value |
|--------|--------|
| Source | GitHub `hoang0650/nanoclaw` · branch `main` |
| Build type | **Dockerfile** |
| Dockerfile path | `deploy/Dockerfile.dokploy` |
| Port | **3100** |

### 2. Environment

```env
NODE_ENV=production
DASHBOARD_PORT=3100
DASHBOARD_HOST=0.0.0.0
# Bật auth (cùng secret trên aimarketplace-api)
DASHBOARD_SECRET=nc-<random-hex>
```

Sinh secret:

```bash
node -e "console.log('nc-'+require('crypto').randomBytes(16).toString('hex'))"
```

### 3. Domain (chọn 1)

**A. ProxVN (mặc định Aimarkets)** — trên **cùng VPS** hoặc máy chạy dashboard:

```bash
proxvn --server <PROXVN_IP>:8882 --proto http 3100 --id nanoclaw-aimarkets --ui=false
```

Cấu hình ProxVN để traffic **https://proxvn.phgrouptechs.com** tới tunnel này (HTTP_DOMAIN / reverse proxy tới ProxVN server của bạn).

**B. Traefik Dokploy (tuỳ chọn)** — Domain `nanoclaw.aimarkets.vn` → port `3100`, rồi paste `deploy/dokploy-dynamic-nanoclaw-aimarkets-wildcard.yml` nếu cần `*.nanoclaw`.

### 4. API marketplace

Dokploy → **aimarketplace-api** → Environment:

```env
NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE=https://proxvn.phgrouptechs.com
NANOCLAW_DASHBOARD_SECRET=<cùng DASHBOARD_SECRET ở trên>
```

Redeploy API + web. Launch NanoClaw sẽ mở:

`https://proxvn.phgrouptechs.com/dashboard?session=market-{userId}…`

### 5. Kiểm tra

```bash
curl -s http://127.0.0.1:3100/api/status
curl -s -H "Authorization: Bearer $DASHBOARD_SECRET" http://127.0.0.1:3100/api/overview
curl -sI https://proxvn.phgrouptechs.com/dashboard
```

---

## Mức 2 — Full NanoClaw host (agent + Docker)

Cần **Docker socket** trên node Dokploy (agent chạy container riêng).

| Field | Value |
|--------|--------|
| Dockerfile | `deploy/Dockerfile.dokploy` |
| Command (override) | `node dist/index.js` |
| Mount | `/var/run/docker.sock:/var/run/docker.sock` |
| Volume | persistent data dir (SQLite / state) |

Env thêm (ví dụ):

```env
DASHBOARD_PORT=3100
DASHBOARD_SECRET=nc-...
WEBHOOK_PORT=3000
# Provider keys theo docs NanoClaw / OneCLI
```

Wire dashboard pusher theo skill `add-dashboard` (copy `dashboard-pusher.ts` vào `src/` + `pnpm add @nanoco/nanoclaw-dashboard`) rồi rebuild image — nếu chưa wire, Command `node dist/index.js` chạy host nhưng dashboard package standalone (CMD mặc định) vẫn đủ cho Launch mức 1.

**Lưu ý:** nested Docker trên Swarm/Dokploy đôi khi bị chặn; ưu tiên mức 1 trước, mức 2 khi đã ổn Launch.

---

## aimarkets-proxy (tuỳ chọn)

Chỉ khi cần `/login?token&autoLogin` → cookie Bearer:

1. Deploy thêm app từ `deploy/aimarkets-proxy` (port **3200**)
2. Env: `DASHBOARD_UPSTREAM=http://<nanoclaw-service>:3100`, `DASHBOARD_SECRET=…`
3. ProxVN tunnel **3200** thay vì 3100
4. API: `NANOCLAW_USE_LOGIN_PROXY=1`

---

## Checklist nhanh

1. [ ] Dokploy app NanoClaw · Dockerfile `deploy/Dockerfile.dokploy` · port 3100  
2. [ ] `DASHBOARD_SECRET` set  
3. [ ] ProxVN client trỏ `:3100` → **proxvn.phgrouptechs.com**  
4. [ ] API: `NANOCLAW_AIMARKETS_PUBLIC_URL_TEMPLATE` + `NANOCLAW_DASHBOARD_SECRET`  
5. [ ] Redeploy marketplace web · bấm Launch Nano Claw  

Chi tiết URL/Launch: [DOKPLOY-AIMARKETS.md](./DOKPLOY-AIMARKETS.md).

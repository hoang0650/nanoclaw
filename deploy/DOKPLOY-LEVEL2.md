# NanoClaw mức 2 — Full host trên Aimarkets (Docker socket + pusher)

Mức 1 = dashboard-only (Overview trống / seed).  
Mức 2 = **full NanoClaw host** + **Docker socket** + **dashboard pusher** → Launch thấy agent groups / sessions thật, container agent có thể spawn.

Public URL không đổi: `https://{userId}.nanoclaw.aimarkets.vn` · Traefik vẫn → `:3100`.

---

## Mục tiêu

| | Mức 1 (hiện tại) | Mức 2 (MVP) |
|--|--|--|
| Process | `@nanoco/nanoclaw-dashboard` + seed | `node dist/index.js` (host) |
| Docker | Không | Mount `/var/run/docker.sock` |
| Overview | Snapshot rỗng | Pusher POST `/api/ingest` từ DB host |
| Agent container | Không | `DockerSessionDriver` spawn sibling containers |
| Multi-tenant | Chỉ Host DNS khác nhau | **Shared host** + group `market-{userId}` (isolation mềm) |

---

## Kiến trúc MVP (Phase 2a)

```
Buyer Launch
  → Traefik Host(`{userId}.nanoclaw.aimarkets.vn`)
  → nanoclaw-host:3100  (dashboard UI + /api/*)

nanoclaw-host (một container Dokploy)
  ├── Node host: dist/index.js
  │     ├── SQLite DATA_DIR (/app/data)
  │     ├── startDashboard() → bind :3100 + pusher 60s
  │     ├── DockerSessionDriver → docker CLI
  │     └── ncl socket (data/ncl.sock)
  └── volume: /var/run/docker.sock → host Docker daemon
        └── docker run nanoclaw-agent-*  (sibling containers)
```

**Một host dùng chung** cho mọi buyer trên VPS. Tenant key = agent group / session folder gắn `market-{userId}` (cùng convention Hermes/OpenClaw). Dashboard hiện **toàn bộ** groups trên host cho đến Phase 2b (filter theo Host).

### Luồng “agent thật”

1. Host boot → migrations → channels/modules → `startDashboard()` + pusher.
2. Tạo agent group (admin/`ncl` hoặc bootstrap Aimarkets):
   - folder / name: `market-{userId}`
   - optional: `ncl groups create --template <ref> --name market-{userId}`
3. Gắn channel (CLI / Telegram / …) → inbound → session wake → Docker spawn.
4. Pusher đẩy snapshot → Overview / Sessions có số liệu thật.

Launch URL API **không cần đổi**: vẫn `/dashboard?session=market-{userId}&audience=aimarkets…`.

---

## Rủi ro & ràng buộc Dokploy / Swarm

- **docker.sock = root trên host Docker.** Chỉ mount trên stack tin cậy; không expose sock ra public.
- Swarm/Dokploy đôi khi chặn nested Docker hoặc sock mount — nếu `docker ps` trong container fail, mức 2 không chạy được trên node đó (rollback mức 1).
- Agent image (`container/Dockerfile`) phải **build sẵn trên host** (`nanoclaw-agent` / slug trong config) trước lần spawn đầu.
- Sibling containers dùng network/volume của **host daemon**, không nằm trong compose service network trừ khi gắn cùng external network.

---

## Phase roadmap

### Phase 2a — MVP (docs + image này)

- [x] Wire `src/dashboard-pusher.ts` + `await startDashboard()` trong `src/index.ts`
- [ ] Deploy `deploy/Dockerfile.level2` + mount sock + volume `data`
- [ ] Build agent base image trên VPS một lần
- [ ] Tạo group thử `market-6a69f224e6032a3f00de977f`, verify Overview ≠ empty seed
- [ ] Giữ Traefik / cert buyer như mức 1

### Phase 2b — Aimarkets product

- Ensure group on Launch: API hoặc host hook tạo `market-{userId}` idempotent
- Filter snapshot / Overview theo `Host` → chỉ group của buyer đó
- Billing hook (COGS + 25%) khi session dùng model (giống OpenClaw aimarkets)
- Optional: `aimarkets-proxy` hash login nếu dashboard cần cookie riêng

### Phase 2c — Isolation mạnh hơn

- Per-buyer host **hoặc** Docker namespace / rootless / separate Docker context
- Không còn shared DB giữa buyers

---

## Deploy trên Dokploy

### 1. Application

| Field | Value |
|--------|--------|
| Source | GitHub `hoang0650/nanoclaw` · `main` |
| Build | **Dockerfile** |
| Docker File | `deploy/Dockerfile.level2` |
| Context | `/` |
| Port | **3100** |

Hoặc Compose: `deploy/docker-compose.aimarkets-level2.yml` (Dokploy Compose mode).

### 2. Mounts (bắt buộc)

| Host | Container | Mục đích |
|------|-----------|----------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | Spawn agent |
| volume `nanoclaw-data` | `/app/data` | SQLite + groups + ncl.sock |

Dokploy UI → Volumes / Mounts. Sock thường là bind mount kiểu file.

### Tripwire (Docker image)

Host từ chối boot nếu thiếu `data/upgrade-state.json` (xem `docs/upgrade-recovery.md`).  
`aimarkets-level2-entrypoint.sh` **stamp marker** mỗi lần start (`via: aimarkets-level2`) — bắt buộc cho image không có `.git`.

```env
NODE_ENV=production
DASHBOARD_PORT=3100
DASHBOARD_HOST=0.0.0.0
DASHBOARD_SECRET=<cùng secret mức 1 / NANOCLAW_DASHBOARD_SECRET>
# Optional providers / channels theo docs NanoClaw
# ANTHROPIC_API_KEY=…
# TIMEZONE=Asia/Ho_Chi_Minh
```

API marketplace **không đổi** template URL; chỉ cần secret khớp.

### 4. Agent image trên VPS (một lần / mỗi upgrade agent)

SSH vào node chạy Docker (cùng daemon với sock):

```bash
cd /path/to/nanoclaw   # hoặc clone tạm
bash container/build.sh
# xác nhận: docker images | grep -i nanoclaw
```

Tên image phải khớp config host (xem `src/drivers` / container config sau setup).

### 5. Tạo group buyer thử

Exec vào container host (hoặc `ncl` qua sock nếu mount được):

```bash
node bin/ncl groups create --folder market-6a69f224e6032a3f00de977f --name market-6a69f224e6032a3f00de977f
# hoặc có template:
# node bin/ncl groups create --template <ref> --name market-6a69f224e6032a3f00de977f --yes
```

Sau ~60s (hoặc ngay nếu pusher push-on-start):  

`curl -s -H "Authorization: Bearer $DASHBOARD_SECRET" https://6a69f224e6032a3f00de977f.nanoclaw.aimarkets.vn/api/overview`  
→ `agent_groups` không còn `[]` thuần seed.

### 6. Rollback về mức 1

Đổi Docker File lại `Dockerfile` (entrypoint dashboard-only), bỏ mount sock. Cert / Traefik / API giữ nguyên.

---

## File trong repo

| File | Vai trò |
|------|---------|
| `deploy/Dockerfile.level2` | Image full host + docker CLI + entrypoint mức 2 |
| `deploy/aimarkets-level2-entrypoint.sh` | `node dist/index.js` (dashboard qua pusher) |
| `deploy/docker-compose.aimarkets-level2.yml` | Compose tham chiếu sock + data volume |
| `src/dashboard-pusher.ts` | startDashboard + POST ingest |
| `src/index.ts` | `await startDashboard()` trước boot-complete log |

Mức 1 vẫn dùng root `Dockerfile` + `aimarkets-dashboard-entrypoint.sh`.

---

## Checklist verify

1. [ ] Container host: `docker ps` thành công (thấy daemon qua sock)
2. [ ] `curl localhost:3100/api/status` → ok
3. [ ] Log host: `Dashboard pusher started`
4. [ ] Có ≥1 agent_groups trên Overview sau khi create group
5. [ ] Session wake → container `nanoclaw-…` xuất hiện trên host `docker ps`
6. [ ] Launch Aimarkets mở đúng `{userId}.nanoclaw…` (cert LE như mức 1)

---

## Không làm trong MVP

- Đổi FE Launch path (vẫn dashboard)
- Per-buyer Docker daemon
- Tự động filter Overview theo subdomain (Phase 2b)
- ProxVN / tunnel (đã bỏ; chỉ `*.nanoclaw.aimarkets.vn`)

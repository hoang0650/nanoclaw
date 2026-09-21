# Deprecated as default Aimarkets edge

**Prefer [ProxVN](https://proxvn.phgrouptechs.com/)** to expose NanoClaw:

```bash
proxvn --server 103.77.246.196:8882 --proto http 3100 --id nanoclaw-aimarkets
```

See `../DOKPLOY-AIMARKETS.md`.

This folder remains an **optional** Bearer login bridge (`/login` → cookie → `Authorization` upstream). If you use it, tunnel **this** port with ProxVN and set `NANOCLAW_USE_LOGIN_PROXY=1` on the marketplace API.

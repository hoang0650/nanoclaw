# Deprecated as default Aimarkets edge

**Prefer [https://proxvn.phgrouptechs.com](https://proxvn.phgrouptechs.com/)** to expose NanoClaw:

```bash
proxvn --server <PROXVN_HOST>:8882 --proto http 3100 --id nanoclaw-aimarkets
```

See `../DOKPLOY-AIMARKETS.md`.

This folder remains an **optional** Bearer login bridge (`/login` → cookie → `Authorization` upstream). If you use it, expose **this** port behind ProxVN and set `NANOCLAW_USE_LOGIN_PROXY=1` on the marketplace API.

# Deprecated as default Aimarkets edge

**Prefer [https://proxvn.phgrouptechs.com](https://proxvn.phgrouptechs.com/)** to expose NanoClaw:

```bash
proxvn --server <PROXVN_HOST>:8882 --proto http 3100 --id nanoclaw-aimarkets
```

See `../DOKPLOY-AIMARKETS.md`.

This folder is the Bearer login bridge (`/login` → cookie → `Authorization` upstream). Both Aimarkets entrypoints start it on **:3200** via `start-background.sh`; point Traefik at that port (never at the dashboard's :3100, whose HTML embeds `DASHBOARD_SECRET`) and set `NANOCLAW_USE_LOGIN_PROXY=1` on the marketplace API.

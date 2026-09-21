# NanoClaw host + dashboard for Dokploy (AI Markets)
# Exposes dashboard on :3100 (Launch → https://proxvn.phgrouptechs.com)

FROM node:22-bookworm-slim AS build
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@10.34.5 --activate
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install
COPY . .
# Dashboard package (Aimarkets Launch surface)
RUN pnpm add @nanoco/nanoclaw-dashboard
RUN pnpm run build

FROM node:22-bookworm-slim
WORKDIR /app
ENV NODE_ENV=production
ENV DASHBOARD_PORT=3100
ENV WEBHOOK_PORT=3000
RUN corepack enable && corepack prepare pnpm@10.34.5 --activate \
  && apt-get update && apt-get install -y --no-install-recommends tini ca-certificates \
  && rm -rf /var/lib/apt/lists/*
COPY --from=build /app /app
# Native sqlite rebuild for runtime image
RUN pnpm rebuild better-sqlite3 || true
EXPOSE 3100 3000
# Prefer dashboard entry for Aimarkets; full agent host needs Docker socket (see DOKPLOY.md)
CMD ["npx", "--yes", "@nanoco/nanoclaw-dashboard"]

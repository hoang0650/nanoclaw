# NanoClaw AI Markets edge (login + Bearer proxy)
# Upstream dashboard: DASHBOARD_UPSTREAM (default http://nanoclaw-dashboard:3100)

FROM node:22-alpine
WORKDIR /app
COPY package.json ./
COPY server.js ./
ENV PORT=3200
ENV DASHBOARD_UPSTREAM=http://127.0.0.1:3100
EXPOSE 3200
CMD ["node", "server.js"]

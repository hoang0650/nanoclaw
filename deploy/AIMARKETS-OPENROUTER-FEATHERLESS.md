# Aimarkets — OpenRouter + Featherless (OpenCode)

NanoClaw không có provider `openrouter`/`featherless` riêng trên trunk; Aimarkets dùng **OpenCode** (`provider: opencode`).

## Dokploy Environment

```env
NANOCLAW_GATEWAY_PROVIDER=none
NANOCLAW_INSTALL_ID=aimarkets
DEFAULT_AGENT_PROVIDER=opencode

# OpenRouter (khuyến nghị mặc định)
OPENCODE_PROVIDER=openrouter
OPENCODE_MODEL=openrouter/anthropic/claude-sonnet-4
OPENCODE_SMALL_MODEL=openrouter/anthropic/claude-haiku-4.5
ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_API_KEY=sk-or-v1-…

# Featherless — comment block OpenRouter ở trên, bật block này:
# OPENCODE_PROVIDER=featherless
# OPENCODE_MODEL=featherless/deepseek-ai/DeepSeek-V3
# OPENCODE_SMALL_MODEL=featherless/deepseek-ai/DeepSeek-V3
# ANTHROPIC_BASE_URL=https://api.featherless.ai/v1
# FEATHERLESS_API_KEY=…
```

Một group chỉ dùng **một** upstream tại một thời điểm (không fallback Hermes-style).

## Sau Deploy

```bash
CID=$(docker ps -q -f name=aimarketplace-nanoclaw-hsnvyh | head -1)
docker exec "$CID" node dist/cli/client.js groups config update \
  --id ag-f6d60fd4-c148-4337-a247-f2fe9d83f79c --provider opencode
docker exec "$CID" node dist/cli/client.js groups restart \
  --id ag-f6d60fd4-c148-4337-a247-f2fe9d83f79c
docker exec "$CID" node dist/cli/client.js messaging-groups send \
  --channel-type cli --platform-id local --text "ping openrouter"
```

Cần rebuild **agent image** (`container/build.sh`) sau khi thêm OpenCode CLI vào image.

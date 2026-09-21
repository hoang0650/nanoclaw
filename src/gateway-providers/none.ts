/**
 * Direct / none gateway — empty contribution.
 *
 * Aimarkets (and other installs that pass Anthropic keys via host env /
 * `data/env/env`) do not need OneCLI for spawn. Set:
 *
 *   NANOCLAW_GATEWAY_PROVIDER=none
 *   ANTHROPIC_API_KEY=sk-ant-…
 *
 * (or CLAUDE_CODE_OAUTH_TOKEN / ANTHROPIC_AUTH_TOKEN).
 */
import { registerGatewayProvider } from './gateway-provider-registry.js';

registerGatewayProvider('none', () => ({
  kind: 'none',
  async contribute() {
    return {};
  },
}));

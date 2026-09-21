/**
 * Host-side container config for the `opencode` provider.
 *
 * OpenCode's `opencode serve` process stores state under XDG_DATA_HOME, which
 * we pin to a per-session host directory mounted at /opencode-xdg. The
 * OPENCODE_* env vars tell the CLI which provider/model to use at runtime
 * (read on the host, injected into the container). NO_PROXY / no_proxy are
 * merged with host values so the in-container OpenCode client can talk to
 * 127.0.0.1 even when HTTPS_PROXY is set by OneCLI.
 *
 * Aimarkets (NANOCLAW_GATEWAY_PROVIDER=none): host writes the upstream API
 * key into a session file (not container env — driver forbids credential
 * values in -e). Container OpenCode reads OPENCODE_API_KEY_FILE.
 */
import fs from 'fs';
import path from 'path';

import { readEnvFile } from '../env.js';
import { registerProviderContainerConfig } from './provider-container-registry.js';

const PASSTHROUGH_KEYS = [
  'OPENCODE_PROVIDER',
  'OPENCODE_MODEL',
  'OPENCODE_SMALL_MODEL',
  'ANTHROPIC_BASE_URL',
  'OPENCODE_MODEL_CONTEXT_LIMIT',
  'OPENCODE_MODEL_OUTPUT_LIMIT',
  'OPENCODE_MODEL_INPUT_MODALITIES',
] as const;

const KEY_ENV_CANDIDATES = ['OPENROUTER_API_KEY', 'FEATHERLESS_API_KEY', 'OPENCODE_API_KEY'] as const;

function mergeNoProxy(current: string | undefined, additions: string): string {
  if (!current?.trim()) return additions;
  const parts = new Set(
    current
      .split(/[\s,]+/)
      .map((s) => s.trim())
      .filter(Boolean),
  );
  for (const addition of additions.split(',')) {
    const trimmed = addition.trim();
    if (trimmed) parts.add(trimmed);
  }
  return [...parts].join(',');
}

function pickUpstreamKey(
  hostEnv: NodeJS.ProcessEnv,
  dotenv: Record<string, string | undefined>,
  provider: string,
): string | undefined {
  const order: string[] =
    provider === 'openrouter'
      ? ['OPENROUTER_API_KEY', 'OPENCODE_API_KEY', 'FEATHERLESS_API_KEY']
      : provider === 'featherless' || provider === 'openai'
        ? ['FEATHERLESS_API_KEY', 'OPENCODE_API_KEY', 'OPENROUTER_API_KEY']
        : ['OPENCODE_API_KEY', 'OPENROUTER_API_KEY', 'FEATHERLESS_API_KEY'];
  for (const key of order) {
    const value = (hostEnv[key] ?? dotenv[key])?.trim();
    if (value) return value;
  }
  return undefined;
}

function defaultBaseUrl(provider: string): string | undefined {
  if (provider === 'openrouter') return 'https://openrouter.ai/api/v1';
  if (provider === 'featherless' || provider === 'openai') return 'https://api.featherless.ai/v1';
  return undefined;
}

registerProviderContainerConfig('opencode', (ctx) => {
  const opencodeDir = path.join(ctx.sessionDir, 'opencode-xdg');
  fs.mkdirSync(opencodeDir, { recursive: true });

  const env: Record<string, string> = {
    XDG_DATA_HOME: '/opencode-xdg',
    NO_PROXY: mergeNoProxy(ctx.hostEnv.NO_PROXY, '127.0.0.1,localhost'),
    no_proxy: mergeNoProxy(ctx.hostEnv.no_proxy, '127.0.0.1,localhost'),
  };
  // The host process does not load `.env` into process.env (readEnvFile keeps
  // file values out of child processes), and the service units set no
  // EnvironmentFile — so under launchd/systemd, ctx.hostEnv carries none of
  // these. Fall back to the `.env` file the way the claude provider does;
  // a real exported variable still wins over the file.
  const dotenv = readEnvFile([...PASSTHROUGH_KEYS, ...KEY_ENV_CANDIDATES]);
  for (const key of PASSTHROUGH_KEYS) {
    const value = ctx.hostEnv[key] ?? dotenv[key];
    if (value) env[key] = value;
  }

  const provider = (env.OPENCODE_PROVIDER || 'openrouter').toLowerCase();
  if (!env.ANTHROPIC_BASE_URL) {
    const fallback = defaultBaseUrl(provider);
    if (fallback) env.ANTHROPIC_BASE_URL = fallback;
  }

  const upstreamKey = pickUpstreamKey(ctx.hostEnv, dotenv, provider);
  if (upstreamKey) {
    const keyPath = path.join(opencodeDir, 'api-key');
    fs.writeFileSync(keyPath, `${upstreamKey}\n`, { mode: 0o600 });
    env.OPENCODE_API_KEY_FILE = '/opencode-xdg/api-key';
  }

  return {
    mounts: [{ hostPath: opencodeDir, containerPath: '/opencode-xdg', readonly: false }],
    env,
  };
});

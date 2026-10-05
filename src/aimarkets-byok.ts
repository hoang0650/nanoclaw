/**
 * AI Markets BYOK: buyer groups (`market-<userId>`) can run on the buyer's own
 * provider key, chosen on aimarkets.vn and resolved here through the
 * marketplace API (`GET /v1/nanoclaw/provider/resolve`, X-Service-Secret).
 * Enabled only when AIMARKETS_API_URL and AIMARKETS_SERVICE_SECRET are set.
 */
import path from 'path';

import { readEnvFile } from './env.js';
import { log } from './log.js';

export interface AimarketsByokConnection {
  provider: string;
  baseUrl: string;
  apiKey: string;
  model: string;
}

const MARKET_FOLDER_RE = /^market-([a-f0-9]{24})$/i;
const CACHE_TTL_MS = 30_000;
const FETCH_TIMEOUT_MS = 5_000;

const cache = new Map<string, { at: number; value: AimarketsByokConnection | null }>();

export function marketUserIdFromGroupDir(groupDir: string): string | null {
  const match = MARKET_FOLDER_RE.exec(path.basename(groupDir));
  return match ? match[1].toLowerCase() : null;
}

function readConfig(hostEnv: NodeJS.ProcessEnv): { apiUrl: string; secret: string } | null {
  const dotenv = readEnvFile(['AIMARKETS_API_URL', 'AIMARKETS_SERVICE_SECRET']);
  const apiUrl = (hostEnv.AIMARKETS_API_URL ?? dotenv.AIMARKETS_API_URL ?? '').trim().replace(/\/+$/, '');
  const secret = (hostEnv.AIMARKETS_SERVICE_SECRET ?? dotenv.AIMARKETS_SERVICE_SECRET ?? '').trim();
  return apiUrl && secret ? { apiUrl, secret } : null;
}

function parseConnection(raw: unknown): AimarketsByokConnection | null {
  if (!raw || typeof raw !== 'object') return null;
  const c = raw as Record<string, unknown>;
  const pick = (k: string) => (typeof c[k] === 'string' ? (c[k] as string).trim() : '');
  const conn = { provider: pick('provider'), baseUrl: pick('baseUrl'), apiKey: pick('apiKey'), model: pick('model') };
  return conn.baseUrl && conn.apiKey && conn.model ? conn : null;
}

export async function resolveAimarketsByok(
  groupDir: string,
  hostEnv: NodeJS.ProcessEnv,
  fetchImpl: typeof fetch = fetch,
): Promise<AimarketsByokConnection | null> {
  const userId = marketUserIdFromGroupDir(groupDir);
  if (!userId) return null;
  const config = readConfig(hostEnv);
  if (!config) return null;

  const cached = cache.get(userId);
  if (cached && Date.now() - cached.at < CACHE_TTL_MS) return cached.value;

  try {
    const url = `${config.apiUrl}/v1/nanoclaw/provider/resolve?user_id=${encodeURIComponent(userId)}`;
    const res = await fetchImpl(url, {
      headers: { 'X-Service-Secret': config.secret, Accept: 'application/json' },
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const body = (await res.json()) as { connection?: unknown };
    const value = parseConnection(body.connection);
    cache.set(userId, { at: Date.now(), value });
    return value;
  } catch (err) {
    log.warn('AI Markets BYOK resolve failed; using default model', { userId, err: String(err) });
    return cached?.value ?? null;
  }
}

export function clearAimarketsByokCache(): void {
  cache.clear();
}

/**
 * Ponytail coding ruleset for AI Markets agents, fetched on the host from the
 * shared Ponytail service (PONYTAIL_URL, see ponytail/deploy/DOKPLOY.md) and
 * inlined into the composed CLAUDE.md by `project-doc-compose.ts`.
 *
 * Never throws: a per-spawn throw would ride the transient-retry contract and
 * respawn the group forever. Unreachable service = last good copy, or nothing.
 */
import { PONYTAIL_MODE, PONYTAIL_URL } from './config.js';
import { log } from './log.js';

const REFRESH_MS = 10 * 60_000;
const RETRY_MS = 60_000;
const TIMEOUT_MS = 3_000;
const MODES = new Set(['compact', 'lite', 'full', 'ultra', 'off']);

export function createPonytailRules(options: {
  url: string;
  mode?: string;
  now?: () => number;
}): () => Promise<string> {
  const base = options.url.trim().replace(/\/+$/, '');
  const requested = (options.mode || '').trim().toLowerCase();
  const mode = MODES.has(requested) ? requested : 'compact';
  const now = options.now ?? Date.now;
  if (!base || mode === 'off') return async () => '';

  let text = '';
  let etag = '';
  let nextRefreshAt = 0;
  let inflight: Promise<void> | null = null;

  const refresh = async (): Promise<void> => {
    try {
      const res = await fetch(`${base}/v1/rules?mode=${mode}`, {
        headers: etag ? { 'If-None-Match': etag } : {},
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
      if (res.status !== 304) {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const body = (await res.text()).trim();
        if (body) {
          text = body;
          etag = res.headers.get('etag') || '';
        }
      }
      nextRefreshAt = now() + REFRESH_MS;
    } catch (err) {
      log.warn('Ponytail rules unavailable', { url: base, err: String(err) });
      nextRefreshAt = now() + RETRY_MS;
    }
  };

  return async () => {
    if (now() >= nextRefreshAt && !inflight) {
      inflight = refresh().finally(() => {
        inflight = null;
      });
    }
    // Serve the last good copy while revalidating; only the very first fetch waits.
    if (!text && inflight) await inflight;
    return text;
  };
}

export const getPonytailRules = createPonytailRules({ url: PONYTAIL_URL, mode: PONYTAIL_MODE });

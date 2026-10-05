import { afterEach, describe, expect, it, vi } from 'vitest';

import { clearAimarketsByokCache, marketUserIdFromGroupDir, resolveAimarketsByok } from './aimarkets-byok.js';

const USER = '6a69f224e6032a3f00de977f';
const GROUP_DIR = `/opt/nanoclaw-aimarkets/groups/market-${USER}`;
const ENV = { AIMARKETS_API_URL: 'https://api.example.test/', AIMARKETS_SERVICE_SECRET: 'svc' };
const CONNECTION = {
  provider: 'openrouter',
  baseUrl: 'https://openrouter.ai/api/v1',
  apiKey: 'sk-or-buyer',
  model: 'anthropic/claude-sonnet-4.5',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

afterEach(() => clearAimarketsByokCache());

describe('marketUserIdFromGroupDir', () => {
  it('extracts the buyer id from market-<userId> folders only', () => {
    expect(marketUserIdFromGroupDir(GROUP_DIR)).toBe(USER);
    expect(marketUserIdFromGroupDir('/app/groups/main')).toBeNull();
    expect(marketUserIdFromGroupDir('/app/groups/market-abc')).toBeNull();
  });
});

describe('resolveAimarketsByok', () => {
  it('fetches the buyer connection with the service secret', async () => {
    const fetchImpl = vi.fn(async () => jsonResponse({ success: true, connection: CONNECTION }));
    const conn = await resolveAimarketsByok(GROUP_DIR, ENV, fetchImpl as unknown as typeof fetch);
    expect(conn).toEqual(CONNECTION);
    const [url, init] = fetchImpl.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe(`https://api.example.test/v1/nanoclaw/provider/resolve?user_id=${USER}`);
    expect((init.headers as Record<string, string>)['X-Service-Secret']).toBe('svc');
  });

  it('caches results, including "no selection"', async () => {
    const fetchImpl = vi.fn(async () => jsonResponse({ success: true, connection: null }));
    const f = fetchImpl as unknown as typeof fetch;
    expect(await resolveAimarketsByok(GROUP_DIR, ENV, f)).toBeNull();
    expect(await resolveAimarketsByok(GROUP_DIR, ENV, f)).toBeNull();
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it('skips non-buyer groups and unconfigured hosts without calling the API', async () => {
    const fetchImpl = vi.fn();
    const f = fetchImpl as unknown as typeof fetch;
    expect(await resolveAimarketsByok('/app/groups/main', ENV, f)).toBeNull();
    expect(await resolveAimarketsByok(GROUP_DIR, {}, f)).toBeNull();
    expect(fetchImpl).not.toHaveBeenCalled();
  });

  it('falls back to the default model on API errors', async () => {
    const fetchImpl = vi.fn(async () => jsonResponse({ success: false }, 500));
    expect(await resolveAimarketsByok(GROUP_DIR, ENV, fetchImpl as unknown as typeof fetch)).toBeNull();
  });

  it('rejects incomplete connections', async () => {
    const fetchImpl = vi.fn(async () => jsonResponse({ connection: { ...CONNECTION, apiKey: '' } }));
    expect(await resolveAimarketsByok(GROUP_DIR, ENV, fetchImpl as unknown as typeof fetch)).toBeNull();
  });
});

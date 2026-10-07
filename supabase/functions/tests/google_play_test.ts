// Run: deno test --allow-env supabase/functions/tests/
import { assert, assertEquals, assertRejects } from "jsr:@std/assert@1";
import {
  entitlementOf,
  getSubscription,
  PlayApiError,
  signJwt,
  type SubscriptionPurchaseV2,
} from "../_shared/google_play.ts";
import { profileEntitled } from "../_shared/entitlement.ts";

const NOW = new Date("2026-10-06T12:00:00Z");
const future = "2026-11-06T12:00:00Z";
const past = "2026-10-01T12:00:00Z";

function sub(state: string, expiry: string, productId = "cnc_assist_pro_monthly"): SubscriptionPurchaseV2 {
  return { subscriptionState: state, lineItems: [{ productId, expiryTime: expiry }] };
}

Deno.test("entitlement: active and grace period grant Pro until expiry", () => {
  for (const state of ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"]) {
    const e = entitlementOf(sub(state, future), NOW);
    assert(e.active, state);
    assertEquals(e.expiresAt?.toISOString(), new Date(future).toISOString());
    assertEquals(e.productId, "cnc_assist_pro_monthly");
  }
});

Deno.test("entitlement: canceled keeps Pro until the paid period ends", () => {
  assert(entitlementOf(sub("SUBSCRIPTION_STATE_CANCELED", future), NOW).active);
  assert(!entitlementOf(sub("SUBSCRIPTION_STATE_CANCELED", past), NOW).active);
});

Deno.test("entitlement: expired, on hold, paused and pending grant nothing", () => {
  for (const state of [
    "SUBSCRIPTION_STATE_EXPIRED",
    "SUBSCRIPTION_STATE_ON_HOLD",
    "SUBSCRIPTION_STATE_PAUSED",
    "SUBSCRIPTION_STATE_PENDING",
    "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED",
  ]) {
    assert(!entitlementOf(sub(state, future), NOW).active, state);
  }
});

Deno.test("entitlement: another app's product grants nothing", () => {
  assert(!entitlementOf(sub("SUBSCRIPTION_STATE_ACTIVE", future, "some_other_sku"), NOW).active);
});

Deno.test("entitlement: latest line item wins", () => {
  const e = entitlementOf({
    subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
    lineItems: [
      { productId: "cnc_assist_pro_monthly", expiryTime: past },
      { productId: "cnc_assist_pro_yearly", expiryTime: future },
    ],
  }, NOW);
  assert(e.active);
  assertEquals(e.productId, "cnc_assist_pro_yearly");
});

Deno.test("profile cache: a tier without an expiry grants nothing", () => {
  assert(!profileEntitled({ subscription_tier: "pro", subscription_expires_at: null }, NOW));
  assert(!profileEntitled({ subscription_tier: "team", subscription_expires_at: null }, NOW));
  assert(!profileEntitled({ subscription_tier: "pro", subscription_expires_at: past }, NOW));
  assert(!profileEntitled({ subscription_tier: "free", subscription_expires_at: future }, NOW));
  assert(!profileEntitled(null, NOW));
  assert(profileEntitled({ subscription_tier: "pro", subscription_expires_at: future }, NOW));
});

async function testKey() {
  const pair = await crypto.subtle.generateKey(
    { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
    true,
    ["sign", "verify"],
  );
  const der = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  let bin = "";
  for (const b of der) bin += String.fromCharCode(b);
  const body = btoa(bin).replace(/(.{64})/g, "$1\n");
  const pem = `-----BEGIN PRIVATE KEY-----\n${body}\n-----END PRIVATE KEY-----\n`;
  return { pem, publicKey: pair.publicKey };
}

function b64urlDecode(s: string): Uint8Array<ArrayBuffer> {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((s.length + 3) % 4);
  const bin = atob(b64);
  const out = new Uint8Array(new ArrayBuffer(bin.length));
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

Deno.test("service-account JWT is RS256-signed with the right claims", async () => {
  const { pem, publicKey } = await testKey();
  const jwt = await signJwt(
    { client_email: "play@test.iam.gserviceaccount.com", private_key: pem },
    "https://oauth2.googleapis.com/token",
    NOW.getTime(),
  );
  const [h, c, s] = jwt.split(".");
  assertEquals(JSON.parse(new TextDecoder().decode(b64urlDecode(h))), { alg: "RS256", typ: "JWT" });
  const claims = JSON.parse(new TextDecoder().decode(b64urlDecode(c)));
  assertEquals(claims.iss, "play@test.iam.gserviceaccount.com");
  assertEquals(claims.scope, "https://www.googleapis.com/auth/androidpublisher");
  assertEquals(claims.aud, "https://oauth2.googleapis.com/token");
  assertEquals(claims.exp - claims.iat, 3600);
  const ok = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    publicKey,
    b64urlDecode(s),
    new TextEncoder().encode(`${h}.${c}`),
  );
  assert(ok, "signature verifies with the public key");
});

Deno.test("getSubscription exchanges the JWT, then calls subscriptionsv2 with the token", async () => {
  const { pem } = await testKey();
  Deno.env.set("GOOGLE_PLAY_SERVICE_ACCOUNT_KEY", JSON.stringify({
    client_email: "play@test.iam.gserviceaccount.com",
    private_key: pem,
    token_uri: "https://oauth2.googleapis.com/token",
  }));
  const calls: string[] = [];
  const realFetch = globalThis.fetch;
  globalThis.fetch = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    calls.push(url);
    if (url === "https://oauth2.googleapis.com/token") {
      const form = new URLSearchParams(String(init?.body));
      assertEquals(form.get("grant_type"), "urn:ietf:params:oauth:grant-type:jwt-bearer");
      return new Response(JSON.stringify({ access_token: "ya29.test", expires_in: 3600 }));
    }
    assertEquals((init?.headers as Record<string, string>).Authorization, "Bearer ya29.test");
    if (url.endsWith("/tokens/good%2Btoken")) {
      return new Response(JSON.stringify(sub("SUBSCRIPTION_STATE_ACTIVE", future)));
    }
    return new Response('{"error":{"code":400,"message":"Invalid Value"}}', { status: 400 });
  }) as typeof fetch;
  try {
    const s = await getSubscription("good+token");
    assertEquals(s.subscriptionState, "SUBSCRIPTION_STATE_ACTIVE");
    assert(calls[1].includes("/applications/com.cncassist.cnc_assist/purchases/subscriptionsv2/tokens/"));

    const err = await assertRejects(() => getSubscription("forged"), PlayApiError);
    assert(err.isInvalidToken);
    // The access token is cached: one OAuth exchange for both API calls.
    assertEquals(calls.filter((u) => u.includes("oauth2")).length, 1);
  } finally {
    globalThis.fetch = realFetch;
  }
});

// ── isPro against a stand-in for the Supabase query builder ─────────────────

import { isPro } from "../_shared/entitlement.ts";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

/// Each table resolves every query on it to one fixed result.
function fakeAdmin(results: Record<string, { data: unknown; error: unknown }>): SupabaseClient {
  const builder = (result: { data: unknown; error: unknown }) => {
    const b: Record<string, unknown> = {};
    for (const m of ["select", "eq", "gt", "in", "order", "limit"]) b[m] = () => b;
    b.maybeSingle = () => Promise.resolve(result);
    b.then = (ok: (r: unknown) => unknown, bad?: (e: unknown) => unknown) =>
      Promise.resolve(result).then(ok, bad);
    return b;
  };
  return { from: (table: string) => builder(results[table]) } as unknown as SupabaseClient;
}

Deno.test("isPro: paid-up profile is Pro without touching purchases", async () => {
  const admin = fakeAdmin({
    profiles: { data: { subscription_tier: "pro", subscription_expires_at: "2999-01-01T00:00:00Z" }, error: null },
    purchases: { data: null, error: { message: "must not be queried" } },
  });
  assert(await isPro(admin, "u1"));
});

Deno.test("isPro: free user stays free (not a 500) if the purchases table is missing", async () => {
  const admin = fakeAdmin({
    profiles: { data: { subscription_tier: "free", subscription_expires_at: null }, error: null },
    purchases: { data: null, error: { code: "PGRST205", message: "Could not find the table 'public.purchases'" } },
  });
  assertEquals(await isPro(admin, "u1"), false);
});

Deno.test("isPro: free user with no purchases is free", async () => {
  const admin = fakeAdmin({
    profiles: { data: { subscription_tier: "free", subscription_expires_at: null }, error: null },
    purchases: { data: [], error: null },
  });
  assertEquals(await isPro(admin, "u1"), false);
});

// Google Play Developer API: verifies subscription purchase tokens server-side.
//
// Needs the secret GOOGLE_PLAY_SERVICE_ACCOUNT_KEY: the full JSON key of a
// Google Cloud service account that has been invited in Play Console (Users and
// permissions) with "View financial data" and "Manage orders and
// subscriptions". The key never leaves the Edge Functions.

export const PACKAGE_NAME = Deno.env.get("PLAY_PACKAGE_NAME") ?? "com.cncassist.cnc_assist";
export const PRO_PRODUCT_IDS = ["cnc_assist_pro_monthly", "cnc_assist_pro_yearly"];

const API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";
const SCOPE = "https://www.googleapis.com/auth/androidpublisher";

/// The fields of a SubscriptionPurchaseV2 this app uses.
/// https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2
export interface SubscriptionPurchaseV2 {
  subscriptionState?: string;
  acknowledgementState?: string;
  linkedPurchaseToken?: string;
  testPurchase?: Record<string, unknown>;
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string };
  lineItems?: Array<{ productId?: string; expiryTime?: string }>;
}

/// States in which the user has paid for the current period. CANCELED means
/// auto-renew is off, but access runs until expiryTime.
const ENTITLED_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  "SUBSCRIPTION_STATE_CANCELED",
]);

export interface Entitlement {
  productId: string | null;
  state: string;
  expiresAt: Date | null;
  active: boolean;
}

/// Reduces a SubscriptionPurchaseV2 to what the app grants. Only products in
/// [PRO_PRODUCT_IDS] count; access needs an entitled state and a future expiry.
export function entitlementOf(sub: SubscriptionPurchaseV2, now = new Date()): Entitlement {
  const items = (sub.lineItems ?? []).filter((li) => li.productId && PRO_PRODUCT_IDS.includes(li.productId));
  let expiresAt: Date | null = null;
  let productId: string | null = null;
  for (const li of items) {
    const t = li.expiryTime ? new Date(li.expiryTime) : null;
    if (t && !isNaN(t.getTime()) && (!expiresAt || t > expiresAt)) {
      expiresAt = t;
      productId = li.productId!;
    }
  }
  const state = sub.subscriptionState ?? "SUBSCRIPTION_STATE_UNSPECIFIED";
  const active = items.length > 0 && ENTITLED_STATES.has(state) && !!expiresAt && expiresAt > now;
  return { productId: productId ?? items[0]?.productId ?? null, state, expiresAt, active };
}

export class PlayApiError extends Error {
  constructor(readonly status: number, readonly body: string) {
    super(`Play API HTTP ${status}: ${body.slice(0, 300)}`);
  }
  /// The token is unknown to Google (forged, or for another app).
  get isInvalidToken(): boolean {
    return this.status === 400 || this.status === 404 || this.status === 410;
  }
}

export async function getSubscription(purchaseToken: string): Promise<SubscriptionPurchaseV2> {
  const url = `${API}/${PACKAGE_NAME}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;
  const resp = await fetch(url, { headers: { Authorization: `Bearer ${await accessToken()}` } });
  if (!resp.ok) throw new PlayApiError(resp.status, await resp.text());
  return await resp.json();
}

/// Acknowledges on the server so the purchase is kept even if the app dies
/// before it calls completePurchase. Google refunds unacknowledged purchases
/// after three days.
export async function acknowledgeSubscription(productId: string, purchaseToken: string): Promise<void> {
  const url = `${API}/${PACKAGE_NAME}/purchases/subscriptions/${encodeURIComponent(productId)}` +
    `/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;
  const resp = await fetch(url, {
    method: "POST",
    headers: { Authorization: `Bearer ${await accessToken()}`, "Content-Type": "application/json" },
    body: "{}",
  });
  if (!resp.ok) throw new PlayApiError(resp.status, await resp.text());
}

export function hasServiceAccount(): boolean {
  return !!Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_KEY");
}

// ── OAuth 2.0 for service accounts (JWT bearer grant) ────────────────────────

interface ServiceAccountKey {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

let cached: { token: string; expiresAt: number } | null = null;

async function accessToken(): Promise<string> {
  if (cached && cached.expiresAt - 60_000 > Date.now()) return cached.token;
  const raw = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_KEY");
  if (!raw) throw new Error("GOOGLE_PLAY_SERVICE_ACCOUNT_KEY is not set");
  const key = JSON.parse(raw) as ServiceAccountKey;
  const tokenUri = key.token_uri ?? "https://oauth2.googleapis.com/token";

  const assertion = await signJwt(key, tokenUri);
  const resp = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!resp.ok) throw new Error(`Google OAuth HTTP ${resp.status}: ${(await resp.text()).slice(0, 300)}`);
  const data = await resp.json() as { access_token: string; expires_in: number };
  cached = { token: data.access_token, expiresAt: Date.now() + data.expires_in * 1000 };
  return data.access_token;
}

export async function signJwt(key: ServiceAccountKey, audience: string, now = Date.now()): Promise<string> {
  const iat = Math.floor(now / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claims = { iss: key.client_email, scope: SCOPE, aud: audience, iat, exp: iat + 3600 };
  const input = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(claims))}`;
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(key.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, new TextEncoder().encode(input));
  return `${input}.${b64url(new Uint8Array(sig))}`;
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "").replace(/\s+/g, "");
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out.buffer;
}

function b64url(data: string | Uint8Array): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// Who is Pro.
//
// The Supabase project is shared with another app, which owns `profiles` and
// the sign-up trigger. CNC Assist keeps its own two tables (migration 003):
//   cnc_purchases     verified Google Play subscriptions, the source of truth
//   cnc_entitlements  one row per user (tier + expiry), a cache of the above
//                     that the app can read
// Neither is writable by app users; only these functions (service role)
// write them.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { entitlementOf, getSubscription, type Entitlement, type SubscriptionPurchaseV2 } from "./google_play.ts";

/// Re-ask Google about a lapsed purchase at most this often per token, so a
/// lapsed subscriber does not trigger an API call on every AI request.
const REFRESH_AFTER_MS = 10 * 60 * 1000;

const ENTITLED_STATES = [
  "SUBSCRIPTION_STATE_ACTIVE",
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  "SUBSCRIPTION_STATE_CANCELED",
];

/// True when a cnc_entitlements row grants Pro right now. A tier without an
/// expiry date grants nothing: every legitimate grant comes with one.
export function entitlementActive(row: { tier?: string | null; expires_at?: string | null } | null,
                                  now = new Date()): boolean {
  if (!row || !row.tier || row.tier === "free") return false;
  if (!row.expires_at) return false;
  return new Date(row.expires_at) > now;
}

/// Whether [userId] has Pro. If the cached expiry has passed but the user has a
/// purchase on file, Google is asked again: the subscription may have renewed.
///
/// A failed lookup counts as "not Pro" (and is logged) rather than an error:
/// free access must keep working, including in the minutes between deploying
/// these functions and running the migration that creates the tables.
export async function isPro(admin: SupabaseClient, userId: string): Promise<boolean> {
  const { data: cached, error } = await admin
    .from("cnc_entitlements")
    .select("tier, expires_at")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    console.error("isPro: entitlement lookup failed:", error);
    return false;
  }
  if (entitlementActive(cached)) return true;

  const { data: rows, error: rowsError } = await admin
    .from("cnc_purchases")
    .select("purchase_token, updated_at")
    .eq("user_id", userId)
    .order("expires_at", { ascending: false, nullsFirst: false })
    .limit(3);
  if (rowsError) {
    console.error("isPro: purchases lookup failed:", rowsError);
    return false;
  }

  for (const row of rows ?? []) {
    if (Date.now() - new Date(row.updated_at).getTime() < REFRESH_AFTER_MS) continue;
    try {
      const sub = await getSubscription(row.purchase_token);
      const ent = await applySubscription(admin, userId, row.purchase_token, sub);
      if (ent.active) return true;
    } catch (e) {
      console.error("entitlement refresh failed:", e);
    }
  }
  return false;
}

/// Stores Google's view of [purchaseToken] for [userId] and refreshes the
/// cached entitlement of everyone it affects.
///
/// A token belongs to one account at a time. Users are anonymous, so a
/// reinstall means a new account; when a token shows up from a new account it
/// moves there, and the previous holder is recomputed (and loses Pro unless
/// they hold another active purchase).
export async function applySubscription(
  admin: SupabaseClient,
  userId: string,
  purchaseToken: string,
  sub: SubscriptionPurchaseV2,
): Promise<Entitlement> {
  const ent = entitlementOf(sub);

  const { data: existing, error: readError } = await admin
    .from("cnc_purchases")
    .select("user_id")
    .eq("purchase_token", purchaseToken)
    .maybeSingle();
  if (readError) throw readError;

  const { error: upsertError } = await admin.from("cnc_purchases").upsert({
    purchase_token:        purchaseToken,
    user_id:               userId,
    product_id:            ent.productId ?? "unknown",
    state:                 ent.state,
    expires_at:            ent.expiresAt?.toISOString() ?? null,
    linked_purchase_token: sub.linkedPurchaseToken ?? null,
    is_test:               !!sub.testPurchase,
    updated_at:            new Date().toISOString(),
  }, { onConflict: "purchase_token" });
  if (upsertError) throw upsertError;

  // An upgrade or resubscribe replaces the old token; it must not keep granting.
  if (sub.linkedPurchaseToken) {
    await admin.from("cnc_purchases").delete().eq("purchase_token", sub.linkedPurchaseToken);
  }

  await recomputeEntitlement(admin, userId);
  if (existing && existing.user_id !== userId) {
    await recomputeEntitlement(admin, existing.user_id);
  }
  return ent;
}

/// Marks a purchase refunded or revoked (voided purchase notification).
export async function voidPurchase(admin: SupabaseClient, purchaseToken: string): Promise<void> {
  const { data: row } = await admin
    .from("cnc_purchases")
    .select("user_id")
    .eq("purchase_token", purchaseToken)
    .maybeSingle();
  if (!row) return;
  await admin.from("cnc_purchases").update({
    state:      "VOIDED",
    expires_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  }).eq("purchase_token", purchaseToken);
  await recomputeEntitlement(admin, row.user_id);
}

/// Sets the user's cached entitlement from their purchases: Pro until the
/// latest expiry of an entitled purchase, otherwise free.
export async function recomputeEntitlement(admin: SupabaseClient, userId: string): Promise<void> {
  const nowIso = new Date().toISOString();
  const { data: rows, error } = await admin
    .from("cnc_purchases")
    .select("expires_at, state")
    .eq("user_id", userId)
    .gt("expires_at", nowIso)
    .in("state", ENTITLED_STATES)
    .order("expires_at", { ascending: false })
    .limit(1);
  if (error) throw error;

  const latest = rows?.[0]?.expires_at ?? null;
  const { error: upsertError } = await admin.from("cnc_entitlements").upsert({
    user_id:    userId,
    tier:       latest ? "pro" : "free",
    expires_at: latest,
    updated_at: nowIso,
  }, { onConflict: "user_id" });
  if (upsertError) throw upsertError;
}

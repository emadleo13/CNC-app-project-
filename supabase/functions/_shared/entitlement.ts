// Who is Pro. The `purchases` table, filled only from verified Google Play data,
// is the source of truth; profiles.subscription_tier and
// profiles.subscription_expires_at are a cache of it that the app can read.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { entitlementOf, getSubscription, type Entitlement, type SubscriptionPurchaseV2 } from "./google_play.ts";

/// Re-ask Google about a lapsed purchase at most this often per token, so a
/// lapsed subscriber does not trigger an API call on every AI request.
const REFRESH_AFTER_MS = 10 * 60 * 1000;

/// True when the profile grants Pro right now. A tier without an expiry date
/// grants nothing: every legitimate grant comes with one.
export function profileEntitled(p: { subscription_tier?: string | null; subscription_expires_at?: string | null } | null,
                                now = new Date()): boolean {
  if (!p || !p.subscription_tier || p.subscription_tier === "free") return false;
  if (!p.subscription_expires_at) return false;
  return new Date(p.subscription_expires_at) > now;
}

/// Whether [userId] has Pro. If the cached expiry has passed but the user has a
/// purchase on file, Google is asked again: the subscription may have renewed.
export async function isPro(admin: SupabaseClient, userId: string): Promise<boolean> {
  const { data: profile, error } = await admin
    .from("profiles")
    .select("subscription_tier, subscription_expires_at")
    .eq("id", userId)
    .maybeSingle();
  if (error) throw error;
  if (profileEntitled(profile)) return true;

  const { data: rows, error: rowsError } = await admin
    .from("purchases")
    .select("purchase_token, updated_at")
    .eq("user_id", userId)
    .order("expires_at", { ascending: false, nullsFirst: false })
    .limit(3);
  if (rowsError) {
    // Fail closed for Pro, but keep the user's free access working. This also
    // covers the minutes between deploying these functions and running the
    // migration that creates the purchases table.
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
/// cached tier of everyone it affects.
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
    .from("purchases")
    .select("user_id")
    .eq("purchase_token", purchaseToken)
    .maybeSingle();
  if (readError) throw readError;

  const { error: upsertError } = await admin.from("purchases").upsert({
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
    await admin.from("purchases").delete().eq("purchase_token", sub.linkedPurchaseToken);
  }

  await recomputeProfile(admin, userId);
  if (existing && existing.user_id !== userId) {
    await recomputeProfile(admin, existing.user_id);
  }
  return ent;
}

/// Marks a purchase refunded or revoked (voided purchase notification).
export async function voidPurchase(admin: SupabaseClient, purchaseToken: string): Promise<void> {
  const { data: row } = await admin
    .from("purchases")
    .select("user_id")
    .eq("purchase_token", purchaseToken)
    .maybeSingle();
  if (!row) return;
  await admin.from("purchases").update({
    state:      "VOIDED",
    expires_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  }).eq("purchase_token", purchaseToken);
  await recomputeProfile(admin, row.user_id);
}

/// Sets the profile's cached tier from the user's purchases: Pro until the
/// latest expiry of an entitled purchase, otherwise free.
export async function recomputeProfile(admin: SupabaseClient, userId: string): Promise<void> {
  const nowIso = new Date().toISOString();
  const { data: rows, error } = await admin
    .from("purchases")
    .select("expires_at, state")
    .eq("user_id", userId)
    .gt("expires_at", nowIso)
    .in("state", ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD", "SUBSCRIPTION_STATE_CANCELED"])
    .order("expires_at", { ascending: false })
    .limit(1);
  if (error) throw error;

  const latest = rows?.[0]?.expires_at ?? null;
  const fields = {
    subscription_tier:       latest ? "pro" : "free",
    subscription_expires_at: latest,
    updated_at:              nowIso,
  };
  const { data: updated, error: updateError } = await admin
    .from("profiles")
    .update(fields)
    .eq("id", userId)
    .select("id");
  if (updateError) throw updateError;
  if (!updated?.length) {
    // The sign-up trigger normally creates the row; don't drop a paid
    // entitlement on the floor if it is missing.
    const { error: insertError } = await admin.from("profiles").insert({ id: userId, email: "", ...fields });
    if (insertError) throw insertError;
  }
}

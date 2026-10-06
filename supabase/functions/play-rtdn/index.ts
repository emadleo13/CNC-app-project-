// Google Play Real-time Developer Notifications, delivered by a Cloud Pub/Sub
// push subscription. Keeps entitlements current between app launches: a
// renewal extends Pro, while an expiry, revocation or refund ends it now
// rather than at the cached expiry date.
//
// Deploy with JWT verification off (Pub/Sub cannot send a Supabase JWT); the
// request is authenticated by the PLAY_RTDN_SECRET query parameter instead.
// Push endpoint:
//   https://<project>.supabase.co/functions/v1/play-rtdn?secret=<PLAY_RTDN_SECRET>
import { adminClient } from "../_shared/auth.ts";
import { applySubscription, voidPurchase } from "../_shared/entitlement.ts";
import { getSubscription, PACKAGE_NAME, PlayApiError } from "../_shared/google_play.ts";
import { json } from "../_shared/http.ts";

interface DeveloperNotification {
  packageName?: string;
  subscriptionNotification?: { notificationType?: number; purchaseToken?: string; subscriptionId?: string };
  voidedPurchaseNotification?: { purchaseToken?: string };
  testNotification?: unknown;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const expected = Deno.env.get("PLAY_RTDN_SECRET");
  const given = new URL(req.url).searchParams.get("secret") ?? "";
  if (!expected || !timingSafeEqual(given, expected)) {
    return json({ error: "Forbidden" }, 403);
  }

  let note: DeveloperNotification;
  try {
    const envelope = await req.json() as { message?: { data?: string } };
    note = JSON.parse(atob(envelope.message?.data ?? ""));
  } catch {
    // Malformed: acknowledge so Pub/Sub does not redeliver it forever.
    console.error("play-rtdn: unreadable message");
    return json({ ok: true, ignored: "unreadable" });
  }

  if (note.packageName && note.packageName !== PACKAGE_NAME) {
    return json({ ok: true, ignored: "other package" });
  }
  if (note.testNotification) {
    console.log("play-rtdn: test notification received");
    return json({ ok: true, test: true });
  }

  const admin = adminClient();
  try {
    const voided = note.voidedPurchaseNotification?.purchaseToken;
    if (voided) {
      await voidPurchase(admin, voided);
      return json({ ok: true });
    }

    const token = note.subscriptionNotification?.purchaseToken;
    if (!token) return json({ ok: true, ignored: "no subscription token" });

    let sub;
    try {
      sub = await getSubscription(token);
    } catch (e) {
      if (e instanceof PlayApiError && e.isInvalidToken) return json({ ok: true, ignored: "unknown token" });
      throw e;
    }

    // Whose purchase is it? The row written when the app verified it, or, if
    // the app never got that far, the account id it attached at checkout.
    const { data: row } = await admin
      .from("purchases")
      .select("user_id")
      .eq("purchase_token", token)
      .maybeSingle();
    const userId = row?.user_id ?? sub.externalAccountIdentifiers?.obfuscatedExternalAccountId;
    if (!userId) return json({ ok: true, ignored: "no known owner" });

    const { data: owner } = await admin.auth.admin.getUserById(userId);
    if (!owner?.user) return json({ ok: true, ignored: "owner deleted" });

    await applySubscription(admin, userId, token, sub);
    return json({ ok: true });
  } catch (e) {
    // Non-2xx makes Pub/Sub retry later, which is what a transient failure needs.
    console.error("play-rtdn error:", e);
    return json({ error: "retry" }, 500);
  }
});

function timingSafeEqual(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

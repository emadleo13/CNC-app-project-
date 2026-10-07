import { adminClient, requireUser } from "../_shared/auth.ts";
import { applySubscription } from "../_shared/entitlement.ts";
import {
  acknowledgeSubscription,
  getSubscription,
  hasServiceAccount,
  PlayApiError,
  PRO_PRODUCT_IDS,
} from "../_shared/google_play.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";

interface VerifyRequest {
  purchaseToken: string;
  productId:     string;
  platform:      "android" | "ios";
}

// Verifies a Google Play subscription with the Play Developer API and, if it is
// paid for, grants Pro until Google's expiry time. Called by the app after a
// purchase and whenever it finds an existing purchase on the device (restore,
// app start), so renewals and reinstalls keep working.
Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;

  try {
    const user = await requireUser(req);
    if (user instanceof Response) return user;

    const body: VerifyRequest = await req.json();
    const { purchaseToken, productId, platform = "android" } = body;

    if (!purchaseToken || !productId) {
      return error(400, "bad_request", "Missing purchase data");
    }
    if (platform !== "android") {
      return error(400, "bad_request", "Unsupported platform");
    }
    if (!PRO_PRODUCT_IDS.includes(productId)) {
      return error(400, "bad_request", "Invalid product");
    }
    if (!hasServiceAccount()) {
      // Fail closed. Never grant Pro from a token we cannot check.
      console.error("verify-purchase: GOOGLE_PLAY_SERVICE_ACCOUNT_KEY is not set");
      return error(503, "verification_unavailable", "Purchase verification is not configured");
    }

    let sub;
    try {
      sub = await getSubscription(purchaseToken);
    } catch (e) {
      if (e instanceof PlayApiError && e.isInvalidToken) {
        return error(402, "invalid_purchase", "Purchase verification failed");
      }
      throw e;
    }

    const lineItem = sub.lineItems?.find((li) => li.productId === productId);
    if (!lineItem) {
      return error(402, "invalid_purchase", "Purchase does not match product");
    }

    const admin = adminClient();
    const ent = await applySubscription(admin, user.id, purchaseToken, sub);

    if (ent.active && sub.acknowledgementState === "ACKNOWLEDGEMENT_STATE_PENDING") {
      try {
        await acknowledgeSubscription(productId, purchaseToken);
      } catch (e) {
        // The app acknowledges too (completePurchase); log and carry on.
        console.error("verify-purchase acknowledge failed:", e);
      }
    }

    if (!ent.active) {
      // A real token that is no longer paid for (expired, on hold, pending).
      return error(402, "not_active", "Subscription is not active", {
        state: ent.state,
        expires_at: ent.expiresAt?.toISOString() ?? null,
      });
    }

    return json({
      success:    true,
      tier:       "pro",
      expires_at: ent.expiresAt!.toISOString(),
    });
  } catch (e) {
    return internalError("verify-purchase", e);
  }
});

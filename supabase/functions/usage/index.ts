import { adminClient, requireUser } from "../_shared/auth.ts";
import { isPro } from "../_shared/entitlement.ts";
import { internalError, json, preflight } from "../_shared/http.ts";
import { deviceHash, FREE_MONTHLY_LIMIT, monthlyUsage } from "../_shared/quota.ts";

// The caller's AI usage this month, counted exactly as the quota counts it:
// the account's calls or the device's. The app cannot count the device's
// calls itself, because after a reinstall they belong to an earlier account
// it cannot read.
Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;

  try {
    const user = await requireUser(req);
    if (user instanceof Response) return user;

    const admin = adminClient();
    const [pro, used] = await Promise.all([
      isPro(admin, user.id),
      deviceHash(req).then((device) => monthlyUsage(admin, { userId: user.id, device })),
    ]);
    return json({ used, limit: FREE_MONTHLY_LIMIT, pro });
  } catch (e) {
    return internalError("usage", e);
  }
});

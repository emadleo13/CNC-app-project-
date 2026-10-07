// Checks that a Google Play service-account key can call the Play Developer
// API for this app, before the key goes into Supabase. Runs on your own
// machine; the key file never leaves it.
//
//   npx deno run --allow-read --allow-env --allow-net \
//     supabase/scripts/check_play_access.ts /path/to/service-account.json
//
// It asks Google about a made-up purchase token. With working access Google
// answers "invalid token" (HTTP 400/404/410), which is the expected result.
// "Insufficient permissions" (401/403) means the Play Console invitation has
// not taken effect yet. That can take up to a day; editing and saving any
// in-app product in Play Console sometimes makes it apply sooner.
import { getSubscription, PACKAGE_NAME, PlayApiError } from "../functions/_shared/google_play.ts";

const path = Deno.args[0];
if (!path) {
  console.error("usage: check_play_access.ts <service-account.json>");
  Deno.exit(2);
}

const raw = await Deno.readTextFile(path);
const key = JSON.parse(raw) as { client_email?: string; private_key?: string };
if (!key.client_email || !key.private_key) {
  console.error("✗ This is not a service-account JSON key (client_email / private_key missing).");
  Deno.exit(1);
}
Deno.env.set("GOOGLE_PLAY_SERVICE_ACCOUNT_KEY", raw);
console.log(`service account: ${key.client_email}`);
console.log(`package:         ${PACKAGE_NAME}`);

try {
  await getSubscription("cnc-assist-access-check-not-a-real-token");
  console.log("? Google accepted a made-up token, which should not happen. Check the package name.");
  Deno.exit(1);
} catch (e) {
  if (e instanceof PlayApiError && e.isInvalidToken) {
    console.log("✓ Access works: Google rejected the made-up token, as expected.");
    console.log("  Next: put the same JSON into the Supabase secret GOOGLE_PLAY_SERVICE_ACCOUNT_KEY.");
    Deno.exit(0);
  }
  if (e instanceof PlayApiError && (e.status === 401 || e.status === 403)) {
    console.log(`✗ Google says the account lacks permission (HTTP ${e.status}).`);
    console.log("  Check Play Console → Users and permissions: the service account must be invited");
    console.log("  with 'View financial data' and 'Manage orders and subscriptions' for this app.");
    console.log("  A fresh invitation can take up to 24 hours to apply.");
    console.log(`  Google said: ${e.body.slice(0, 300)}`);
    Deno.exit(1);
  }
  console.log(`✗ Unexpected failure: ${e instanceof Error ? e.message : e}`);
  console.log("  If this mentions the API being disabled, enable 'Google Play Android Developer API'");
  console.log("  in Google Cloud Console for the project that owns the service account.");
  Deno.exit(1);
}

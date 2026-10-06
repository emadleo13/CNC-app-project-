import { adminClient, requireUser } from "../_shared/auth.ts";
import { error, internalError, json, preflight } from "../_shared/http.ts";

// Permanently deletes the calling user's account and all owned data.
// Google Play requires apps with account creation to offer in-app deletion.
//
// This does not cancel a Google Play subscription; billing stays with Google
// and the user cancels it in the Play Store.
Deno.serve(async (req) => {
  const pre = preflight(req);
  if (pre) return pre;

  try {
    const user = await requireUser(req);
    if (user instanceof Response) return user;

    const admin = adminClient();

    // Delete owned data. Tables that reference auth.users or profiles with
    // ON DELETE CASCADE (profiles, gcode_analyses, saved_calculations,
    // qa_sessions, purchases) go with the auth user; qa_logs has no foreign
    // key, so it is cleared explicitly. Add any future user-scoped table here.
    await admin.from("qa_logs").delete().eq("user_id", user.id);
    await admin.from("profiles").delete().eq("id", user.id);

    // Delete the auth user. This is irreversible.
    const { error: delError } = await admin.auth.admin.deleteUser(user.id);
    if (delError) {
      console.error("delete-account deleteUser failed:", delError);
      return error(500, "internal", "Account deletion failed");
    }

    return json({ success: true });
  } catch (e) {
    return internalError("delete-account", e);
  }
});

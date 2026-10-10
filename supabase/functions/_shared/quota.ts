// Free-tier AI quota, counted and written only with the service role.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { error } from "./http.ts";

export const FREE_MONTHLY_LIMIT = 10;

/// Usage rows of deleted accounts keep this user_id: they belong to no one,
/// but still count for their device until the month is over.
export const DELETED_USER = "00000000-0000-0000-0000-000000000000";

export interface UsageMeta {
  question_excerpt:   string;
  had_alarm_context?: boolean;
  is_image?:          boolean;
}

/// Who is asking: the anonymous account and the device.
///
/// Reinstalling the app creates a new anonymous account, so counting accounts
/// alone gave ten more free questions per reinstall. The app sends its
/// app-scoped Android ID, which survives a reinstall (only a factory reset
/// changes it), and the quota counts the account's rows or the device's.
export interface Caller {
  userId: string;
  /// SHA-256 of the Android ID; null from app versions up to 1.3.1.
  device: string | null;
}

/// First moment of the current month (UTC), the quota's window.
export function monthStart(now = new Date()): string {
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1)).toISOString();
}

/// Hashes the `x-device-id` header the app sends. The raw ID is never stored.
/// A missing or malformed header gives null: the account alone is counted.
export async function deviceHash(req: Request): Promise<string | null> {
  const id = req.headers.get("x-device-id")?.trim();
  if (!id || !/^[A-Za-z0-9._-]{4,128}$/.test(id)) return null;
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(`cnc-assist-device:${id.toLowerCase()}`),
  );
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

/// AI calls this month by the caller's account or on the caller's device.
export async function monthlyUsage(admin: SupabaseClient, caller: Caller): Promise<number> {
  let query = admin
    .from("qa_logs")
    .select("id", { count: "exact", head: true })
    .gte("created_at", monthStart());
  // device is lowercase hex from deviceHash(), safe inside the filter string.
  query = caller.device
    ? query.or(`user_id.eq.${caller.userId},device_hash.eq.${caller.device}`)
    : query.eq("user_id", caller.userId);
  const { count, error: countError } = await query;
  if (countError) throw countError;
  return count ?? 0;
}

/// Checks the monthly quota and, if there is room, records the call up front.
/// Recording before calling the model means a burst of parallel requests
/// cannot all slip under the limit. Pass the returned id to [settleUsage] or
/// [releaseUsage].
///
/// Pro users are not limited but are still logged, for cost tracking.
export async function reserveUsage(
  admin: SupabaseClient,
  caller: Caller,
  pro: boolean,
  meta: UsageMeta,
): Promise<{ logId: string } | Response> {
  if (!pro) {
    const used = await monthlyUsage(admin, caller);
    if (used >= FREE_MONTHLY_LIMIT) {
      // quota_exceeded stays in the body: app versions up to 1.1.6 look for it.
      return error(429, "quota_exceeded", "Monthly quota exceeded", {
        quota_exceeded: true,
        used,
        limit:     FREE_MONTHLY_LIMIT,
        remaining: 0,
      });
    }
  }

  const { data, error: insertError } = await admin
    .from("qa_logs")
    .insert({
      user_id:           caller.userId,
      device_hash:       caller.device,
      question_excerpt:  meta.question_excerpt.substring(0, 300),
      had_alarm_context: meta.had_alarm_context ?? false,
      is_image:          meta.is_image ?? false,
    })
    .select("id")
    .single();
  if (insertError) throw insertError;
  return { logId: data.id as string };
}

/// Stores the token count once the model has answered.
export async function settleUsage(admin: SupabaseClient, logId: string, tokens: number): Promise<void> {
  const { error: e } = await admin.from("qa_logs").update({ token_count: tokens }).eq("id", logId);
  if (e) console.error("settleUsage failed:", e);
}

/// Gives the call back when the model failed, so an outage does not use up
/// the user's free questions.
export async function releaseUsage(admin: SupabaseClient, logId: string): Promise<void> {
  const { error: e } = await admin.from("qa_logs").delete().eq("id", logId);
  if (e) console.error("releaseUsage failed:", e);
}

/// Removes a deleted account's usage. Earlier months and rows without a
/// device go. This month's rows from a device lose their text and their link
/// to the account but stay, so deleting the account does not reset the
/// device's free questions. Rows left that way by earlier deletions are
/// purged once their month is over.
export async function forgetUsage(admin: SupabaseClient, userId: string): Promise<void> {
  const since = monthStart();
  const steps = [
    () => admin.from("qa_logs").delete().eq("user_id", userId).lt("created_at", since),
    () => admin.from("qa_logs").delete().eq("user_id", userId).is("device_hash", null),
    () => admin.from("qa_logs").update({ user_id: DELETED_USER, question_excerpt: null }).eq("user_id", userId),
    () => admin.from("qa_logs").delete().eq("user_id", DELETED_USER).lt("created_at", since),
  ];
  for (const step of steps) {
    const { error: e } = await step();
    if (e) throw e;
  }
}

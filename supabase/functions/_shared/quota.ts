// Free-tier AI quota, counted and written only with the service role.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { error } from "./http.ts";

export const FREE_MONTHLY_LIMIT = 10;

export interface UsageMeta {
  question_excerpt:   string;
  had_alarm_context?: boolean;
  is_image?:          boolean;
}

/// Checks the monthly quota and, if there is room, records the call up front.
/// Recording before calling the model means a burst of parallel requests
/// cannot all slip under the limit. Pass the returned id to [settleUsage] or
/// [releaseUsage].
///
/// Pro users are not limited but are still logged, for cost tracking.
export async function reserveUsage(
  admin: SupabaseClient,
  userId: string,
  pro: boolean,
  meta: UsageMeta,
): Promise<{ logId: string } | Response> {
  if (!pro) {
    const now = new Date();
    const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1)).toISOString();
    const { count, error: countError } = await admin
      .from("qa_logs")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .gte("created_at", monthStart);
    if (countError) throw countError;
    const used = count ?? 0;
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
      user_id:           userId,
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

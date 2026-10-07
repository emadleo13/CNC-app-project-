// Caller identification and the service-role client.
import { createClient, type SupabaseClient, type User } from "npm:@supabase/supabase-js@2";
import { error } from "./http.ts";

let admin: SupabaseClient | null = null;

/// Service-role client. It bypasses RLS, so it is the only thing that writes
/// usage logs, purchases and subscription fields; the migrations deny those to
/// app users.
export function adminClient(): SupabaseClient {
  admin ??= createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
  return admin;
}

/// Resolves the signed-in (or anonymous) user from the request's JWT, or
/// returns the 401 response to send back.
export async function requireUser(req: Request): Promise<User | Response> {
  const header = req.headers.get("Authorization");
  if (!header?.startsWith("Bearer ")) {
    return error(401, "unauthorized", "Missing authorization header");
  }
  const { data, error: authError } = await adminClient().auth.getUser(header.slice(7));
  if (authError || !data.user) {
    return error(401, "unauthorized", "Unauthorized");
  }
  return data.user;
}

// Response helpers shared by every Edge Function.

export const corsHeaders = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/// Every error response carries a stable `code` the app maps to a translated
/// message. `error` stays human-readable for logs and older app versions.
export function error(status: number, code: string, message: string, extra: Record<string, unknown> = {}): Response {
  return json({ error: message, code, ...extra }, status);
}

export function preflight(req: Request): Response | null {
  return req.method === "OPTIONS" ? new Response("ok", { headers: corsHeaders }) : null;
}

/// Logs the real cause server-side and returns a generic 500. Internal error
/// text (model IDs, provider responses, SQL) is not sent to the client.
export function internalError(fn: string, e: unknown): Response {
  console.error(`${fn} error:`, e);
  return error(500, "internal", "Internal server error");
}

import { llmComplete } from "../_shared/llm.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ToolingRequest {
  material:      string;
  operation:     string;
  diameter:      number;
  units:         "metric" | "imperial";
  toolMaterial?: string;
  depthOfCut?:   number;
  widthOfCut?:   number;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")      ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Pro feature — check subscription
    const { data: profile } = await supabase
      .from("profiles")
      .select("subscription_tier")
      .eq("id", user.id)
      .single();

    const isPro = profile?.subscription_tier === "pro" || profile?.subscription_tier === "team";
    if (!isPro) {
      return new Response(JSON.stringify({ error: "Pro subscription required", pro_required: true }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body: ToolingRequest = await req.json();
    const { material, operation, diameter, units, toolMaterial, depthOfCut, widthOfCut } = body;

    const unitStr = units === "imperial" ? "inches" : "mm";
    const prompt  = `I need tooling recommendations for this CNC milling operation:
- Material: ${material}
- Operation: ${operation}
- Tool diameter: ${diameter} ${unitStr}
- Tool material: ${toolMaterial ?? "carbide"}
- Depth of cut: ${depthOfCut ?? "??"} ${unitStr}
- Width of cut: ${widthOfCut ?? "??"} ${unitStr}

Please recommend:
1. **Specific tool geometry** (flutes, helix angle, coating, edge prep)
2. **Top 2-3 brand/grade recommendations** (e.g., Sandvik, Kennametal, Walter, Iscar)
3. **Why these specs suit this material + operation**
4. **One alternative budget option**

Be specific with product codes where possible. Keep it practical for a shop floor operator.`;

    const { text: answer } = await llmComplete({
      parts:          [{ kind: "text", text: prompt }],
      maxTokens:      1200,
      anthropicModel: "claude-haiku-4-5-20251001",
    });

    return new Response(JSON.stringify({ answer }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("tooling-recs error:", error);
    return new Response(JSON.stringify({
      error:  "Internal server error",
      detail: error instanceof Error ? error.message : String(error),
    }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

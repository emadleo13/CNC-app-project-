import Anthropic from "npm:@anthropic-ai/sdk@0.30.0";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const FREE_LIMIT = 10;

interface AskRequest {
  question:      string;
  alarmContext?: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
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

    // Check subscription tier and enforce quota
    const { data: profile } = await supabase
      .from("profiles")
      .select("subscription_tier")
      .eq("id", user.id)
      .single();

    const isPro = profile?.subscription_tier === "pro" || profile?.subscription_tier === "team";

    if (!isPro) {
      const monthStart = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString();
      const { count }  = await supabase
        .from("qa_logs")
        .select("*", { count: "exact", head: true })
        .eq("user_id", user.id)
        .gte("created_at", monthStart);

      if ((count ?? 0) >= FREE_LIMIT) {
        return new Response(JSON.stringify({
          error:          "Monthly quota exceeded",
          quota_exceeded: true,
          used:           count ?? FREE_LIMIT,
          limit:          FREE_LIMIT,
          remaining:      0,
        }), {
          status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    const body: AskRequest = await req.json();
    const { question, alarmContext } = body;

    if (!question || question.trim().length === 0) {
      return new Response(JSON.stringify({ error: "No question provided" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (question.length > 2000) {
      return new Response(JSON.stringify({ error: "Question too long. Max 2000 characters." }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const contextBlock = alarmContext
      ? `\n\nThe app has found the following alarm data from its local database relevant to this question:\n${alarmContext}Use this data to provide a specific, accurate answer about this alarm code.`
      : "";

    const systemPrompt =
      "You are an expert CNC machining assistant for an app used by machine operators and programmers. " +
      "You specialize in:\n" +
      "- Haas CNC controllers (VF series, ST series, DC series) — alarms, programming, operation\n" +
      "- Siemens Sinumerik 840D sl / 828D — alarms, cycles (CYCLE81–CYCLE840), machine data\n" +
      "- FANUC Series 0i/16i/18i/21i/31i — alarms, parameters, PMC\n" +
      "- Heidenhain TNC 640/530/426 — alarms, cycles, conversational programming\n" +
      "- G-code programming (ISO 6983, Haas dialect, Sinumerik dialect)\n" +
      "- Feed and speed calculations (Vc, RPM, chip load, MRR)\n" +
      "- CNC troubleshooting — servo faults, spindle issues, ATC faults, parameter errors\n" +
      "- Tooling — carbide/HSS endmills, drills, inserts, taps\n\n" +
      "Guidelines:\n" +
      "- Be concise and practical — operators need quick, actionable answers\n" +
      "- When answering about alarm codes: what it means, top 2–3 likely causes, first steps to resolve\n" +
      "- Format code with triple backticks and specify the dialect\n" +
      "- If a question involves safety risks, mention them clearly\n" +
      "- When uncertain, say so — do not guess critical safety or machine-specific information\n" +
      contextBlock;

    const client = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") ?? "" });

    const message = await client.messages.create({
      model:      "claude-haiku-4-5-20251001",
      max_tokens: 1024,
      system:     systemPrompt,
      messages:   [{ role: "user", content: question }],
    });

    const answer = message.content[0].type === "text" ? message.content[0].text : "";

    // Log usage (async — non-blocking)
    supabase.from("qa_logs").insert({
      user_id:            user.id,
      question_excerpt:   question.substring(0, 300),
      had_alarm_context:  !!alarmContext,
      token_count:        message.usage.input_tokens + message.usage.output_tokens,
      is_image:           false,
    }).then(() => {}).catch(console.error);

    return new Response(JSON.stringify({ answer }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

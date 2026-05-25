import Anthropic from "npm:@anthropic-ai/sdk@0.30.0";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const FREE_LIMIT = 10;

interface AnalyzeImageRequest {
  imageBase64: string;
  mediaType:   "image/jpeg" | "image/png" | "image/webp";
  mode:        "error_diagnosis" | "drawing_to_gcode";
  question?:   string;
  dialect?:    string;
}

const ERROR_SYSTEM = `You are an expert CNC machine technician and controller specialist.
The user will show you a photo of a CNC machine control panel, screen, or display showing an error, alarm, or fault message.

Your task:
1. Identify the exact alarm code and message visible in the image
2. Explain clearly what this alarm means
3. List the 2-3 most likely causes
4. Provide step-by-step troubleshooting instructions
5. Note any safety considerations before attempting repair

Be specific and practical — operators need to resolve this quickly.
If the image is unclear or doesn't show a CNC alarm, say so and ask for a clearer photo.
Format your response with clear sections: Alarm Identified / What It Means / Likely Causes / How to Fix / Safety Notes.`;

const DRAWING_SYSTEM = `You are an expert CNC programmer with deep knowledge of Haas and Siemens Sinumerik controllers.
The user will show you a technical drawing, engineering sketch, or photo of a machined part.

Your task:
1. Analyze visible dimensions, tolerances, surface finish requirements, and features
2. Generate a complete, ready-to-run CNC G-code program for machining this part
3. Use the dialect specified by the user (Haas or Sinumerik)
4. Include:
   - Program header with setup notes
   - Tool list with recommended types (endmill, drill, etc.)
   - Work offset setup (G54)
   - Spindle speeds and feed rates (suggest based on steel/aluminum)
   - Operations in logical order (roughing → finishing → holes)
   - Program footer with tool retract and spindle stop

Format the G-code cleanly with inline comments on each line.
State assumptions if dimensions are not fully visible.
If the image is not a technical drawing or part photo, ask the user to provide one.`;

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

    // Check subscription + quota (image calls count toward free limit)
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

    const body: AnalyzeImageRequest = await req.json();
    const { imageBase64, mediaType = "image/jpeg", mode, question, dialect = "haas" } = body;

    if (!imageBase64 || imageBase64.length === 0) {
      return new Response(JSON.stringify({ error: "No image provided" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (imageBase64.length > 7_000_000) {
      return new Response(JSON.stringify({ error: "Image too large. Please use a smaller photo." }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const isError   = mode === "error_diagnosis";
    const maxTokens = isError ? 1024 : 4096;
    const system    = isError ? ERROR_SYSTEM : DRAWING_SYSTEM;

    const userText = isError
      ? (question?.trim() || "What CNC alarm or error is shown in this image? Diagnose it and provide solutions.")
      : `Generate ${dialect.toUpperCase()} G-code for the part shown in this technical drawing.`;

    const client = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") ?? "" });

    const message = await client.messages.create({
      model:      "claude-sonnet-4-6",
      max_tokens: maxTokens,
      system,
      messages: [{
        role:    "user",
        content: [
          {
            type:   "image",
            source: { type: "base64", media_type: mediaType, data: imageBase64 },
          },
          { type: "text", text: userText },
        ],
      }],
    });

    const answer = message.content[0].type === "text" ? message.content[0].text : "";

    // Log usage
    supabase.from("qa_logs").insert({
      user_id:           user.id,
      question_excerpt:  `[image:${mode}] ${userText.substring(0, 100)}`,
      had_alarm_context: false,
      is_image:          true,
      token_count:       message.usage.input_tokens + message.usage.output_tokens,
    }).then(() => {}).catch(console.error);

    return new Response(JSON.stringify({ answer }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("analyze-image error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

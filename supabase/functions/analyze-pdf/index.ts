import { llmComplete } from "../_shared/llm.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface PdfRequest {
  pdfBase64: string;
  question?: string;
  dialect?:  string;
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

    // Pro feature check
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

    const body: PdfRequest = await req.json();
    const { pdfBase64, question, dialect = "haas" } = body;

    if (!pdfBase64 || pdfBase64.length === 0) {
      return new Response(JSON.stringify({ error: "No PDF provided" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ~10MB limit for PDF base64
    if (pdfBase64.length > 14_000_000) {
      return new Response(JSON.stringify({ error: "PDF too large. Max 10MB." }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userQuestion = question?.trim() ||
      `Analyze this technical drawing and generate ${dialect.toUpperCase()} G-code for machining the part shown. Include tool list, work offsets, feeds and speeds.`;

    const systemPrompt =
      "You are an expert CNC programmer analyzing technical drawings and engineering documents.\n" +
      "When given a technical drawing or part specification:\n" +
      "1. Identify visible dimensions, tolerances, surface finish, and features\n" +
      "2. Generate a complete CNC G-code program (well-commented, ready to run)\n" +
      "3. Include: program header, tool list, work offset setup, operations in order, footer\n" +
      "4. State assumptions clearly when dimensions are not visible\n" +
      "If not a technical drawing, extract and summarize CNC-relevant information.";

    const { text: answer, tokens } = await llmComplete({
      system: systemPrompt,
      parts: [
        { kind: "pdf",  data: pdfBase64 },
        { kind: "text", text: userQuestion },
      ],
      maxTokens:      4096,
      anthropicModel: "claude-sonnet-4-6",
    });

    // Log usage
    supabase.from("qa_logs").insert({
      user_id:           user.id,
      question_excerpt:  `[pdf] ${userQuestion.substring(0, 200)}`,
      is_image:          true,
      token_count:       tokens,
    }).then(() => {}).catch(console.error);

    return new Response(JSON.stringify({ answer }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("analyze-pdf error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

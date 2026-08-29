import { llmComplete } from "../_shared/llm.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface AnalyzeRequest {
  gcode:    string;
  dialect:  "haas" | "sinumerik" | "generic";
  context?: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Validate JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body: AnalyzeRequest = await req.json();
    const { gcode, dialect = "haas" } = body;

    if (!gcode || gcode.trim().length === 0) {
      return new Response(JSON.stringify({ error: "No G-code provided" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Limit input size to prevent abuse (max 50KB of G-code)
    if (gcode.length > 50000) {
      return new Response(JSON.stringify({ error: "G-code too large. Max 50KB per request." }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const dialectGuide = dialect === "sinumerik"
      ? `You are analyzing Siemens Sinumerik 840D/828D G-code.
Key Sinumerik specifics:
- Cycles: CYCLE81 (drilling), CYCLE82 (drilling+dwell), CYCLE83 (deep hole peck), CYCLE84 (rigid tapping), CYCLE840 (flexible tapping)
- Variables: DEF REAL/INT/BOOL/STRING, accessed via variable name
- Transformations: TRANS, ATRANS, ROT, AROT, SCALE, MIRROR
- Jumps: GOTOB (backward), GOTOF (forward), labels end with ':'
- Tool change: T1 D1 (T=tool, D=cutting edge)
- Subroutines: PROC name / ENDPROC`
      : `You are analyzing Haas CNC G-code (compatible with Fanuc ISO standard).
Key Haas specifics:
- Tool change: T1 M6 (M6 executes the change)
- Tool length: G43 H# (H matches tool number)
- Subprograms: M98 P#### (call), M99 (return)
- Macro variables: #1-#33 (local), #100-#199 (global retained), #500-#999 (global saved)
- Haas-specific: M136 (inch per rev tapping), M154/M155 (pallet control)`;

    const systemPrompt = `${dialectGuide}

Analyze the G-code and respond with a valid JSON object using EXACTLY this structure:
{
  "summary": "One paragraph describing what this CNC program does",
  "operation_type": "milling|turning|drilling|tapping|multi",
  "estimated_runtime_minutes": null,
  "lines": [
    {
      "line_number": 1,
      "original": "exact line text",
      "explanation": "What this line does in plain language",
      "severity": "ok|warning|error",
      "issue": "Description of the problem (only if warning/error, else omit)",
      "suggestion": "How to fix it (only if error, else omit)"
    }
  ],
  "overall_issues": ["list of significant issues found"],
  "suggestions": ["list of optimization recommendations"]
}

Rules:
- Every line in the program must appear in "lines" array, including empty lines and comments
- Be thorough but concise in explanations
- Flag potential crashes, wrong tool calls, missing retracts as errors
- Flag suboptimal feeds, missing G-codes as warnings
- DO NOT include markdown or text outside the JSON`;

    const { text: responseText, tokens } = await llmComplete({
      system: systemPrompt,
      parts:  [{ kind: "text", text: `Analyze this ${dialect.toUpperCase()} G-code program:\n\n${gcode}` }],
      maxTokens:      8192,
      anthropicModel: "claude-sonnet-4-6",
    });

    // Extract JSON from response
    let analysisJson: Record<string, unknown>;

    try {
      // Handle case where Claude wraps JSON in markdown code blocks
      const jsonMatch = responseText.match(/```(?:json)?\s*([\s\S]+?)\s*```/) ||
                        responseText.match(/(\{[\s\S]+\})/);
      const jsonStr = jsonMatch ? jsonMatch[1] : responseText;
      analysisJson = JSON.parse(jsonStr);
    } catch {
      return new Response(JSON.stringify({
        error:    "Failed to parse AI response",
        raw:      responseText.substring(0, 500),
      }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    }

    // Log token usage for cost tracking (async, don't await)
    supabase.from("gcode_analyses").insert({
      user_id:       user.id,
      gcode_content: gcode,
      dialect:       dialect,
      analysis_json: analysisJson,
      error_count:   (analysisJson.lines as Array<{severity: string}>)?.filter(l => l.severity === "error").length ?? 0,
      warning_count: (analysisJson.lines as Array<{severity: string}>)?.filter(l => l.severity === "warning").length ?? 0,
      line_count:    (analysisJson.lines as unknown[])?.length ?? 0,
      token_count:   tokens,
    }).then(() => {}).catch(console.error);

    return new Response(JSON.stringify(analysisJson), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(JSON.stringify({
      error:  "Internal server error",
      detail: error instanceof Error ? error.message : String(error),
    }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

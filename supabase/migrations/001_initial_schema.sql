-- CNC Assist - Initial Schema
-- Run this in your Supabase project SQL editor

-- User profiles (extends auth.users)
CREATE TABLE public.profiles (
    id                    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email                 TEXT NOT NULL,
    display_name          TEXT,
    subscription_tier     TEXT NOT NULL DEFAULT 'free'
                              CHECK (subscription_tier IN ('free', 'pro', 'team')),
    subscription_expires_at TIMESTAMPTZ,
    preferred_dialect     TEXT DEFAULT 'haas'
                              CHECK (preferred_dialect IN ('haas', 'sinumerik', 'generic')),
    preferred_units       TEXT DEFAULT 'metric'
                              CHECK (preferred_units IN ('metric', 'imperial')),
    language              TEXT DEFAULT 'en',
    created_at            TIMESTAMPTZ DEFAULT NOW(),
    updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email)
    VALUES (NEW.id, NEW.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- G-code analysis history
CREATE TABLE public.gcode_analyses (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title         TEXT NOT NULL DEFAULT 'Untitled Program',
    gcode_content TEXT NOT NULL,
    dialect       TEXT NOT NULL DEFAULT 'haas',
    analysis_json JSONB,
    error_count   INTEGER DEFAULT 0,
    warning_count INTEGER DEFAULT 0,
    line_count    INTEGER DEFAULT 0,
    token_count   INTEGER,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gcode_analyses_user_created
    ON public.gcode_analyses(user_id, created_at DESC);

-- Saved Feed/Speed calculations
CREATE TABLE public.saved_calculations (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name          TEXT,
    material_code TEXT NOT NULL,
    tool_type     TEXT NOT NULL,
    tool_diameter DECIMAL(8,3),
    flutes        INTEGER,
    operation     TEXT NOT NULL,
    depth_of_cut  DECIMAL(8,3),
    width_of_cut  DECIMAL(8,3),
    result_rpm    INTEGER,
    result_feed   DECIMAL(10,3),
    result_mrr    DECIMAL(10,4),
    units         TEXT DEFAULT 'metric',
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Q&A sessions history
CREATE TABLE public.qa_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    question        TEXT NOT NULL,
    answer          TEXT NOT NULL,
    source_chunks   JSONB,
    dialect_context TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE public.profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gcode_analyses   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_calculations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qa_sessions      ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own profile"
    ON public.profiles FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users manage own analyses"
    ON public.gcode_analyses FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users manage own calculations"
    ON public.saved_calculations FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users manage own qa sessions"
    ON public.qa_sessions FOR ALL USING (auth.uid() = user_id);

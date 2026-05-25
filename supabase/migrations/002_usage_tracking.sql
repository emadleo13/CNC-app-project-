-- 002_usage_tracking.sql
-- AI usage logging for freemium quota enforcement

CREATE TABLE IF NOT EXISTS public.qa_logs (
    id                UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID    NOT NULL,
    question_excerpt  TEXT,
    had_alarm_context BOOLEAN DEFAULT FALSE,
    is_image          BOOLEAN DEFAULT FALSE,
    token_count       INTEGER,
    created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_qa_logs_user_month
    ON public.qa_logs(user_id, created_at DESC);

ALTER TABLE public.qa_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own qa_logs"
    ON public.qa_logs FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role inserts qa_logs"
    ON public.qa_logs FOR INSERT WITH CHECK (true);

-- Fix handle_new_user to support anonymous auth (NULL email)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email)
    VALUES (NEW.id, COALESCE(NEW.email, ''))
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper: count current-month AI calls for a user
CREATE OR REPLACE FUNCTION public.get_monthly_usage(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM   public.qa_logs
    WHERE  user_id    = p_user_id
      AND  date_trunc('month', created_at) = date_trunc('month', NOW());
    RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

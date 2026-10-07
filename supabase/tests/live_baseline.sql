-- What the live project (colahcvziorjkqckqdlt) looked like before migration
-- 003, as read from it on 2026-10-07. Limited to the objects 003 could
-- interact with. The test applies this, then 003, and checks both apps.
--
-- Shared with another app: profiles, handle_new_user and bookings are THAT
-- app's. qa_logs and get_monthly_usage are CNC Assist's.

-- ── the other app ──────────────────────────────────────────────────────────
create table public.profiles (
    id          uuid primary key,
    full_name   text,
    phone       text,
    avatar_url  text,
    notes       text,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);
alter table public.profiles enable row level security;
create policy "profiles self insert" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles self read"   on public.profiles for select using (auth.uid() = id);
create policy "profiles self update" on public.profiles for update using (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
exception when others then
  raise warning 'handle_new_user failed for %: %', new.id, sqlerrm;
  return new;
end;
$function$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

create table public.bookings (
    id         uuid primary key default gen_random_uuid(),
    user_id    uuid,
    note       text,
    created_at timestamptz not null default now()
);
alter table public.bookings enable row level security;
create policy "bookings owner read"    on public.bookings for select using (user_id = auth.uid());
create policy "bookings owner update"  on public.bookings for update using (user_id = auth.uid());
create policy "bookings public insert" on public.bookings for insert with check (true);

-- ── CNC Assist (from 002) ──────────────────────────────────────────────────
create table public.qa_logs (
    id                uuid primary key default gen_random_uuid(),
    user_id           uuid not null,
    question_excerpt  text,
    had_alarm_context boolean default false,
    is_image          boolean default false,
    token_count       integer,
    created_at        timestamptz default now()
);
create index idx_qa_logs_user_month on public.qa_logs(user_id, created_at desc);
alter table public.qa_logs enable row level security;
create policy "Users read own qa_logs" on public.qa_logs for select using (auth.uid() = user_id);
create policy "Service role inserts qa_logs" on public.qa_logs for insert with check (true);

create or replace function public.get_monthly_usage(p_user_id uuid)
returns integer as $$
declare v_count integer;
begin
    select count(*) into v_count from public.qa_logs
    where user_id = p_user_id
      and date_trunc('month', created_at) = date_trunc('month', now());
    return coalesce(v_count, 0);
end;
$$ language plpgsql security definer;

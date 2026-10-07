// Applies the live baseline (live_baseline.sql, what production had before
// 003) and then migration 003 to an in-process Postgres (PGlite), with a
// stand-in for Supabase's auth schema and roles. Checks that the CNC holes are
// closed AND that the other app sharing the project still works.
// Fails (exit 1) if any expectation breaks.
//
//   cd supabase/tests && npm install && npm test
//   node rls_test.mjs --before     # same checks against the baseline alone
import { PGlite } from "@electric-sql/pglite";
import { readFileSync } from "node:fs";

const here = (p) => new URL(p, import.meta.url);
const before = process.argv.includes("--before");
const db = new PGlite();

// What Supabase provides before any migration runs.
await db.exec(`
  create role anon nologin;
  create role authenticated nologin;
  create role service_role nologin bypassrls;
  create schema auth;
  create table auth.users (id uuid primary key, email text, raw_user_meta_data jsonb default '{}');
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  grant usage on schema auth to anon, authenticated, service_role;
  grant execute on function auth.uid() to anon, authenticated, service_role;
  grant usage on schema public to anon, authenticated, service_role;
  alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
  alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
`);
await db.exec(readFileSync(here("./live_baseline.sql"), "utf8"));
if (!before) {
  const m = readFileSync(here("../migrations/003_security_hardening.sql"), "utf8");
  await db.exec(m);
  await db.exec(m); // must be safe to run twice
}

const A = "11111111-1111-1111-1111-111111111111";
const B = "22222222-2222-2222-2222-222222222222";
await db.exec(`insert into auth.users (id, email) values ('${A}', null), ('${B}', 'b@example.com');`);

async function as(role, user, sql) {
  try {
    await db.exec(`set role ${role}; select set_config('request.jwt.claim.sub', '${user ?? ""}', false);`);
    const r = await db.query(sql);
    return { ok: true, rows: r.rows.length || r.affectedRows || 0 };
  } catch (e) {
    return { ok: false, error: e.message };
  } finally {
    await db.exec("reset role;");
  }
}

let failures = 0;
async function expect(label, sql, want, { role = "authenticated", user = A } = {}) {
  const r = await as(role, user, sql);
  const got = !r.ok ? "denied" : r.rows > 0 ? "allowed" : "no rows";
  const pass = got === want;
  if (!pass) failures++;
  console.log(`${pass ? "ok  " : "FAIL"} ${label.padEnd(56)} ${got}${pass ? "" : `  (expected ${want})`}`);
}

if (!before) {
  // Edge Functions (service role) write the CNC tables.
  await db.exec(`set role service_role;
    insert into public.qa_logs(user_id, question_excerpt) values ('${A}','svc');
    insert into public.cnc_purchases(purchase_token,user_id,product_id,state,expires_at)
      values ('tok','${A}','cnc_assist_pro_monthly','SUBSCRIPTION_STATE_ACTIVE', now()+interval '30 days');
    insert into public.cnc_entitlements(user_id, tier, expires_at) values ('${A}','pro', now()+interval '30 days');
    insert into public.cnc_entitlements(user_id, tier, expires_at) values ('${B}','free', null);
    reset role;`);
}

console.log("— CNC Assist");
await expect("insert usage row for another user (burn quota)", `insert into public.qa_logs(user_id, question_excerpt) values ('${B}','x')`, "denied");
await expect("insert own usage row", `insert into public.qa_logs(user_id, question_excerpt) values ('${A}','x')`, "denied");
await expect("delete own usage rows (reset quota)", `delete from public.qa_logs where user_id='${A}'`, "denied");
await expect("anon key inserts a usage row", `insert into public.qa_logs(user_id, question_excerpt) values ('${B}','x')`, "denied", { role: "anon", user: null });
await expect("call get_monthly_usage(B)", `select public.get_monthly_usage('${B}')`, "denied");
if (!before) {
  await expect("read own usage rows written by the server", `select id from public.qa_logs where user_id='${A}'`, "allowed");
  await expect("read own entitlement", `select tier from public.cnc_entitlements where user_id='${A}'`, "allowed");
  await expect("read another user's entitlement", `select tier from public.cnc_entitlements where user_id='${B}'`, "no rows");
  await expect("grant self Pro (update entitlement)", `update public.cnc_entitlements set tier='pro', expires_at=now()+interval '9 years' where user_id='${B}'`, "denied", { user: B });
  await expect("insert own entitlement", `insert into public.cnc_entitlements(user_id,tier,expires_at) values ('${A}','pro',now())`, "denied");
  await expect("insert a purchase", `insert into public.cnc_purchases(purchase_token,user_id,product_id,state) values ('t','${A}','p','s')`, "denied");
  await expect("read purchases", `select * from public.cnc_purchases`, "denied");
}

console.log("— the other app (must be unchanged)");
await expect("read own profile", `select id from public.profiles where id='${A}'`, "allowed");
await expect("update own profile", `update public.profiles set full_name='Ann' where id='${A}'`, "allowed");
await expect("update another user's profile", `update public.profiles set full_name='x' where id='${B}'`, "no rows");
await expect("public booking insert (anon)", `insert into public.bookings(note) values ('hi')`, "allowed", { role: "anon", user: null });

await db.exec(`insert into auth.users (id, email, raw_user_meta_data) values ('33333333-3333-3333-3333-333333333333', 'c@example.com', '{"full_name":"Cy"}');`);
const made = (await db.query(`select full_name from public.profiles where id='33333333-3333-3333-3333-333333333333'`)).rows;
const trigOk = made.length === 1 && made[0].full_name === "Cy";
if (!trigOk) failures++;
console.log(`${trigOk ? "ok  " : "FAIL"} ${"sign-up trigger still creates the other app's profile".padEnd(56)}`);

if (failures) {
  console.error(`\n${failures} expectation(s) failed${before ? " (expected: --before shows the holes)" : ""}`);
  process.exit(1);
}
console.log("\nall expectations hold");

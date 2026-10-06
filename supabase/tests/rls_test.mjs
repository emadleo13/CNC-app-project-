// Applies every migration to an in-process Postgres (PGlite) with a stand-in
// for Supabase's auth schema and roles, then checks what an app user can and
// cannot do with the public anon key. Fails (exit 1) if any expectation breaks.
//
//   cd supabase/tests && npm install && npm test
import { PGlite } from "@electric-sql/pglite";
import { readdirSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const migrations = fileURLToPath(new URL("../migrations/", import.meta.url));
const db = new PGlite();

// What Supabase provides before any migration runs.
await db.exec(`
  create role anon nologin;
  create role authenticated nologin;
  create role service_role nologin bypassrls;
  create schema auth;
  create table auth.users (id uuid primary key, email text);
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  grant usage on schema auth to anon, authenticated, service_role;
  grant execute on function auth.uid() to anon, authenticated, service_role;
  grant usage on schema public to anon, authenticated, service_role;
  alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
  alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
`);
for (const f of readdirSync(migrations).filter((f) => f.endsWith(".sql")).sort()) {
  await db.exec(readFileSync(migrations + f, "utf8"));
}

const A = "11111111-1111-1111-1111-111111111111";
const B = "22222222-2222-2222-2222-222222222222";
await db.exec(`insert into auth.users values ('${A}', null), ('${B}', 'b@example.com');`);

async function asUser(user, sql) {
  try {
    await db.exec(`set role authenticated; select set_config('request.jwt.claim.sub', '${user}', false);`);
    const r = await db.query(sql);
    return { ok: true, rows: r.rows.length || r.affectedRows || 0 };
  } catch (e) {
    return { ok: false, error: e.message };
  } finally {
    await db.exec("reset role;");
  }
}

let failures = 0;
async function expect(label, sql, want) {
  const r = await asUser(A, sql);
  const got = !r.ok ? "denied" : r.rows > 0 ? "allowed" : "no rows";
  const pass = got === want;
  if (!pass) failures++;
  console.log(`${pass ? "ok  " : "FAIL"} ${label.padEnd(52)} ${got}${pass ? "" : `  (expected ${want})`}`);
}

await expect("grant self Pro", `update public.profiles set subscription_tier='pro' where id='${A}'`, "denied");
await expect("extend own expiry", `update public.profiles set subscription_expires_at=now()+interval '9 years' where id='${A}'`, "denied");
await expect("change own preferred_units", `update public.profiles set preferred_units='imperial' where id='${A}'`, "allowed");
await expect("change another user's profile", `update public.profiles set display_name='x' where id='${B}'`, "no rows");
await expect("read own profile", `select id from public.profiles where id='${A}'`, "allowed");
await expect("read another user's profile", `select id from public.profiles where id='${B}'`, "no rows");
await expect("insert usage row for another user", `insert into public.qa_logs(user_id, question_excerpt) values ('${B}','x')`, "denied");
await expect("insert own usage row", `insert into public.qa_logs(user_id, question_excerpt) values ('${A}','x')`, "denied");
await expect("delete own usage rows (reset quota)", `delete from public.qa_logs where user_id='${A}'`, "denied");
await expect("insert a purchase", `insert into public.purchases(purchase_token,user_id,product_id,state) values ('t','${A}','p','s')`, "denied");
await expect("read purchases", `select * from public.purchases`, "denied");

// The Edge Functions (service role) keep full access.
await db.exec(`set role service_role;
  insert into public.qa_logs(user_id, question_excerpt) values ('${A}','svc');
  insert into public.purchases(purchase_token,user_id,product_id,state,expires_at)
    values ('tok','${A}','cnc_assist_pro_monthly','SUBSCRIPTION_STATE_ACTIVE', now()+interval '30 days');
  update public.profiles set subscription_tier='pro', subscription_expires_at=now()+interval '30 days' where id='${A}';
  reset role;`);
await expect("read own usage rows written by the server", `select id from public.qa_logs where user_id='${A}'`, "allowed");

await db.exec(`insert into auth.users values ('33333333-3333-3333-3333-333333333333', 'c@example.com');`);
const made = (await db.query(`select 1 from public.profiles where id='33333333-3333-3333-3333-333333333333'`)).rows.length;
if (made !== 1) failures++;
console.log(`${made === 1 ? "ok  " : "FAIL"} sign-up trigger still creates the profile`);

if (failures) {
  console.error(`\n${failures} expectation(s) failed`);
  process.exit(1);
}
console.log("\nall RLS expectations hold");

// Free quota per account and per device (_shared/quota.ts).
import { assert, assertEquals, assertMatch, assertNotEquals } from "jsr:@std/assert@1";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import {
  DELETED_USER,
  deviceHash,
  forgetUsage,
  FREE_MONTHLY_LIMIT,
  monthlyUsage,
  monthStart,
  reserveUsage,
} from "../_shared/quota.ts";

const withDevice = (id?: string) =>
  new Request("https://x/", { headers: id === undefined ? {} : { "x-device-id": id } });

/// One qa_logs row as the fake table holds it.
interface Row {
  id: string;
  user_id: string;
  device_hash: string | null;
  question_excerpt: string | null;
  created_at: string;
}

/// A qa_logs table in memory behind the subset of the query builder that
/// quota.ts uses, so the tests check which rows a query really matches.
function fakeAdmin(rows: Row[]): SupabaseClient {
  const from = (_table: string) => {
    const filters: ((r: Row) => boolean)[] = [];
    let action: "select" | "delete" | "update" | "insert" = "select";
    let patch: Partial<Row> = {};
    const b: Record<string, unknown> = {};
    b.select = () => b;
    b.gte = (c: keyof Row, v: string) => (filters.push((r) => String(r[c]) >= v), b);
    b.lt = (c: keyof Row, v: string) => (filters.push((r) => String(r[c]) < v), b);
    b.eq = (c: keyof Row, v: string) => (filters.push((r) => r[c] === v), b);
    b.is = (c: keyof Row, v: null) => (filters.push((r) => r[c] === v), b);
    b.or = (expr: string) => {
      const alts = expr.split(",").map((t) => {
        const [c, , v] = t.split(".");
        return (r: Row) => r[c as keyof Row] === v;
      });
      filters.push((r) => alts.some((f) => f(r)));
      return b;
    };
    b.delete = () => ((action = "delete"), b);
    b.update = (p: Partial<Row>) => ((action = "update"), (patch = p), b);
    b.insert = (r: Partial<Row>) => {
      action = "insert";
      rows.push({ id: `new${rows.length}`, created_at: new Date().toISOString(), question_excerpt: null, device_hash: null, user_id: "", ...r });
      return b;
    };
    b.single = () => Promise.resolve({ data: { id: rows[rows.length - 1].id }, error: null });
    b.then = (ok: (r: unknown) => unknown, bad?: (e: unknown) => unknown) => {
      const hit = rows.filter((r) => filters.every((f) => f(r)));
      if (action === "delete") for (const r of hit) rows.splice(rows.indexOf(r), 1);
      if (action === "update") for (const r of hit) Object.assign(r, patch);
      return Promise.resolve({ count: hit.length, data: null, error: null }).then(ok, bad);
    };
    return b;
  };
  return { from } as unknown as SupabaseClient;
}

const now = new Date().toISOString();
const lastMonth = new Date(Date.parse(monthStart()) - 86_400_000).toISOString();
let n = 0;
const row = (user_id: string, device_hash: string | null, created_at = now): Row =>
  ({ id: `r${n++}`, user_id, device_hash, question_excerpt: "q", created_at });

Deno.test("deviceHash: same Android ID, same hash; raw ID not in it", async () => {
  const a = await deviceHash(withDevice("9f2c4a7e1b3d5f60"));
  assertMatch(a!, /^[0-9a-f]{64}$/);
  assertEquals(await deviceHash(withDevice("9f2c4a7e1b3d5f60")), a);
  assertNotEquals(await deviceHash(withDevice("0000000000000001")), a);
  assert(!a!.includes("9f2c4a7e1b3d5f60"));
});

Deno.test("deviceHash: missing or malformed header counts the account only", async () => {
  assertEquals(await deviceHash(withDevice()), null);
  assertEquals(await deviceHash(withDevice("")), null);
  assertEquals(await deviceHash(withDevice("a,user_id.neq.x")), null, "no filter injection");
  assertEquals(await deviceHash(withDevice("x".repeat(200))), null);
});

Deno.test("reinstall: a new account on the same device has no free questions left", async () => {
  const dev = (await deviceHash(withDevice("9f2c4a7e1b3d5f60")))!;
  const rows = Array.from({ length: FREE_MONTHLY_LIMIT }, () => row("old-account", dev));
  const admin = fakeAdmin(rows);

  const r = await reserveUsage(admin, { userId: "new-account", device: dev }, false, { question_excerpt: "hi" });
  assert(r instanceof Response);
  assertEquals(r.status, 429);
  assertEquals((await r.json()).used, FREE_MONTHLY_LIMIT);
  assertEquals(rows.length, FREE_MONTHLY_LIMIT, "a refused call is not logged");
});

Deno.test("quota: other devices, other accounts and last month do not count", async () => {
  const rows = [
    row("someone", "other-device"),
    row("me", "my-device", lastMonth),
    row("me", null),
    row("old-me", "my-device"),
  ];
  const admin = fakeAdmin(rows);
  assertEquals(await monthlyUsage(admin, { userId: "me", device: "my-device" }), 2);
  assertEquals(await monthlyUsage(admin, { userId: "me", device: null }), 1);
});

Deno.test("quota: a call within the limit is logged with the device", async () => {
  const rows: Row[] = [];
  const r = await reserveUsage(fakeAdmin(rows), { userId: "me", device: "my-device" }, false, { question_excerpt: "hi" });
  assert(!(r instanceof Response));
  assertEquals(rows[0].device_hash, "my-device");
});

Deno.test("Pro is not limited", async () => {
  const rows = Array.from({ length: 50 }, () => row("me", "my-device"));
  const r = await reserveUsage(fakeAdmin(rows), { userId: "me", device: "my-device" }, true, { question_excerpt: "hi" });
  assert(!(r instanceof Response));
});

Deno.test("delete account: this month's device count stays, without text or owner", async () => {
  const rows = [
    row("me", "my-device"),
    row("me", "my-device", lastMonth),
    row("me", null),
    row("someone", "other-device"),
    row(DELETED_USER, "old-device", lastMonth),
  ];
  const admin = fakeAdmin(rows);
  await forgetUsage(admin, "me");

  assertEquals(rows.filter((r) => r.user_id === "me").length, 0);
  const kept = rows.filter((r) => r.device_hash === "my-device");
  assertEquals(kept.length, 1);
  assertEquals(kept[0].user_id, DELETED_USER);
  assertEquals(kept[0].question_excerpt, null);
  assertEquals(rows.filter((r) => r.device_hash === "old-device").length, 0, "last month's leftovers purged");
  assertEquals(rows.filter((r) => r.user_id === "someone").length, 1, "other users untouched");

  // A new account on the same device still sees that call.
  assertEquals(await monthlyUsage(admin, { userId: "fresh", device: "my-device" }), 1);
});

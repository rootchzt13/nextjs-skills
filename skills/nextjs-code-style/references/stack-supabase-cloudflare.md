# Stack Opsional: Supabase + Cloudflare KV + Turnstile (+ vinext)

**Baca file ini hanya jika project memakai Supabase, Cloudflare KV, Turnstile, atau vinext**
(cek `package.json`: `@supabase/ssr`, `@supabase/supabase-js`, `vinext`, `@vinext/cloudflare`,
atau ada `wrangler.jsonc`). Untuk stack lain, pola factory/cache/captcha di bawah tetap berlaku,
cukup ganti SDK-nya.

Repo banking memakai Appwrite (DB + auth), Plaid, Dwolla, dan deploy ke Vercel.
Stack ini berbeda, tapi **pola kodenya tetap sama**. Tabel ini memetakan satu ke satu.

| Di repo banking | Di stack kita | Pola yang dipertahankan |
|---|---|---|
| `lib/appwrite.ts` → `createSessionClient()`, `createAdminClient()` | `lib/supabase/server.ts`, `lib/supabase/admin.ts` | fungsi factory `create<Peran>Client()` |
| `cookies().set("appwrite-session", ...)` | Supabase SSR helper mengelola cookie sendiri | session dibaca di server, bukan localStorage |
| `database.listDocuments(DB_ID, COLLECTION_ID, [Query.equal(...)])` | `supabase.from("table").select().eq(...)` | query hanya di `lib/actions/` |
| `account.createEmailPasswordSession()` | `supabase.auth.signInWithPassword()` | dibungkus action `signIn({ email, password })` |
| `account.create()` + `database.createDocument()` | `supabase.auth.signUp()` + insert ke `profiles` | dibungkus action `signUp(userData)` |
| `getLoggedInUser()` | `supabase.auth.getUser()` + `getUserInfo()` | nama & bentuk fungsi sama |
| `revalidatePath()` setelah mutasi | `revalidatePath()` **dan** `deleteCached()` | invalidasi setelah mutasi |
| `next dev/build/start` | `vinext dev/build`, `npx @vinext/cloudflare deploy` | |
| `process.env.NEXT_APPWRITE_KEY` | `process.env.SUPABASE_SERVICE_ROLE_KEY` (server only) | env destructuring di atas file |

## Template file yang harus ada

### `lib/supabase/server.ts`

```ts
import { createServerClient as createSupabaseServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

const { NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY } = process.env;

// Supabase client for server components and server actions, bound to the request cookies
export const createServerClient = async () => {
  const cookieStore = await cookies();

  return createSupabaseServerClient(NEXT_PUBLIC_SUPABASE_URL!, NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    cookies: {
      getAll: () => cookieStore.getAll(),
      setAll: (cookiesToSet) => {
        cookiesToSet.forEach(({ name, value, options }) =>
          cookieStore.set(name, value, options)
        );
      },
    },
  });
};
```

### `lib/supabase/client.ts`

```ts
import { createBrowserClient as createSupabaseBrowserClient } from "@supabase/ssr";

const { NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY } = process.env;

// Supabase client for client components only
export const createBrowserClient = () =>
  createSupabaseBrowserClient(NEXT_PUBLIC_SUPABASE_URL!, NEXT_PUBLIC_SUPABASE_ANON_KEY!);
```

### `lib/supabase/admin.ts`

```ts
import "server-only";
import { createClient } from "@supabase/supabase-js";

const { NEXT_PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = process.env;

// Service-role client. Bypasses RLS — use only inside server actions that need it
export const createAdminClient = () =>
  createClient(NEXT_PUBLIC_SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { persistSession: false },
  });
```

### `lib/cache.ts` (Cloudflare KV)

```ts
import { getCloudflareContext } from "@vinext/cloudflare"; // sesuaikan dengan API vinext versi terpasang

const DEFAULT_TTL_SECONDS = 60;

// Read a JSON value from KV; returns null when the key is missing
export const getCached = async <T>(key: string): Promise<T | null> => {
  try {
    const { env } = await getCloudflareContext();
    const cachedValue = await env.CACHE.get(key, "json");
    return (cachedValue as T) ?? null;
  } catch (error) {
    console.error("getCached error:", error);
    return null;
  }
};

// Store a JSON value in KV with a TTL
export const setCached = async (key: string, value: unknown, ttlSeconds = DEFAULT_TTL_SECONDS) => {
  try {
    const { env } = await getCloudflareContext();
    await env.CACHE.put(key, JSON.stringify(value), { expirationTtl: ttlSeconds });
  } catch (error) {
    console.error("setCached error:", error);
  }
};

// Remove a key from KV, call this after any mutation that changes the cached data
export const deleteCached = async (key: string) => {
  try {
    const { env } = await getCloudflareContext();
    await env.CACHE.delete(key);
  } catch (error) {
    console.error("deleteCached error:", error);
  }
};
```

Konvensi key: `<domain>:<id>[:<sub>]` — `accounts:<userId>`, `transactions:<bankId>:<page>`.
Binding KV bernama `CACHE` di `wrangler.jsonc`. Jika nama API `getCloudflareContext` berbeda
di versi vinext yang terpasang, cek `node_modules/@vinext/cloudflare` dan sesuaikan **hanya di file ini**.

### `lib/turnstile.ts`

```ts
import "server-only";

const { TURNSTILE_SECRET_KEY } = process.env;
const TURNSTILE_VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify";

// Verify a Turnstile token sent from the client. Returns true only when Cloudflare confirms it
export const verifyTurnstileToken = async (token: string): Promise<boolean> => {
  try {
    const response = await fetch(TURNSTILE_VERIFY_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ secret: TURNSTILE_SECRET_KEY, response: token }),
    });

    const result = await response.json();
    return result.success === true;
  } catch (error) {
    console.error("verifyTurnstileToken error:", error);
    return false;
  }
};
```

Pemakaian di action:

```ts
export const signUp = async ({ turnstileToken, ...userData }: signUpParams) => {
  try {
    const isHuman = await verifyTurnstileToken(turnstileToken);
    if (!isHuman) throw new Error("Captcha verification failed");

    // ...lanjut ke supabase.auth.signUp()
  } catch (error) {
    console.error("signUp error:", error);
    return null;
  }
};
```

Di client, widget Turnstile dibungkus komponen `TurnstileWidget.tsx` yang menerima `onVerify(token)`,
dan form menyimpan token di state `turnstileToken` lalu mengirimnya bersama data form.

## Contoh action lengkap dengan cache

Catatan: `userId` di contoh ini harus berasal dari session (`supabase.auth.getUser()`) atau
dicocokkan dengannya — jangan percaya `userId` mentah dari client. RLS di Supabase adalah
lapisan pertahanan kedua, bukan pengganti cek ini.

```ts
// lib/actions/bank.actions.ts
"use server";

import { createServerClient } from "@/lib/supabase/server";
import { getCached, setCached } from "@/lib/cache";
import { parseStringify } from "@/lib/utils";

const ACCOUNTS_CACHE_TTL_SECONDS = 120;

// Get all bank accounts for a user, served from KV when available
export const getAccounts = async ({ userId }: getAccountsParams) => {
  try {
    const cacheKey = `accounts:${userId}`;

    const cachedAccounts = await getCached<AccountsSummary>(cacheKey);
    if (cachedAccounts) return cachedAccounts;

    const supabase = await createServerClient();
    const { data: accounts, error } = await supabase
      .from("bank_accounts")
      .select("*")
      .eq("user_id", userId);

    if (error) throw error;

    const totalCurrentBalance = accounts.reduce(
      (total, account) => total + account.current_balance,
      0
    );

    const accountsSummary = parseStringify({
      data: accounts,
      totalBanks: accounts.length,
      totalCurrentBalance,
    });

    await setCached(cacheKey, accountsSummary, ACCOUNTS_CACHE_TTL_SECONDS);

    return accountsSummary;
  } catch (error) {
    console.error("getAccounts error:", error);
    return null;
  }
};
```

# Konvensi Kode — Diekstrak dari adrianhajdin/banking

Setiap pola di bawah merujuk ke file asli di repo (path relatif ke root repo) supaya
bisa dibuka langsung setelah `scripts/fetch_reference_repo.sh` dijalankan.

Repo asli memakai Appwrite/Plaid dan Next.js versi lama. Contoh di bawah sudah diadaptasi:
akses data ditulis generik (`db`, `createServerClient()` — ganti dengan layanan project),
dan `params`/`searchParams` ditulis async sesuai Next.js 15+.

Daftar isi:
1. Komponen presentasi
2. Komponen client dengan form
3. Komponen pembungkus field (CustomInput)
4. Server action
5. Factory client service (lib/<service>.ts)
6. Helper murni (lib/utils.ts)
7. Page (server component)
8. Tipe global (types/index.d.ts)
9. Konstanta (constants/index.ts)
10. CSS semantik (app/globals.css)
11. Urutan import
12. Komentar

---

## 1. Komponen presentasi

Rujukan: `components/HeaderBox.tsx`, `components/TotalBalanceBox.tsx`, `components/RecentTransactions.tsx`

```tsx
import AnimatedCounter from "./AnimatedCounter";
import DoughnutChart from "./DoughnutChart";

const TotalBalanceBox = ({
  accounts = [],
  totalBanks,
  totalCurrentBalance,
}: TotalBalanceBoxProps) => {
  return (
    <section className="total-balance">
      <div className="total-balance-chart">
        <DoughnutChart accounts={accounts} />
      </div>

      <div className="flex flex-col gap-6">
        <h2 className="header-2">Bank Accounts: {totalBanks}</h2>
        <div className="flex flex-col gap-2">
          <p className="total-balance-label">Total Current Balance</p>
          <div className="total-balance-amount flex-center gap-2">
            <AnimatedCounter amount={totalCurrentBalance} />
          </div>
        </div>
      </div>
    </section>
  );
};

export default TotalBalanceBox;
```

Ciri yang harus ditiru:
- `const Nama = ({ ...props }: NamaProps) => { return (...) }` lalu `export default Nama;` di baris terakhir. Bukan `export default function`, bukan `React.FC`.
- Default value di destructuring: `accounts = []`, `page = 1`, `type = "title"`.
- Tidak ada `import React` kecuali butuh `useState`/hook lain.
- Elemen semantik: `<section>`, `<header>`, `<h2>`, `<p>` — bukan `<div>` untuk semuanya.
- Class root komponen = nama komponen dalam kebab-case (`.total-balance`), sub-elemen pakai prefix yang sama (`.total-balance-chart`, `.total-balance-label`).
- Perhitungan ringan boleh di dalam komponen (lihat `RecentTransactions`: `rowsPerPage`, `totalPages`, `indexOfFirstTransaction`) dengan nama variabel yang menjelaskan dirinya sendiri. Perhitungan yang dipakai di lebih dari satu komponen pindah ke `lib/utils.ts`.
- Baris kosong memisahkan blok JSX yang berbeda tujuan.

## 2. Komponen client dengan form

Rujukan: `components/AuthForm.tsx`, `components/PaymentTransferForm.tsx`

```tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { Loader2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Form } from "@/components/ui/form";
import CustomInput from "./CustomInput";
import { signInSchema } from "@/lib/validations";
import { signIn } from "@/lib/actions/user.actions";

const SignInForm = () => {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);

  const form = useForm<z.infer<typeof signInSchema>>({
    resolver: zodResolver(signInSchema),
    defaultValues: { email: "", password: "" },
  });

  const onSubmit = async (data: z.infer<typeof signInSchema>) => {
    setIsLoading(true);

    try {
      const loggedInUser = await signIn(data);
      if (loggedInUser) router.push("/");
    } catch (error) {
      console.error("SignInForm submit error:", error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
        <CustomInput control={form.control} name="email" label="Email" placeholder="Enter your email" />
        <CustomInput control={form.control} name="password" label="Password" placeholder="Enter your password" />

        <Button type="submit" disabled={isLoading} className="form-btn">
          {isLoading ? (
            <>
              <Loader2 size={20} className="animate-spin" /> &nbsp; Loading...
            </>
          ) : (
            "Sign In"
          )}
        </Button>
      </form>
    </Form>
  );
};

export default SignInForm;
```

Ciri:
- `"use client"` baris pertama, lalu baris kosong.
- State boolean bernama `isLoading`, setter `setIsLoading`.
- Handler submit bernama `onSubmit`, handler lain `handleXxx`.
- Loading state pakai `Loader2` dari lucide dengan `animate-spin`.
- Field tidak ditulis manual berulang; pakai `CustomInput`.

## 3. Komponen pembungkus field (CustomInput)

Rujukan: `components/CustomInput.tsx`

Tujuannya menghilangkan duplikasi `FormField > FormLabel > FormControl > Input > FormMessage`
yang akan muncul di setiap field. Terima `control`, `name`, `label`, `placeholder`; tipe `name`
diturunkan dari schema (`FieldPath<z.infer<typeof schema>>`) agar salah ketik nama field
langsung error di TypeScript.

Terapkan pola yang sama untuk elemen form lain yang berulang: `CustomSelect`, `CustomTextarea`.

## 4. Server action

Rujukan: `lib/actions/user.actions.ts`, `lib/actions/bank.actions.ts`, `lib/actions/transaction.actions.ts`

```ts
"use server";

import { db } from "@/lib/db";
import { parseStringify } from "@/lib/utils";

// Get a single user profile by its auth user id
export const getUserInfo = async ({ userId }: getUserInfoParams) => {
  try {
    const user = await db.profile.findUnique({ where: { userId } });
    if (!user) throw new Error("Profile not found");

    return parseStringify(user);
  } catch (error) {
    console.error("getUserInfo error:", error);
    return null;
  }
};
```

`db` di sini contoh (Prisma). Dengan Supabase: `const supabase = await createServerClient();`
lalu `supabase.from("profiles").select("*").eq("user_id", userId).single()` dan `if (error) throw error;`.
Bentuk action-nya tetap sama.

Jika `userId` berasal dari client, **cocokkan dengan user di session** sebelum query
(`getCurrentUser()`), atau lebih baik ambil langsung dari session dan jangan terima dari parameter.

Ciri:
- Satu file per domain: `user.actions.ts`, `bank.actions.ts`, `transaction.actions.ts`. Nama domain tunggal, huruf kecil.
- `export const` arrow async. Nama kata kerja: `get`, `create`, `update`, `delete`, `sign`, `exchange`.
- Parameter satu object dengan tipe `<namaFungsi>Params` (di repo asli disebut `*Props`; kita pakai `*Params` untuk action agar tidak tertukar dengan props komponen. Tipe `*Props` tetap untuk komponen).
- Komentar satu baris di atas fungsi.
- `try/catch` membungkus seluruh body; `catch` mencatat error dengan nama fungsi dan `return null`.
- Action memanggil action lain dari domain berbeda lewat import, bukan duplikasi query (`bank.actions.ts` mengimpor `getBanks` dari `user.actions.ts`).
- Komentar pendek di dalam body untuk tiap langkah besar: `// get banks from db`, `// get each account info from plaid`.
- Env destructuring di atas file dengan alias yang lebih pendek dan jelas:
  ```ts
  const {
    DATABASE_URL,
    STRIPE_SECRET_KEY,
  } = process.env;
  ```

## 5. Factory client service

Rujukan: `lib/appwrite.ts` (`createSessionClient`, `createAdminClient`), `lib/plaid.ts`

Pola: satu file per layanan eksternal, mengekspor fungsi `create<Peran>Client()` yang
mengembalikan client siap pakai. Pemanggil tidak perlu tahu cara inisialisasi.

Contoh: `lib/db.ts` (Prisma/Drizzle) mengekspor `db`; `lib/stripe.ts` mengekspor `stripe`.
Untuk Supabase: `lib/supabase/server.ts`, `lib/supabase/client.ts`, `lib/supabase/admin.ts` —
template lengkapnya ada di `stack-supabase-cloudflare.md`.

File yang memakai secret diawali `import "server-only";` agar build gagal jika terimpor dari client.

## 6. Helper murni

Rujukan: `lib/utils.ts`

Fungsi di sini:
- Tidak memanggil database/API, tidak membaca cookie. Input → output.
- Nama kata kerja + objek: `formatAmount`, `formatDateTime`, `removeSpecialCharacters`, `countTransactionCategories`, `extractCustomerIdFromUrl`, `getTransactionStatus`, `getAccountTypeColors`.
- Tipe return eksplisit kalau tidak jelas (`formatAmount(amount: number): string`).
- Fungsi yang mengembalikan beberapa variasi mengembalikan object bernama jelas (`formatDateTime` → `{ dateTime, dateDay, dateOnly, timeOnly }`).
- `switch` untuk pemetaan nilai → config (`getAccountTypeColors`), dengan `default`.
- Komentar per langkah di fungsi yang agak panjang (`countTransactionCategories`).

Wajib ada di setiap proyek: `cn()` (clsx + tailwind-merge), `parseStringify()`, `formatAmount()`, `formatDateTime()`, `formUrlQuery()`.

## 7. Page

Rujukan: `app/(root)/page.tsx`, `app/(root)/transaction-history/page.tsx`, `app/(root)/payment-transfer/page.tsx`

Ciri:
- `const NamaHalaman = async ({ searchParams }: SearchParamProps) => { ... }; export default NamaHalaman;`
- Baris pertama body: `await` lalu ubah menjadi nilai siap pakai:
  ```tsx
  const { id, page } = await searchParams;
  const currentPage = Number(page) || 1;
  ```
  (Repo asli men-destructure `searchParams` langsung di parameter — itu pola Next.js 14 dan
  tidak berlaku lagi di Next.js 15+.)
- Lalu fetch berurutan: user → accounts → account. Guard `if (!x) return;` atau `redirect()` segera setelah fetch yang bisa gagal.
- JSX halaman hanya menyusun komponen besar: `HeaderBox`, `TotalBalanceBox`, `RecentTransactions`, `RightSidebar`. Tidak ada `map` rumit atau tabel langsung di page.
- Layout per route group: `app/(auth)/layout.tsx` (dua kolom, gambar di kanan), `app/(root)/layout.tsx` (sidebar + konten + mobile nav).

## 8. Tipe global

Rujukan: `types/index.d.ts`

```ts
/* eslint-disable no-unused-vars */

declare type SearchParamProps = {
  params: Promise<{ [key: string]: string }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
};

// ========================================

declare type User = {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
};

declare type HeaderBoxProps = {
  type?: "title" | "greeting";
  title: string;
  subtext: string;
  user?: string;
};

declare type getUserInfoParams = {
  userId: string;
};
```

Ciri:
- `declare type` (bukan `interface`, bukan `export`) agar tersedia global tanpa import.
- Blok dipisah `// ====` per kelompok: entitas (User, Account, Transaction), props komponen, params action.
- Entitas = kata benda tunggal PascalCase. Props = `<Komponen>Props`. Params action = `<fungsi>Params`.
- Union literal untuk nilai terbatas: `type?: "title" | "greeting"`, `category: "Food and Drink" | "Travel" | "Transfer"`.
- Tipe lokal (`interface CustomInput` di `CustomInput.tsx`) hanya bila tipe bergantung pada generic lokal dan tidak dipakai file lain.
- Alternatif untuk Next.js 15.5+: helper global `PageProps<"/route/[id]">` dan `LayoutProps<"/route">`
  (dibuat otomatis oleh `next dev`/`next build`/`next typegen`) memberi tipe `params` yang tepat per route.
  Jika project sudah memakainya, ikuti itu daripada `SearchParamProps`.

## 9. Konstanta

Rujukan: `constants/index.ts`

- Array config navigasi: `sidebarLinks = [{ imgURL, route, label }]`.
- Konstanta identitas/ID: `UPPER_SNAKE_CASE`.
- Map warna/label per kategori: object dengan key literal.
- Setiap konstanta `export`. Komentar singkat jika asal nilainya tidak jelas.

## 10. CSS semantik

Rujukan: `app/globals.css`

```css
@layer utilities {
  .input-class {
    @apply text-16 placeholder:text-16 rounded-lg border border-gray-300 text-gray-900 placeholder:text-gray-500;
  }

  .flex-center {
    @apply flex items-center justify-center;
  }

  /* Home */
  .home {
    @apply no-scrollbar flex w-full flex-row max-xl:max-h-screen max-xl:overflow-y-scroll;
  }

  .home-content {
    @apply no-scrollbar flex w-full flex-1 flex-col gap-8 px-5 sm:px-8 py-7 lg:py-12 xl:max-h-screen xl:overflow-y-scroll;
  }

  .total-balance {
    @apply flex w-full items-center gap-4 rounded-xl border border-gray-200 p-4 shadow-chart sm:gap-6 sm:p-6;
  }
}
```

Contoh di atas gaya Tailwind v3. Di Tailwind v4, tulis tiap class sebagai
`@utility input-class { @apply ...; }` di `app/globals.css`; aturan penamaannya sama.

Ciri:
- Utility umum dulu (`.flex-center`, `.input-class`, `.text-14`), lalu blok per halaman/komponen dengan komentar judul (`/* Home */`, `/* Auth */`).
- Nama = nama komponen/halaman kebab-case; turunan pakai prefix (`.home-header`, `.home-content`).
- Skala tipografi custom di Tailwind config (`text-14`, `text-16`) dipakai konsisten, bukan `text-[14px]` inline.

## 11. Urutan import

Dari `AuthForm.tsx` dan `page.tsx` (dirapikan sedikit):

1. `"use client"` / `"use server"`
2. `next/*`, `react`
3. Library pihak ketiga (`zod`, `react-hook-form`, `lucide-react`)
4. `@/components/ui/*`
5. `@/components/*` atau relatif `./`
6. `@/lib/*`
7. `@/constants`, `@/types` (jarang perlu karena global)

Baris kosong antar kelompok. Alias `@/` untuk semua yang bukan sibling.

## 12. Komentar

Dari `lib/utils.ts` dan `lib/actions/*`:
- Komentar huruf kapital untuk pemisah bagian di file utilitas: `// FORMAT DATE TIME`.
- Komentar kalimat pendek di atas langkah: `// Iterate over each transaction`, `// Sort by count in descending order`.
- Komentar inline di akhir baris hanya untuk option yang tidak jelas (`hour12: true, // 12-hour clock`).
- Tidak ada JSDoc panjang. Nama fungsi yang baik menggantikan dokumentasi.

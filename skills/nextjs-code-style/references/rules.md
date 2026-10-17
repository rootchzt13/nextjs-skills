# Aturan Inti — Next.js App Router

File ini adalah sumber aturan untuk semua skill `nextjs-*`. Jika project punya `AGENTS.md`
di root, file itu yang menang. Jika tidak ada, pakai file ini. Instruksi langsung dari user
di percakapan selalu menang atas keduanya.

Tujuan utama: kode yang **mudah dibaca manusia**, **tidak duplikat**, dan **konsisten**,
dengan gaya yang terinspirasi repo [adrianhajdin/banking](https://github.com/adrianhajdin/banking).

---

## 1. Tech Stack

**Ikuti stack yang sudah dipakai project** (cek `package.json`). Jangan mengganti library yang
sudah ada, dan jangan menambah library baru untuk hal yang sudah bisa dikerjakan stack yang ada.
Kalau terpaksa menambah, jelaskan alasannya ke user dulu.

Default yang diasumsikan skill ini (jika project belum menentukan):

| Layer | Default | Catatan |
|---|---|---|
| Framework | **Next.js App Router** (15+) | `params`, `searchParams`, `cookies()`, `headers()` bersifat async — wajib di-`await` |
| Bahasa | **TypeScript** | `strict: true` |
| Styling | **Tailwind CSS** | Class semantik lewat `@apply` di `app/globals.css` untuk pola berulang |
| UI | **shadcn/ui** | Primitif di `components/ui/` (lowercase). Jangan edit manual; bungkus di komponen sendiri |
| Form | **react-hook-form + zod** | Schema zod jadi sumber tipe form |
| Icon | **lucide-react** | |
| Data & auth | bebas (Supabase, Prisma, Drizzle, Auth.js, dll.) | Diakses lewat factory/helper di `lib/`, lihat bagian 6 |

Stack opsional dengan template siap pakai (Supabase + Cloudflare KV + Turnstile + vinext):
lihat `stack-supabase-cloudflare.md`.

---

## 2. Struktur Folder

Ikuti struktur ini. Jangan membuat folder baru di root tanpa alasan kuat. Jika project sudah
memakai `src/`, semua path di bawah berada di dalam `src/`.

```
app/
  (auth)/              # route group: halaman tanpa layout utama (sign-in, sign-up)
  (root)/              # route group: halaman utama setelah login
    layout.tsx
    page.tsx
    <nama-route>/page.tsx   # kebab-case, satu folder per route
  api/                 # route handler hanya jika benar-benar perlu (webhook, dll.)
  globals.css
  layout.tsx
components/
  <NamaKomponen>.tsx   # PascalCase, satu komponen per file, default export
  ui/                  # shadcn/ui, lowercase, jangan ditulis manual
constants/
  index.ts             # data statis: link navigasi, label, opsi select, limit
lib/
  actions/
    <domain>.actions.ts   # server actions per domain: user.actions.ts, post.actions.ts
  <layanan>.ts         # factory client layanan eksternal: db.ts, stripe.ts, (atau folder lib/<layanan>/)
  utils.ts             # cn(), formatAmount(), formatDateTime(), parseStringify(), dll.
  validations.ts       # semua zod schema
types/
  index.d.ts           # declare type global: *Props untuk komponen, *Params untuk action
public/
  icons/               # svg ikon
```

Aturan penempatan:
- **Fetch data di `page.tsx`** (server component), lalu kirim ke komponen lewat props. Komponen tidak fetch sendiri kecuali client component yang memang interaktif.
- **Logika bisnis dan akses data di `lib/actions/`**, bukan di komponen atau page.
- **Helper murni (tanpa side effect) di `lib/utils.ts`**.
- **Semua schema zod di `lib/validations.ts`**, agar satu schema dipakai form dan server action.

---

## 3. Penamaan — harus jelas dan mudah dibaca manusia

Prinsip: nama harus menjelaskan **apa** isinya tanpa perlu membaca implementasinya. Hindari singkatan kecuali sudah umum (`id`, `url`, `db`).

| Hal | Aturan | Contoh benar | Contoh salah |
|---|---|---|---|
| File komponen | PascalCase, sama dengan nama komponen | `TotalBalanceBox.tsx` | `total-balance.tsx`, `tbb.tsx` |
| File shadcn | lowercase (biarkan apa adanya) | `components/ui/button.tsx` | |
| File action | `<domain>.actions.ts` | `user.actions.ts` | `userActions.ts`, `actions.ts` |
| Folder route | kebab-case | `app/(root)/payment-transfer/` | `app/(root)/PaymentTransfer/` |
| Komponen | PascalCase, kata benda | `HeaderBox`, `BankCard` | `header_box`, `Comp1` |
| Fungsi | camelCase, **diawali kata kerja** | `getAccounts`, `formatAmount`, `createUserProfile` | `accounts()`, `data`, `handle` |
| Event handler | `handle<Aksi>` di dalam komponen, `on<Aksi>` sebagai prop | `handleSubmit`, prop `onSelect` | `submit`, `click` |
| Variabel | camelCase, kata benda deskriptif | `currentTransactions`, `totalCurrentBalance` | `tmp`, `data2`, `x` |
| Boolean | awalan `is` / `has` / `can` / `should` | `isLoading`, `hasBankAccount` | `loading`, `bank` |
| Konstanta global | UPPER_SNAKE_CASE | `ROWS_PER_PAGE`, `SESSION_COOKIE_NAME` | `rowsPerPage` (di level modul) |
| Tipe props komponen | `<NamaKomponen>Props` | `HeaderBoxProps` | `Props`, `IHeaderBox` |
| Tipe param action | `<namaFungsi>Params` | `getAccountsParams` | `GetAccountsInput` |
| Class CSS semantik | kebab-case, nama blok | `.header-box`, `.total-balance-amount` | `.hb`, `.box1` |

Semua nama identifier dalam **bahasa Inggris**. Komentar boleh Inggris atau Indonesia, konsisten dalam satu file.

---

## 4. Gaya Menulis Kode

### Komponen

```tsx
// components/HeaderBox.tsx
const HeaderBox = ({ type = "title", title, subtext, user }: HeaderBoxProps) => {
  return (
    <div className="header-box">
      <h1 className="header-box-title">
        {title}
        {type === "greeting" && (
          <span className="text-bankGradient">&nbsp;{user}</span>
        )}
      </h1>
      <p className="header-box-subtext">{subtext}</p>
    </div>
  );
};

export default HeaderBox;
```

- Arrow function, destructuring props langsung di parameter, tipe dari `types/index.d.ts`.
- Default value lewat destructuring (`type = "title"`), bukan `||` di dalam body.
- `"use client"` hanya kalau komponen memakai hook, event, atau browser API. Default-nya server component.
- Satu komponen per file. Komponen kecil pembantu yang hanya dipakai satu file boleh di file yang sama, tanpa export.

### Server action

```ts
// lib/actions/bank.actions.ts
"use server";

import { db } from "@/lib/db";
import { getCurrentUser } from "@/lib/actions/user.actions";
import { parseStringify } from "@/lib/utils";

// Get all bank accounts that belong to the logged-in user
export const getAccounts = async () => {
  try {
    const currentUser = await getCurrentUser();
    if (!currentUser) throw new Error("Not authenticated");

    const accounts = await db.bankAccount.findMany({
      where: { userId: currentUser.id },
    });

    const totalCurrentBalance = accounts.reduce(
      (total, account) => total + account.currentBalance,
      0
    );

    return parseStringify({ data: accounts, totalBanks: accounts.length, totalCurrentBalance });
  } catch (error) {
    console.error("getAccounts error:", error);
    return null;
  }
};
```

- Satu baris komentar di atas setiap action menjelaskan tujuannya.
- Parameter (jika ada) selalu **satu object** yang di-destructure, bukan parameter posisional: `getTransactions({ accountId, page })`.
- `try/catch` di setiap action. Log dengan nama fungsi di depannya. Return `null` saat gagal, dan pemanggil wajib menangani `null`.
- **Identitas user diambil dari session di server**, bukan dari parameter yang dikirim client. Server action adalah endpoint publik.
- Return lewat `parseStringify()` jika hasilnya object kompleks dari SDK (menghindari error serialisasi).

### Halaman

```tsx
// app/(root)/page.tsx
const Home = async ({ searchParams }: SearchParamProps) => {
  const { page } = await searchParams;
  const currentPage = Number(page) || 1;

  const loggedInUser = await getCurrentUser();
  if (!loggedInUser) redirect("/sign-in");

  const accounts = await getAccounts();
  if (!accounts) return;

  return (
    <section className="home">
      <HeaderBox type="greeting" title="Welcome" user={loggedInUser.firstName} subtext="..." />
      <TotalBalanceBox accounts={accounts.data} totalBanks={accounts.totalBanks} totalCurrentBalance={accounts.totalCurrentBalance} />
    </section>
  );
};

export default Home;
```

- `params` dan `searchParams` adalah `Promise` di Next.js 15+ — `await` di baris pertama body.
  Di client component, buka dengan `use(searchParams)` dari React.

### Urutan isi file

1. `"use client"` / `"use server"` (jika ada)
2. Import: framework → library pihak ketiga → `@/components` → `@/lib` → relatif
3. Konstanta lokal
4. Tipe lokal (hanya jika tidak dipakai file lain; selain itu taruh di `types/`)
5. Komponen / fungsi utama
6. `export default`

### Styling

- Pakai class Tailwind langsung untuk layout sederhana (`flex flex-col gap-4`).
- Jika kombinasi class yang sama muncul **≥ 2 kali** atau panjang **> ~6 class**, buat class semantik di `app/globals.css` (Tailwind v4: `@utility nama { @apply ...; }`; v3: di dalam `@layer utilities`), lalu pakai namanya. Contoh: `.total-balance`, `.form-item`, `.input-class`.
- Gabungkan class kondisional dengan `cn()` dari `lib/utils.ts`, bukan template string.

### Form

- Schema zod di `lib/validations.ts`, tipe form diturunkan dari schema: `z.infer<typeof signUpSchema>`.
- Field berulang dibungkus komponen `CustomInput`, jangan tulis `FormField` manual berulang-ulang.
- Validasi ulang dengan schema yang sama **di server action**; validasi di form hanya untuk UX.
- Jika ada captcha, verifikasi token di server action **sebelum** menyentuh database.

### Komentar

- Komentar menjelaskan **kenapa** atau meringkas blok logika, bukan mengulang kode.
- Komentar pendek di atas blok: `// get banks from db`, `// Sort by count in descending order`.
- Jangan tinggalkan kode mati yang di-comment. Hapus saja; git menyimpan histori.

---

## 5. Anti-Duplikasi dan Reusabilitas (wajib)

Sebelum menulis fungsi atau komponen baru, **cari dulu** (`grep`/`rg`) apakah sudah ada yang mirip di `lib/utils.ts`, `lib/actions/`, `components/`, dan `constants/`. Gunakan atau perluas yang ada.

Aturan:
1. **Logika yang sama muncul 2 kali → ekstrak** ke fungsi di `lib/utils.ts` (murni) atau `lib/actions/` (ada I/O).
2. **Markup yang sama muncul 2 kali → ekstrak** ke komponen di `components/` dengan props.
3. **Kombinasi class Tailwind sama 2 kali → class semantik** di `globals.css`.
4. **Nilai literal yang dipakai di lebih dari satu tempat** (label, route, limit, nama cookie) → `constants/index.ts`.
5. **Tipe yang dipakai di lebih dari satu file → `types/index.d.ts`**, jangan duplikasi `interface`.
6. Komponen harus menerima data lewat props, bukan hard-code, agar bisa dipakai ulang.
7. Fungsi melakukan **satu hal**. Jika nama fungsinya butuh kata "and" (`fetchAndFormatAndSave`), pecah.
8. Jangan copy-paste lalu ubah sedikit. Kalau butuh variasi, tambahkan parameter/props.

---

## 6. Layanan Eksternal, Secret, dan Cache

- **Satu factory per layanan** di `lib/<layanan>.ts` atau `lib/<layanan>/`: `createServerClient()`, `createAdminClient()`, `db`. Pemanggil tidak perlu tahu cara inisialisasi.
- **Secret hanya di server.** File yang memakai secret diawali `import "server-only";`. Tidak ada `NEXT_PUBLIC_` untuk kunci rahasia. Client component tidak boleh mengimpor file tersebut.
- **Env** dibaca lewat `process.env` dengan destructuring di atas file (atau satu `lib/env.ts`), nama jelas: `DATABASE_URL`, `STRIPE_SECRET_KEY`.
- **Otorisasi**: setiap action yang membaca/mengubah data milik user memastikan data itu milik user dari session.
- **Invalidasi setelah mutasi**: panggil `revalidatePath()` / `revalidateTag()` untuk path/tag terdampak, dan hapus key cache eksternal (KV/Redis) jika ada. Semua akses cache eksternal lewat satu helper (`lib/cache.ts`), key ber-prefix domain: `accounts:<userId>`.
- **Input publik** (sign-up, form kontak) divalidasi zod di server dan, jika ada captcha, diverifikasi sebelum menyentuh database.

---

## 7. Alur Kerja Agent

1. **Baca aturan ini** (atau `AGENTS.md` project) dan contoh di `conventions.md`.
2. **Pahami yang sudah ada** sebelum menambah: lihat `types/index.d.ts`, `lib/utils.ts`, `constants/index.ts`, dan daftar `components/`.
3. **Rencanakan singkat** (file apa yang dibuat/diubah, nama fungsi/komponen) dan sampaikan ke user untuk perubahan besar.
4. **Tulis kode** mengikuti bagian 3–6.
5. **Review sendiri** sebelum selesai, pakai checklist di bawah.
6. Jalankan `npx tsc --noEmit` dan `npm run lint` jika tersedia. Perbaiki error sebelum melapor selesai.

### Checklist sebelum selesai

- [ ] Nama file, komponen, fungsi, variabel sesuai tabel di bagian 3
- [ ] Tidak ada logika/markup/class yang duplikat (sudah dicari dengan grep)
- [ ] Tipe ada di `types/index.d.ts` jika dipakai > 1 file
- [ ] Server action punya komentar tujuan, `try/catch`, object param, identitas user dari session
- [ ] `params`/`searchParams`/`cookies()`/`headers()` di-`await`
- [ ] Tidak ada `any` baru tanpa alasan, tidak ada `console.log` sisa debug
- [ ] `"use client"` hanya di komponen yang memang perlu
- [ ] Secret tidak bocor ke client
- [ ] Cache/path di-invalidate setelah mutasi terkait

---

## 8. Yang Tidak Boleh Dilakukan

- Mengganti framework/library yang sudah dipakai project tanpa izin.
- Menulis ulang komponen shadcn di `components/ui/` secara manual.
- Membuat file "utils" baru di sembarang folder; semua helper umum di `lib/utils.ts`.
- Menaruh query database di dalam komponen.
- Nama variabel satu huruf di luar callback pendek (`(a, b) => b.count - a.count` boleh; `const d = ...` tidak).
- Menghapus atau mengubah `AGENTS.md` project tanpa diminta user.

---
name: nextjs-code-style
description: Aturan gaya kode, penamaan, struktur folder, dan anti-duplikasi untuk project Next.js App Router (TypeScript + Tailwind + shadcn/ui + zod), terinspirasi repo adrianhajdin/banking. Gunakan SETIAP KALI akan membuat atau mengubah komponen React, page, layout, server action, helper di lib/, tipe di types/, atau class di globals.css di project Next.js — bahkan untuk perubahan kecil seperti menambah satu fungsi atau satu prop. Juga gunakan saat user meminta "rapikan kode", "refactor", "hilangkan duplikasi", "samakan gaya kode", atau saat review kode Next.js. Skill ini juga menjadi sumber aturan bagi nextjs-plan, nextjs-test, nextjs-review, dan nextjs-bugreport.
---

# Next.js Code Style

Skill ini menjelaskan **bagaimana** kode ditulis agar mudah dibaca, tidak duplikat, dan konsisten.

## Sumber aturan (urutan prioritas)

1. Instruksi langsung dari user di percakapan.
2. `AGENTS.md` di root project, jika ada.
3. [references/rules.md](references/rules.md) — aturan bawaan skill ini.

Jika `AGENTS.md` project bertentangan dengan `rules.md`, ikuti `AGENTS.md`.
Skill `nextjs-setup` bisa membuatkan `AGENTS.md` dari `rules.md` untuk project.

## Kapan membaca apa

| Situasi | Baca |
|---|---|
| Sebelum menulis kode apa pun di project Next.js | `references/rules.md` (aturan lengkap) |
| Membuat/mengubah komponen, page, action, helper, tipe, CSS | `references/conventions.md` (template per jenis file) |
| Bingung file harus ditaruh di mana | `references/file-structure.md` |
| Project memakai Supabase, Cloudflare KV, Turnstile, atau vinext | `references/stack-supabase-cloudflare.md` |
| Butuh contoh nyata dari repo referensi | Jalankan `bash scripts/fetch_reference_repo.sh` dari root project, lalu buka file di `.reference/banking/` |

## Pola inti (ringkasan)

1. **Komponen** = arrow function + destructured props + tipe `<Nama>Props` dari `types/index.d.ts` + `export default` di baris terakhir. Satu komponen per file PascalCase.
2. **Server action** = `lib/actions/<domain>.actions.ts`, `"use server"` di atas, `export const namaKerja = async ({ ...param }: namaKerjaParams) => { try { ... } catch { ... } }`, komentar satu baris di atasnya, return `null` saat gagal. Identitas user dari session, bukan dari parameter client.
3. **Page** = server component async yang `await searchParams`/`params`, fetch data, lalu kirim ke komponen via props. Markup rumit ada di komponen.
4. **Helper murni** = `lib/utils.ts`. Nama diawali kata kerja: `formatAmount`, `countTransactionCategories`.
5. **Tipe global** = `types/index.d.ts` dengan `declare type`, tanpa import, dipisah blok `// ====` per domain.
6. **Data statis** = `constants/index.ts`.
7. **Class CSS semantik** = `app/globals.css` dengan `@apply`, nama kebab-case mengikuti nama komponen: `.header-box`, `.header-box-title`.
8. **Form** = react-hook-form + zod; field dibungkus `CustomInput`; schema di `lib/validations.ts` dan divalidasi ulang di server.
9. **Secret** hanya di server (`import "server-only"`), tidak pernah `NEXT_PUBLIC_`.

## Alur saat menulis kode

1. Cek `package.json` untuk stack yang benar-benar dipakai. Ikuti itu; jangan menambah library tanpa izin.
2. Cari dulu yang sudah ada: `rg "export (const|function) <kataKunci>" lib components` dan `rg "declare type <Nama>" types`. Pakai ulang atau perluas.
3. Tentukan lokasi file lewat `references/file-structure.md`.
4. Tentukan nama lewat tabel penamaan di `rules.md` bagian 3. Uji: *apakah orang baru paham isinya hanya dari namanya?*
5. Tulis mengikuti template di `references/conventions.md`.
6. Jalankan checklist di `rules.md` bagian 7, khususnya cek duplikasi, lalu `npx tsc --noEmit` dan `npm run lint`.

## Contoh singkat: dari permintaan ke kode

**Permintaan:** "Tambahkan kartu yang menampilkan jumlah transaksi bulan ini."

**Yang benar:**
- Tipe: tambah `declare type MonthlyTransactionCardProps = { transactions: Transaction[] }` di `types/index.d.ts`.
- Helper: jika belum ada, tambah `countTransactionsThisMonth(transactions)` di `lib/utils.ts` (murni, bisa dites, bisa dipakai di tempat lain).
- Komponen: `components/MonthlyTransactionCard.tsx`, menerima `transactions`, memanggil helper, render dengan class `.monthly-transaction-card` di `globals.css`.
- Page: `app/(root)/page.tsx` sudah punya `transactions`, cukup kirim ke komponen baru.

**Yang salah:**
- Menghitung langsung di JSX page dengan `transactions.filter(t => ...)` (logika di page, tidak reusable, `t` tidak deskriptif).
- Menamai komponen `Card2.tsx` atau `MTCard.tsx`.
- Menulis `interface Props` lokal padahal pola project memakai tipe global `*Props`.

## Perbedaan yang disengaja dari repo banking

Repo banking adalah materi tutorial; beberapa hal diperbaiki, dan ini **bukan** pelanggaran gaya:
- `params`/`searchParams` di-`await` (Next.js 15+), bukan di-destructure langsung.
- Hindari `any` (repo memakai `parseStringify = (value: any)`); beri tipe generik `<T>` bila mudah.
- Server action yang gagal mengembalikan `null` secara eksplisit, dan pemanggil wajib menanganinya.
- Secret hanya di server; tidak ada `NEXT_PUBLIC_` untuk kunci rahasia.
- `console.error` menyertakan nama fungsi: `console.error("getAccounts error:", error)`.

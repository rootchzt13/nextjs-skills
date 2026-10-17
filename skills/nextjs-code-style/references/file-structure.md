# Di Mana File Harus Ditaruh

Struktur mengikuti repo banking (flat, per jenis file), dibuat umum untuk Next.js App Router.
Jika project memakai `src/`, semua path di bawah berada di dalam `src/`.

```
.
├── app/
│   ├── (auth)/                     # halaman publik, tanpa layout utama
│   │   ├── layout.tsx              # dua kolom: form kiri, ilustrasi kanan
│   │   ├── sign-in/page.tsx
│   │   └── sign-up/page.tsx
│   ├── (root)/                     # halaman setelah login
│   │   ├── layout.tsx              # Sidebar + MobileNav + konten; cek session di sini
│   │   ├── page.tsx                # dashboard
│   │   └── <kebab-route>/page.tsx
│   ├── api/                        # route handler: webhook pihak ketiga, health check
│   ├── globals.css                 # tailwind + class semantik
│   └── layout.tsx                  # html/body, font, metadata
├── components/
│   ├── ui/                         # shadcn (jangan tulis manual; `npx shadcn add <nama>`)
│   ├── AuthForm.tsx                # client, form
│   ├── CustomInput.tsx             # pembungkus FormField
│   ├── HeaderBox.tsx               # presentasi
│   ├── Sidebar.tsx                 # navigasi
│   └── ...                         # satu komponen per file, PascalCase
├── constants/
│   └── index.ts                    # sidebarLinks, label, opsi, limit
├── lib/
│   ├── actions/
│   │   ├── user.actions.ts         # auth + profil
│   │   └── <domain>.actions.ts
│   ├── db.ts                       # factory/klien database (atau lib/<layanan>/ untuk beberapa peran)
│   ├── cache.ts                    # (opsional) getCached / setCached / deleteCached untuk KV/Redis
│   ├── env.ts                      # (opsional) baca & validasi env di satu tempat
│   ├── validations.ts              # semua zod schema
│   └── utils.ts                    # cn, formatAmount, formatDateTime, parseStringify, ...
├── types/
│   └── index.d.ts                  # declare type global
├── public/
│   └── icons/                      # svg
├── proxy.ts                        # (opsional) Next.js 16; di Next.js 15 namanya middleware.ts
└── AGENTS.md                       # (opsional) aturan project, dibuat oleh skill nextjs-setup
```

## Tabel keputusan

| Saya mau menambah... | Taruh di | Nama |
|---|---|---|
| Halaman baru | `app/(root)/<kebab-route>/page.tsx` | folder kebab-case |
| Halaman publik (landing, reset password) | `app/(auth)/<kebab-route>/page.tsx` | |
| Komponen UI yang dipakai page | `components/<PascalCase>.tsx` | kata benda |
| Primitif UI (button, dialog) | `npx shadcn add <nama>` → `components/ui/` | jangan tulis manual |
| Query/mutasi data | `lib/actions/<domain>.actions.ts` | kata kerja |
| Klien layanan eksternal | `lib/<layanan>.ts` atau `lib/<layanan>/<peran>.ts` | `create<Peran>Client()` |
| Fungsi format/hitung tanpa I/O | `lib/utils.ts` | kata kerja |
| Zod schema | `lib/validations.ts` | `<nama>Schema` |
| Akses cache eksternal (KV/Redis) | hanya lewat `lib/cache.ts` | |
| Tipe dipakai > 1 file | `types/index.d.ts` | `*Props`, `*Params`, entitas |
| Nilai tetap dipakai > 1 tempat | `constants/index.ts` | `UPPER_SNAKE` / camelCase array |
| Kombinasi class Tailwind berulang | `app/globals.css` | kebab-case, prefix nama komponen |
| Ikon | `public/icons/<kebab>.svg` | |

## Yang jangan dibuat

- `utils/` di root, `helpers/`, `services/` — semuanya sudah ada tempatnya di `lib/`.
- `components/<Fitur>/<Komponen>.tsx` bersarang dalam; struktur flat. Kalau komponen sudah > 30 file, boleh kelompokkan per domain (`components/bank/`, `components/transaction/`) setelah diskusi dengan user.
- File `index.ts` barrel di `components/`; import langsung dari filenya.

Jika project sudah punya struktur lain yang konsisten (misal feature folders), **ikuti struktur
project**, jangan memaksakan struktur ini. Sampaikan ke user jika ada ketidakkonsistenan.

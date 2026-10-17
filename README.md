# nextjs-skills

Kumpulan **Agent Skills** untuk project **Next.js App Router**. Isinya aturan gaya kode dan alur kerja
*plan → test → review → bug report*, supaya kode yang ditulis AI agent mudah dibaca, tidak duplikat,
dan terverifikasi. Bisa dipakai di Claude Code, Cursor, Codex, dan agent lain yang mendukung
[skills.sh](https://skills.sh).

Gaya kodenya terinspirasi dari [adrianhajdin/banking](https://github.com/adrianhajdin/banking) dan
sudah diperbarui untuk Next.js 15+ (`params`/`searchParams` async).

## Instalasi

```bash
# semua skill (disarankan)
npx skills add rootchzt13/nextjs-skills

# hanya skill tertentu
npx skills add rootchzt13/nextjs-skills --skill nextjs-code-style

# lihat daftar skill tanpa memasang
npx skills add rootchzt13/nextjs-skills --list
```

Setelah terpasang, jalankan sekali di root project:

```
/nextjs-setup
```

Perintah ini membuat `AGENTS.md` (aturan project yang disesuaikan dengan `package.json`),
`CLAUDE.md`, subagent `bug-reporter`, serta folder `docs/plans/` dan `docs/bug-reports/`.
Langkah ini opsional; tanpa `AGENTS.md`, skill memakai aturan bawaan dari `nextjs-code-style`.

## Daftar skill

| Skill | Dipanggil | Fungsi |
|---|---|---|
| `nextjs-code-style` | otomatis saat menulis kode | Aturan penamaan, struktur folder, anti-duplikasi, pola komponen/action/page, keamanan server action |
| `nextjs-plan` | `/nextjs-plan <tugas>` (manual) | Menulis rencana ke `docs/plans/`, menunggu persetujuan, tidak menyentuh kode |
| `nextjs-test` | `/nextjs-test [lingkup]` atau "jalankan test" | tsc + lint + test, perbaiki sampai hijau (maks 5 iterasi, tanpa melemahkan test), memasang Vitest jika belum ada |
| `nextjs-review` | `/nextjs-review [lingkup]` atau "cek lagi" | Review skeptis terhadap aturan, menjalankan ulang alat sebagai bukti, tabel temuan per tingkat |
| `nextjs-bugreport` | `/nextjs-bugreport [area]` atau "cari bug" | Subagent read-only menulis laporan bug ke `docs/bug-reports/` |
| `nextjs-setup` | `/nextjs-setup` (manual) | Memasang `AGENTS.md`, `CLAUDE.md`, dan subagent ke project |

Alur yang disarankan untuk tugas besar:

```
/nextjs-plan → implementasi → /nextjs-test → /nextjs-review
```

## Stack

Default yang diasumsikan: Next.js App Router, TypeScript, Tailwind CSS, shadcn/ui, react-hook-form + zod,
lucide-react. Database dan auth bebas (Supabase, Prisma, Drizzle, Auth.js, ...). Skill selalu
mengikuti stack yang ada di `package.json` project.

Template siap pakai untuk **Supabase + Cloudflare KV + Turnstile + vinext** tersedia di
[`skills/nextjs-code-style/references/stack-supabase-cloudflare.md`](skills/nextjs-code-style/references/stack-supabase-cloudflare.md).

## Struktur repo

```
skills/
├── nextjs-code-style/
│   ├── SKILL.md
│   ├── references/
│   │   ├── rules.md                      # aturan inti (sumber AGENTS.md)
│   │   ├── conventions.md                # template kode per jenis file
│   │   ├── file-structure.md             # tabel "taruh di mana"
│   │   └── stack-supabase-cloudflare.md  # stack opsional
│   └── scripts/fetch_reference_repo.sh   # clone repo banking untuk contoh nyata
├── nextjs-plan/SKILL.md
├── nextjs-test/SKILL.md
├── nextjs-review/SKILL.md
├── nextjs-bugreport/
│   ├── SKILL.md
│   └── references/bug-reporter.md        # instruksi subagent
└── nextjs-setup/
    ├── SKILL.md
    └── assets/CLAUDE.md
```

## Kustomisasi

Aturan bawaan bisa ditimpa per project: edit `AGENTS.md` di root project. Semua skill membaca
`AGENTS.md` lebih dulu, lalu jatuh ke `rules.md` jika tidak ada.

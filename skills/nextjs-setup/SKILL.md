---
name: nextjs-setup
description: Memasang file pendukung skill nextjs-* ke root project Next.js — AGENTS.md (aturan project, dibuat dari nextjs-code-style dan disesuaikan dengan stack di package.json), CLAUDE.md, subagent .claude/agents/bug-reporter.md, serta folder docs/plans dan docs/bug-reports. Gunakan saat user mengetik /nextjs-setup, atau meminta "setup aturan project", "buatkan AGENTS.md", "pasang nextjs skills ke project ini".
argument-hint: [kosong, atau "tanpa-claude" untuk melewati CLAUDE.md dan subagent]
disable-model-invocation: true
---

# /nextjs-setup — Pasang Aturan ke Project

Argumen: $ARGUMENTS

`npx skills add` hanya memasang folder skill. File yang harus berada di root project
(`AGENTS.md`, `CLAUDE.md`, subagent) dipasang oleh skill ini. **Jangan menimpa file yang
sudah ada tanpa persetujuan user.**

## Sumber file

| File di project | Sumber |
|---|---|
| `AGENTS.md` | `../nextjs-code-style/references/rules.md` (relatif ke folder skill ini), disesuaikan |
| `CLAUDE.md` | `assets/CLAUDE.md` di folder skill ini |
| `.claude/agents/bug-reporter.md` | `../nextjs-bugreport/references/bug-reporter.md` |

Jika skill `nextjs-code-style` atau `nextjs-bugreport` tidak ditemukan, minta user memasang semua skill:
`npx skills add rootchzt13/nextjs-skills`.

## Langkah

### 1. Pastikan ini project Next.js
Baca `package.json` di direktori kerja. Jika tidak ada dependency `next`, beri tahu user dan
tanya apakah tetap mau dilanjutkan. Catat stack yang benar-benar dipakai:
`next`, `react`, `typescript`, `tailwindcss`, shadcn (`components.json`), `zod`, `react-hook-form`,
library data/auth (`@supabase/*`, `@prisma/client`, `drizzle-orm`, `next-auth`, `better-auth`, ...),
cache (`@upstash/redis`, binding KV di `wrangler.jsonc`), captcha, test runner, dan apakah project memakai `src/`.

### 2. Cek file yang sudah ada
Untuk `AGENTS.md`, `CLAUDE.md`, dan `.claude/agents/bug-reporter.md`:
- Tidak ada → akan dibuat.
- Sudah ada → tampilkan ringkasan isinya dan tanya user: **lewati**, **timpa**, atau **gabungkan**
  (untuk `CLAUDE.md`, "gabungkan" berarti menambahkan baris `@AGENTS.md` dan tabel perintah jika belum ada).

### 3. Buat `AGENTS.md`
Salin isi `rules.md`, lalu sesuaikan:
- Judul jadi `# AGENTS.md — Instruksi Utama untuk Agent`, dan paragraf pembuka jadi:
  "File ini adalah sumber kebenaran untuk setiap agent (Claude Code, Codex, Cursor, dll.) yang bekerja
  di repo ini. Baca sampai selesai sebelum menulis kode. Instruksi langsung dari user di percakapan menang."
- **Bagian 1 (Tech Stack)**: ganti tabel default dengan stack yang terdeteksi di langkah 1, lengkap
  dengan versi mayor (`Next.js 16`, `Tailwind v4`, ...). Hapus baris yang tidak dipakai project.
- Jika project memakai Supabase/Cloudflare KV/Turnstile/vinext, tambahkan subbagian di bagian 6 berisi
  pola dari `../nextjs-code-style/references/stack-supabase-cloudflare.md` (lokasi file, nama fungsi,
  nama env) — cukup aturannya, tanpa template kode lengkap.
- Jika project memakai `src/`, sesuaikan semua path di bagian 2.
- Bagian 7 langkah 1: rujuk ke skill `nextjs-code-style` untuk contoh kode.
- Jangan mengubah aturan penamaan, anti-duplikasi, dan keamanan.

### 4. Buat `CLAUDE.md` dan subagent
Lewati langkah ini jika argumen berisi `tanpa-claude`.
- Salin `assets/CLAUDE.md` ke root project.
- Salin `../nextjs-bugreport/references/bug-reporter.md` ke `.claude/agents/bug-reporter.md` apa adanya.

### 5. Siapkan folder dokumen
Buat `docs/plans/.gitkeep` dan `docs/bug-reports/.gitkeep` jika belum ada.

### 6. Laporan
Tampilkan ke user:

```markdown
## Setup selesai

| File | Status |
|---|---|
| AGENTS.md | dibuat / dilewati / digabung |
| CLAUDE.md | ... |
| .claude/agents/bug-reporter.md | ... |
| docs/plans/, docs/bug-reports/ | ... |

Stack terdeteksi: Next.js 16, TypeScript, Tailwind v4, shadcn/ui, Prisma, ...

Coba: `/nextjs-plan <fitur pertama>`
```

Sarankan user membaca `AGENTS.md` sekali dan menyesuaikan aturan yang tidak cocok dengan timnya,
lalu commit file-file tersebut agar seluruh tim dan semua agent memakai aturan yang sama.

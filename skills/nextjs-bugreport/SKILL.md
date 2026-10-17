---
name: nextjs-bugreport
description: Menugaskan subagent pemeriksa bug untuk memeriksa kode project Next.js secara menyeluruh dan menghasilkan laporan bug terstruktur (ID, tingkat, lokasi, cara reproduksi, saran perbaikan) di docs/bug-reports/, tanpa mengubah kode. Gunakan saat user mengetik /nextjs-bugreport, atau berkata "cari bug", "audit kode", "ada yang error nggak", "periksa kemungkinan bug", "laporan bug", "hunting bug", baik untuk seluruh repo maupun area tertentu. Berbeda dari nextjs-review — review menilai perubahan terbaru terhadap aturan, sedangkan bugreport mencari cacat fungsional dan keamanan di kode yang sudah ada.
argument-hint: [area, file, atau fitur yang mau diperiksa, kosong = seluruh repo]
---

# /nextjs-bugreport — Laporan Bug oleh Subagent

Area: $ARGUMENTS

Pencarian bug didelegasikan ke subagent supaya:
- konteks percakapan utama tidak penuh oleh pembacaan puluhan file,
- pemeriksa tidak "bias" oleh kode yang baru saja ditulis di sesi ini,
- hasilnya berupa dokumen yang bisa dirujuk saat `/nextjs-plan` perbaikan.

Instruksi lengkap pemeriksa ada di [references/bug-reporter.md](references/bug-reporter.md).

## Langkah untuk agent utama

### 1. Siapkan konteks untuk subagent
Kumpulkan dalam satu pesan tugas:
- Area yang diperiksa (dari argumen). Jika kosong: seluruh `app/`, `components/`, `lib/`, `types/` (atau di dalam `src/` jika project memakainya).
- Daftar file di area itu (`git ls-files <area>`), agar subagent tidak perlu menebak.
- Perubahan terakhir jika relevan: `git log --oneline -10 -- <area>`.
- Nama file output: `docs/bug-reports/<YYYY-MM-DD>-<slug-area>.md`.
- **Path absolut** ke `references/bug-reporter.md` di folder skill ini.

### 2. Panggil subagent
Pilih jenis subagent:
- Jika project punya `.claude/agents/bug-reporter.md` (dipasang oleh skill `nextjs-setup`),
  pakai `subagent_type: "bug-reporter"`.
- Jika tidak, pakai subagent umum (`general-purpose`) dan minta ia membaca instruksi dari file referensi.

Isi prompt:

```
Baca dan ikuti instruksi pemeriksa bug di: <path absolut ke references/bug-reporter.md>
(lewati bagian ini jika kamu adalah agent bug-reporter)

Periksa area berikut untuk mencari bug: <area>
File yang termasuk:
<daftar file>

Tulis laporan ke: <path output>
Jangan mengubah file apa pun selain file laporan.
Setelah selesai, kembalikan ringkasan: jumlah bug per tingkat dan 3 bug paling penting.
```

Jika area besar (> 40 file), pecah menjadi beberapa subagent paralel per folder
(`lib/actions`, `components`, `app`), masing-masing menulis laporan sendiri, lalu agent utama
menggabungkan ringkasannya.

Jika tool subagent tidak tersedia di lingkungan ini, jalankan sendiri dengan mengikuti
`references/bug-reporter.md` sebagai instruksi, dan beri tahu user bahwa pemeriksaan
dilakukan tanpa subagent.

### 3. Sampaikan hasil ke user
Setelah subagent selesai, tampilkan di chat (maksimal 15 baris):

```markdown
## Laporan bug — <area>
Laporan lengkap: `docs/bug-reports/<file>.md`

| Tingkat | Jumlah |
|---|---|
| Kritis | 1 |
| Tinggi | 2 |
| Sedang | 4 |
| Rendah | 3 |

Paling penting:
1. **BUG-001 (Kritis)** `lib/actions/user.actions.ts:54` — updateProfile memakai userId dari client tanpa cek session.
2. ...
3. ...

Mau saya buatkan rencana perbaikan dengan `/nextjs-plan perbaiki BUG-001 BUG-002`?
```

Jangan langsung memperbaiki bug. Perbaikan lewat `/nextjs-plan` → implementasi → `/nextjs-test` →
`/nextjs-review`, agar setiap perbaikan terverifikasi.

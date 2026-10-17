---
name: nextjs-review
description: Memverifikasi ulang hasil kerja agent di project Next.js secara skeptis, bukan sekadar membaca ulang. Mengecek perubahan terhadap aturan project (penamaan, struktur, duplikasi, batas client/server, secret, otorisasi, invalidasi cache), menjalankan ulang tsc/lint/test untuk membuktikan klaim "sudah jalan", dan menghasilkan laporan temuan per tingkat keparahan. Gunakan saat user mengetik /nextjs-review, atau berkata "cek lagi", "verifikasi", "review kode", "periksa hasil tadi", "apa ada yang terlewat", atau setelah agent selesai mengerjakan tugas besar.
argument-hint: [file, folder, "staged", "branch", atau kosong = perubahan belum di-commit]
---

# /nextjs-review — Verifikasi Ulang Hasil Kerja

Lingkup: $ARGUMENTS

Sikap yang diharapkan: **reviewer yang tidak percaya sebelum melihat bukti.** Agent yang menulis
kode (mungkin kamu sendiri di giliran sebelumnya) bisa salah, lupa, atau mengklaim sesuatu yang
tidak dicek. Tugas skill ini adalah menemukan itu sebelum user menemukannya.

**Selama review, jangan mengubah kode.** Hanya laporkan. Perbaikan dilakukan setelah user
memilih temuan mana yang mau diperbaiki (atau user memintanya langsung).

## Sumber aturan

Baca `AGENTS.md` di root project jika ada. Jika tidak ada, pakai aturan dari skill
`nextjs-code-style`: `references/rules.md` (biasanya `../nextjs-code-style/references/rules.md`
relatif ke folder skill ini). Selanjutnya disebut **"aturan"**; nomor bagian (§) merujuk ke file itu.

## Langkah

### 1. Tentukan lingkup
| Argumen | Perintah untuk mendapatkan daftar file |
|---|---|
| kosong | `git status --porcelain` + `git diff` (perubahan belum di-commit, termasuk file baru) |
| `staged` | `git diff --cached` |
| `branch` | `git diff $(git merge-base HEAD main)...HEAD` (ganti `main` jika default branch beda) |
| path file/folder | file tersebut apa adanya |

Jika tidak ada perubahan sama sekali, katakan begitu dan berhenti.

### 2. Baca aturan, lalu baca perubahan
Baca aturan (terutama §3, §4, §5, §6, §8). Baca **seluruh** diff, bukan hanya file yang
kelihatan penting. Untuk setiap file yang diubah, buka juga file yang berhubungan
(tipe di `types/`, helper yang dipanggil, komponen induk).

### 3. Verifikasi klaim dengan menjalankan, bukan membaca
Jalankan dan catat hasil aslinya:
- `npx tsc --noEmit`
- `npm run lint` (jika ada script-nya)
- `npm test` atau runner yang ada di `package.json` (jika ada)
- Jika ada rencana di `docs/plans/` yang statusnya `disetujui` dan berkaitan: cocokkan tabel
  "Perubahan file" dan "Cara verifikasi" dengan yang benar-benar dikerjakan. Item yang dicentang
  tapi tidak terbukti → temuan.

Untuk setiap fungsi/komponen/tipe yang **dipanggil** di kode baru, pastikan benar-benar ada
(`rg "export (const|function) namaFungsi"`). Agent sering memanggil helper yang belum dibuat.

### 4. Checklist pemeriksaan
Periksa setiap poin terhadap setiap file yang berubah. Simpan temuan dengan `file:baris`.

**Penamaan (§3)**
- File komponen PascalCase, action `<domain>.actions.ts`, route kebab-case.
- Fungsi diawali kata kerja; boolean `is/has/can`; variabel deskriptif, tidak ada `data2`, `tmp`, `x`.
- Tipe `*Props` untuk komponen, `*Params` untuk action, ada di `types/index.d.ts` jika dipakai > 1 file.

**Duplikasi & reusabilitas (§5)** — bagian paling penting
- Jalankan `rg` untuk potongan logika yang baru ditulis: apakah sudah ada fungsi serupa di `lib/utils.ts` atau `lib/actions/`?
- Markup/komponen yang mirip dengan komponen yang sudah ada?
- Kombinasi class Tailwind yang sama muncul ≥ 2 kali dan belum jadi class semantik?
- Literal (route, label, limit, nama cookie/key) yang diulang dan belum masuk `constants/`?
- `interface`/`type` lokal yang menduplikasi tipe global?

**Struktur & pola (§2, §4)**
- Query/mutasi hanya di `lib/actions/`, bukan di komponen atau page.
- Server action: `"use server"`, komentar tujuan, satu object param, `try/catch`, `console.error("namaFungsi error:", error)`, `return null` saat gagal, dan **pemanggil menangani `null`**.
- `"use client"` hanya di komponen yang memakai hook/event/browser API; tidak ada di file yang seharusnya server.
- `params`, `searchParams`, `cookies()`, `headers()` di-`await` (Next.js 15+).
- Page: fetch data lalu kirim via props; tidak ada logika rumit di JSX.
- Urutan import sesuai §4.

**Keamanan & integrasi (§6)**
- File dengan secret (`*_SECRET*`, `*_SERVICE_ROLE*`, klien admin) diawali `import "server-only"` dan tidak terimpor dari client component. Tidak ada secret ber-prefix `NEXT_PUBLIC_`.
- Server action memastikan data milik user dari session; tidak percaya `userId` dari client.
- Input user divalidasi zod di sisi server, bukan hanya di form. Captcha (jika ada) diverifikasi **sebelum** menyentuh database.
- Setelah mutasi: `revalidatePath()`/`revalidateTag()` untuk yang terdampak, dan cache eksternal (KV/Redis) dihapus.

**Kebersihan**
- Tidak ada `console.log` sisa debug, kode mati yang di-comment, `any` baru, `// TODO` tanpa penjelasan.
- Tidak ada file di luar struktur §2 (`utils/`, `helpers/`, `services/` di root).

### 5. Tulis laporan
Tampilkan di chat dengan format ini:

```markdown
## Hasil Review — <lingkup>

**Keputusan: LULUS** / **PERLU PERBAIKAN** / **DITOLAK**
(LULUS = tidak ada temuan tinggi/sedang. DITOLAK = ada temuan tinggi yang merusak fungsi atau keamanan.)

### Bukti yang dijalankan
| Perintah | Hasil |
|---|---|
| npx tsc --noEmit | bersih / 3 error |
| npm run lint | ... |
| npm test | 12 lulus, 1 gagal |

### Temuan
| # | Tingkat | Lokasi | Masalah | Saran perbaikan |
|---|---|---|---|---|
| 1 | Tinggi | app/(root)/page.tsx:12 | hasil `getAccounts` dipakai tanpa menangani `null` | tambah `if (!accounts) return;` |
| 2 | Sedang | components/BankCard.tsx:8 | class `flex items-center gap-2 rounded-xl border p-4` juga ada di `BankInfo.tsx:11` | buat `.bank-card` di globals.css |
| 3 | Rendah | lib/utils.ts:90 | variabel `d` tidak deskriptif | ganti `transactionDate` |

### Yang sudah baik
- <1–3 poin, singkat, hanya yang benar-benar layak disebut>

### Langkah berikutnya
Perbaiki #1 dan #2 sekarang? Atau sebutkan nomor temuan yang mau diperbaiki.
```

Tingkat keparahan:
- **Tinggi**: bug yang merusak fungsi, secret bocor ke client, data user lain bisa diakses, data tidak tervalidasi di server, cache tidak di-invalidate sehingga user melihat data basi.
- **Sedang**: duplikasi yang jelas, pelanggaran struktur (query di komponen), penamaan yang menyesatkan, klaim di rencana yang tidak terbukti.
- **Rendah**: gaya, urutan import, komentar, nama variabel kurang deskriptif di lingkup kecil.

Jika tidak ada temuan sama sekali, tetap tampilkan tabel "Bukti yang dijalankan". Keputusan LULUS
tanpa bukti bukan review.

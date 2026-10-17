---
name: nextjs-plan
description: Membuat rencana implementasi tertulis SEBELUM menulis kode, untuk fitur, perubahan, atau perbaikan di project Next.js. Gunakan saat user mengetik /nextjs-plan, atau meminta "buat rencana", "rencanakan dulu", "planning", "breakdown tugas", "mau tambah fitur X" tanpa menyuruh langsung coding. Rencana disimpan ke docs/plans/ dan harus disetujui user sebelum implementasi dimulai.
argument-hint: [deskripsi fitur atau perubahan]
disable-model-invocation: true
---

# /nextjs-plan — Rencana Implementasi

Tugas: $ARGUMENTS

Tujuan skill ini: memaksa berpikir dulu sebelum menulis kode, supaya hasilnya sesuai aturan
project, tidak duplikat, dan user bisa mengoreksi arah sebelum ada kode yang ditulis.

**Selama skill ini berjalan, jangan membuat atau mengubah file kode apa pun.** Satu-satunya file
yang boleh ditulis adalah file rencana di `docs/plans/`.

## Sumber aturan

Baca `AGENTS.md` di root project jika ada. Jika tidak ada, pakai aturan dari skill
`nextjs-code-style`: `references/rules.md` (biasanya `../nextjs-code-style/references/rules.md`
relatif ke folder skill ini). Selanjutnya disebut **"aturan"**; nomor bagian (§) merujuk ke file itu.
Jika keduanya tidak ditemukan, beri tahu user untuk memasang
`npx skills add rootchzt13/nextjs-skills --skill nextjs-code-style`.

## Langkah

### 1. Pahami konteks (jangan dilewati)
- Baca aturan dan `package.json` (stack yang benar-benar dipakai).
- Cari yang sudah ada dan relevan dengan tugas:
  - `rg -n "<kata kunci>" lib components app types constants` untuk fungsi, komponen, tipe yang bisa dipakai ulang.
  - `ls components lib/actions` untuk daftar yang sudah ada.
  - `cat types/index.d.ts` untuk tipe yang sudah ada.
- Catat apa yang **bisa dipakai ulang** dan apa yang **belum ada**. Ini bagian paling penting dari rencana.

### 2. Klarifikasi hanya jika benar-benar ambigu
Jika ada keputusan yang mengubah arah besar (misal: butuh tabel/model database baru, atau fitur
bisa diartikan dua cara), tanyakan ke user **sebelum** menulis rencana. Maksimal 3 pertanyaan, singkat.
Kalau bisa diasumsikan dengan aman, tulis asumsinya di rencana, jangan bertanya.

### 3. Tulis rencana
Simpan ke `docs/plans/<YYYY-MM-DD>-<slug-kebab>.md` (buat folder jika belum ada).
Gunakan template ini persis:

```markdown
# Rencana: <judul singkat>

Tanggal: <YYYY-MM-DD>
Status: menunggu persetujuan

## Tujuan
<1–3 kalimat: apa yang user dapat setelah ini selesai>

## Lingkup
Termasuk:
- ...
Tidak termasuk (sengaja):
- ...

## Asumsi
- ...

## Yang dipakai ulang (sudah ada)
| Jenis | Nama | Lokasi | Dipakai untuk |
|---|---|---|---|
| helper | formatAmount | lib/utils.ts | ... |

## Perubahan file
| Aksi | File | Isi / nama identifier utama |
|---|---|---|
| buat | components/MonthlyTransactionCard.tsx | komponen `MonthlyTransactionCard` |
| ubah | types/index.d.ts | tambah `MonthlyTransactionCardProps` |
| ubah | lib/utils.ts | tambah `countTransactionsThisMonth()` |

## Data & tipe
<tipe baru, perubahan schema database (tabel/kolom/policy), key cache, env baru>

## Langkah implementasi (urut)
1. ...
2. ...

## Cara verifikasi
- [ ] <perintah atau cek manual yang membuktikan fitur bekerja>
- [ ] `npx tsc --noEmit` dan `npm run lint` bersih
- [ ] <test yang perlu ditambah>

## Risiko & hal yang perlu diperhatikan
- ...

## Pertanyaan terbuka
- ... (atau "tidak ada")
```

Aturan isi:
- Nama file/fungsi/komponen di tabel **sudah final** dan mengikuti tabel penamaan di aturan §3.
  Implementasi nanti tinggal mengikuti, bukan menamai ulang.
- Setiap file yang "buat" harus dijelaskan kenapa tidak bisa memakai yang sudah ada.
- Langkah implementasi diurutkan agar setiap langkah bisa di-compile: tipe → helper → action → komponen → page.
- Jangan menulis kode lengkap di rencana. Signature fungsi dan nama props cukup.

### 4. Sampaikan ke user
Di chat, tulis ringkasan maksimal 10 baris: tujuan, file yang disentuh, dan pertanyaan terbuka (jika ada).
Lalu tanya: **"Setujui rencana ini, atau ada yang mau diubah?"**

Jangan mulai implementasi sampai user menyetujui. Setelah disetujui, ubah `Status:` di file
rencana menjadi `disetujui`, kerjakan sesuai urutan langkah, dan centang "Cara verifikasi"
satu per satu saat terbukti. Setelah selesai, sarankan user menjalankan `/nextjs-test` lalu `/nextjs-review`.

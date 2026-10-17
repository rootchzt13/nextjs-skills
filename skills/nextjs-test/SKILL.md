---
name: nextjs-test
description: Menjalankan seluruh pemeriksaan otomatis di project Next.js (type check, lint, unit/integration test) dan memperbaiki kode sampai semuanya lulus, dengan batas iterasi dan tanpa melemahkan test. Juga menulis test yang hilang untuk kode yang berubah, dan menyiapkan Vitest jika project belum punya test runner. Gunakan saat user mengetik /nextjs-test, atau berkata "jalankan test", "pastikan semua pass", "tes semua kode", "kenapa test gagal", "tambahkan test", atau sebelum commit/deploy.
argument-hint: [file, folder, nama test, atau kosong = semua]
---

# /nextjs-test — Jalankan Sampai Lulus

Lingkup: $ARGUMENTS

Tujuan: setelah skill ini selesai, `tsc`, `lint`, dan test runner semuanya hijau, **dan**
kode yang berubah punya test yang bermakna. "Lulus" dicapai dengan memperbaiki kode, bukan
dengan menghapus assertion, menambah `skip`, atau memperlonggar `expect`.

## Sumber aturan

Perbaikan kode mengikuti `AGENTS.md` di root project jika ada; jika tidak, aturan dari skill
`nextjs-code-style` (`../nextjs-code-style/references/rules.md` relatif ke folder skill ini).

## Langkah

### 1. Deteksi alat yang ada
Baca `package.json`:
- `scripts.test` dan devDependencies: `vitest`, `jest`, `@playwright/test`, `@testing-library/react`.
- `scripts.lint`, `scripts.typecheck`. (Next.js 16 menghapus `next lint`; jika `scripts.lint`
  masih `next lint`, sampaikan ke user dan sarankan `eslint .`.)

Jika **tidak ada test runner**, pasang Vitest (setup yang direkomendasikan dokumentasi Next.js):
```bash
npm i -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/dom @testing-library/jest-dom vite-tsconfig-paths
```
Tambahkan ke `package.json`:
```json
"test": "vitest run",
"test:watch": "vitest",
"typecheck": "tsc --noEmit"
```
Buat `vitest.config.mts`:
```ts
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig({
  plugins: [tsconfigPaths(), react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./tests/setup.ts"],
    include: ["**/*.test.{ts,tsx}"],
    exclude: ["node_modules", ".next"],
  },
});
```
dan `tests/setup.ts` berisi `import "@testing-library/jest-dom/vitest";`.
Beri tahu user bahwa runner baru dipasang; jangan diam-diam.

### 2. Tentukan lingkup
- Kosong → semua test, seluruh repo.
- Path/folder → test di path itu **dan** test yang mengimpor file di path itu (`rg -l "from \"@/<path>" --glob "*.test.*"`).
- Nama → `npx vitest run -t "<nama>"`.

Selain itu, selalu jalankan `tsc --noEmit` dan `lint` untuk seluruh repo, karena error tipe di
satu file bisa berasal dari file lain.

### 3. Tulis test yang hilang (sebelum loop perbaikan)
Untuk setiap file yang berubah (`git diff --name-only` + untracked) yang belum punya test:

| Jenis file | Lokasi test | Apa yang dites |
|---|---|---|
| `lib/utils.ts` (helper murni) | `lib/utils.test.ts` | input → output, termasuk kasus kosong/null/negatif |
| `lib/actions/*.actions.ts` | `lib/actions/<domain>.actions.test.ts` | mock klien data (`vi.mock("@/lib/db")`), session, dan cache; tes jalur sukses, jalur error mengembalikan `null`, data user lain ditolak, cache/path di-invalidate setelah mutasi, captcha dicek sebelum DB (jika ada) |
| `components/*.tsx` presentasi | `components/<Nama>.test.tsx` | render dengan props, teks/elemen muncul, default props bekerja |
| `components/*.tsx` form (client) | `components/<Nama>.test.tsx` | validasi zod menolak input salah, submit memanggil action dengan data benar |
| `app/**/page.tsx`, `layout.tsx` | tidak dites unit | Vitest belum mendukung async server component; dicakup lewat action + komponen (atau E2E jika ada Playwright) |
| `components/ui/*` (shadcn) | tidak dites | kode pihak ketiga |

Gaya test mengikuti aturan penamaan: `describe("formatAmount")`, `it("returns USD format with two decimals")`,
variabel deskriptif, satu perilaku per `it`. Mock modul server lewat `vi.mock(...)`;
`next/navigation`, `next/headers`, dan `next/cache` juga perlu di-mock di test action/komponen.
Jangan menulis test yang hanya mengulang implementasi (`expect(add(1,2)).toBe(1+2)`).

### 4. Loop perbaikan (maksimal 5 iterasi)
```
ulangi:
  jalankan: npx tsc --noEmit && npm run lint && npm test -- <lingkup>
  jika semua hijau → keluar
  untuk setiap kegagalan:
    baca pesan error dan stack trace sepenuhnya
    tentukan: kode salah, atau test salah?
      - kode salah (umumnya) → perbaiki kode sesuai aturan
      - test salah (ekspektasi tidak sesuai spesifikasi, mock salah) → perbaiki test
        DAN jelaskan di laporan kenapa test yang diubah, bukan kode
    perbaiki akar masalah, bukan gejala (jangan tambah `?.` atau `as any` untuk membungkam)
  iterasi += 1
```
Dilarang sebagai cara "meluluskan":
- `it.skip`, `xit`, `test.todo`, menghapus assertion, mengganti `toBe` jadi `toBeTruthy`.
- `// @ts-ignore`, `// eslint-disable` tanpa alasan tertulis.
- Mengubah snapshot tanpa membaca diff-nya.

Setelah 5 iterasi masih gagal: **berhenti**, jangan memaksa. Laporkan apa yang sudah dicoba,
error yang tersisa, dan hipotesis penyebabnya. Lebih baik user tahu daripada test dibuat palsu.

Jika ada test yang gagal **bukan karena perubahan sekarang** (sudah gagal di branch utama), catat sebagai
"gagal sebelumnya" dan tanyakan user apakah mau diperbaiki sekalian.

### 5. Laporan
```markdown
## Hasil /nextjs-test — <lingkup>

| Pemeriksaan | Hasil | Iterasi |
|---|---|---|
| tsc --noEmit | ✅ bersih | 2 |
| lint | ✅ bersih | 1 |
| vitest | ✅ 24 lulus, 0 gagal | 3 |

### Test baru
- `lib/utils.test.ts` — 6 kasus untuk `countTransactionsThisMonth`
- `lib/actions/bank.actions.test.ts` — 4 kasus (sukses, error → null, data user lain ditolak, invalidasi)

### Perbaikan yang dilakukan
| File | Masalah | Perbaikan |
|---|---|---|
| lib/utils.ts:88 | bulan dibandingkan sebagai string | pakai `getMonth()` + `getFullYear()` |

### Test yang diubah (dengan alasan)
- tidak ada / <file: alasan>

### Belum lulus (jika ada)
- <error, yang sudah dicoba, hipotesis>
```

Setelah hijau, sarankan `/nextjs-review` jika perubahan kodenya cukup besar.

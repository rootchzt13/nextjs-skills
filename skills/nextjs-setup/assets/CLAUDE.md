# CLAUDE.md

Claude Code membaca file ini otomatis. Semua instruksi utama ada di AGENTS.md;
baris di bawah mengimpor isinya sehingga ada satu sumber kebenaran untuk semua agent.

@AGENTS.md

Sebelum menulis atau mengubah kode, gunakan juga skill `nextjs-code-style`.

## Perintah kerja (skill)

| Perintah | Fungsi |
|---|---|
| `/nextjs-plan <tugas>` | Buat rencana ke `docs/plans/`, tunggu persetujuan, baru implementasi |
| `/nextjs-test [lingkup]` | tsc + lint + test, perbaiki sampai lulus, tulis test yang hilang |
| `/nextjs-review [lingkup]` | Verifikasi ulang hasil kerja terhadap AGENTS.md dengan bukti |
| `/nextjs-bugreport [area]` | Subagent `bug-reporter` menulis laporan bug ke `docs/bug-reports/` |

Alur yang disarankan untuk tugas besar: `/nextjs-plan` → implementasi → `/nextjs-test` → `/nextjs-review`.

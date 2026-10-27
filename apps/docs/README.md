# apps/docs: jejak pengerjaan

Catatan per tugas selama pembangunan. Aturan lengkap: `../../.cursor/rules/` dan `../../Dokument/`.

| Folder | Isi | Indeks |
| --- | --- | --- |
| `version/` | Rencana dan riwayat perubahan: kapan, kenapa, file apa yang berubah | `VERSION_INDEX.md` |
| `todo/` | Backlog per fase atau inisiatif, dengan daftar periksa | `TODO_INDEX.md` |
| `features/<area>/` | Dokumen fitur: alur kerja, aturan bisnis, endpoint, cara uji | `FEATURE_INDEX.md` |
| `flows/` | Diagram alur eksekusi lintas fitur | `FLOWS_INDEX.md` |

Templat berawalan garis bawah: `_VERSION_TEMPLATE.md`, `_TODO_TEMPLATE.md`, `_FEATURE_TEMPLATE.md`. Salin, jangan edit templat.

Periksa tabel atribut dengan `powershell -File ../scripts/verify-frontmatter.ps1`.

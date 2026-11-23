"use client";
import { ExternalLink, FileText, X } from "lucide-react";
import { useState } from "react";
import { unduhBerkas } from "@/lib/api";
import { useDokumen } from "@/lib/hooks";

/**
 * Lampiran yang tertanam di gelembung pesan pengguna. Diklik membuka pratinjau: teks yang dibaca asisten dan tombol
 * membuka berkas asli dari server. Dokumen dicocokkan lewat nama berkas (yang terbaru bila ada beberapa).
 */
export function PratinjauLampiran({ nama }: { nama: string }) {
  const [buka, setBuka] = useState(false);
  return (
    <>
      <button
        type="button"
        onClick={() => setBuka(true)}
        className="inline-flex max-w-full items-center gap-1.5 rounded-[10px] bg-white/20 px-2 py-1 text-xs font-semibold transition-colors hover:bg-white/30 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
        aria-label={`Lihat pratinjau ${nama}`}
      >
        <FileText className="h-3.5 w-3.5 shrink-0" aria-hidden />
        <span className="truncate">{nama}</span>
      </button>
      {buka && <Dialog nama={nama} tutup={() => setBuka(false)} />}
    </>
  );
}

function Dialog({ nama, tutup }: { nama: string; tutup: () => void }) {
  const dok = useDokumen();
  const [membuka, setMembuka] = useState(false);
  const [galat, setGalat] = useState<string | null>(null);
  const d = (dok.data ?? []).filter((x) => x.nama_berkas === nama).sort((a, b) => b.tanggal_unggah.localeCompare(a.tanggal_unggah))[0];
  const ringkasan = typeof d?.hasil_baca?.ringkasan_teks === "string" ? (d.hasil_baca.ringkasan_teks as string) : null;

  async function lihatAsli() {
    if (!d) return;
    setMembuka(true);
    setGalat(null);
    try {
      const url = URL.createObjectURL(await unduhBerkas(`/me/dokumen/${d.id}/berkas`));
      window.open(url, "_blank", "noopener");
      setTimeout(() => URL.revokeObjectURL(url), 60000);
    } catch (e) {
      setGalat(e instanceof Error ? e.message : "Gagal membuka berkas.");
    } finally {
      setMembuka(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-0 sm:items-center sm:p-6" role="dialog" aria-modal="true" aria-label={`Pratinjau ${nama}`} onClick={tutup}>
      <div className="max-h-[85vh] w-full max-w-2xl overflow-y-auto rounded-t-[24px] bg-card p-5 text-ink shadow-xl sm:rounded-[24px]" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <p className="truncate text-base font-bold text-navy">{nama}</p>
            <p className="text-xs text-muted">Lampiran chat</p>
          </div>
          <button type="button" onClick={tutup} aria-label="Tutup pratinjau" className="rounded-full p-2 hover:bg-c2">
            <X className="h-5 w-5" aria-hidden />
          </button>
        </div>
        {dok.isPending && <p className="mt-4 text-sm">Memuat pratinjau</p>}
        {dok.isError && <p className="mt-4 text-sm text-danger-ink">Pratinjau tidak dapat dimuat. Coba lagi nanti.</p>}
        {!dok.isPending && !dok.isError && !d && (
          <p className="mt-4 text-sm">Berkas ini tidak ada di server (mungkin sudah dihapus otomatis atau manual), jadi pratinjaunya tidak tersedia.</p>
        )}
        {d && (
          <div className="mt-4 space-y-3">
            {d.ada_berkas && (
              <button type="button" onClick={() => void lihatAsli()} disabled={membuka} className="inline-flex items-center gap-2 rounded-[14px] border border-c4 px-4 py-2 text-sm font-semibold text-primary hover:bg-c2 disabled:opacity-60">
                <ExternalLink className="h-4 w-4" aria-hidden /> {membuka ? "Membuka" : "Buka berkas asli"}
              </button>
            )}
            {galat && <p className="text-sm text-danger-ink">{galat}</p>}
            {ringkasan ? (
              <div>
                <p className="mb-1 text-xs font-bold text-navy">Teks yang dibaca asisten</p>
                <pre className="max-h-[50vh] overflow-auto whitespace-pre-wrap rounded-[14px] border border-c4 bg-c1 p-3 text-xs leading-relaxed">{ringkasan.length > 6000 ? `${ringkasan.slice(0, 6000)}\n...` : ringkasan}</pre>
              </div>
            ) : (
              <p className="text-sm">Teks hasil baca belum tersedia untuk berkas ini.</p>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

"use client";
import { Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { GalatState, MemuatState } from "@/components/state";
import { JudulHalaman, Kartu, Masukan, Pilihan, Tombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { useAksi, useMemori, useStatistikMemori } from "@/lib/hooks";
import type { ButirMemori } from "@/lib/types";

const JENIS = ["keahlian", "prestasi", "organisasi", "sertifikat", "pengalaman", "minat", "kepribadian", "lainnya"];
const KUNCI = [["memori"]] as const;

function Butir({ b, utama }: { b: ButirMemori; utama: boolean }) {
  const [sunting, setSunting] = useState(false);
  const [isi, setIsi] = useState(b.isi);
  const ubah = useAksi((v: { isi?: string; aktif?: boolean }) => kirim(`/me/memori/${b.id}`, "PATCH", v), ...KUNCI);
  const hapus = useAksi(() => kirim(`/me/memori/${b.id}`, "DELETE"), ...KUNCI);
  return (
    <li className={`rounded-[14px] border border-c4 bg-card p-3 ${utama && b.aktif ? "" : "opacity-50"}`}>
      <div className="flex items-start gap-3">
        <div className="min-w-0 flex-1">
          <p className="text-xs font-bold uppercase text-muted">{b.jenis}</p>
          {sunting ? (
            <div className="mt-1 flex gap-2">
              <Masukan aria-label="Isi memori" value={isi} maxLength={480} onChange={(e) => setIsi(e.target.value)} />
              <Tombol
                onClick={() => {
                  ubah.mutate({ isi });
                  setSunting(false);
                }}
              >
                Simpan
              </Tombol>
            </div>
          ) : (
            <button type="button" className="text-left text-sm text-ink" onClick={() => setSunting(true)} aria-label="Sunting memori">
              {b.isi}
            </button>
          )}
        </div>
        <label className="flex items-center gap-2 text-xs">
          <input type="checkbox" role="switch" checked={b.aktif} onChange={(e) => ubah.mutate({ aktif: e.target.checked })} aria-label={`Pakai memori: ${b.isi}`} />
          Pakai
        </label>
        <button type="button" aria-label="Hapus memori" onClick={() => hapus.mutate()} className="flex h-9 w-9 items-center justify-center rounded-full text-muted hover:bg-c2">
          <Trash2 className="h-4 w-4" aria-hidden />
        </button>
      </div>
    </li>
  );
}

export default function MemoriAI() {
  const daftar = useMemori();
  const stat = useStatistikMemori();
  const [jenis, setJenis] = useState("lainnya");
  const [baru, setBaru] = useState("");
  const tambah = useAksi((v: { jenis: string; isi: string }) => kirim("/me/memori", "POST", v), ...KUNCI);
  const saklar = useAksi((aktif: boolean) => kirim("/me/memori/pengaturan", "PUT", { aktif }), ...KUNCI);
  const hapusSemua = useAksi(() => kirim("/me/memori", "DELETE"), ...KUNCI);
  const utama = stat.data?.memori_aktif ?? true;

  return (
    <div className="halaman-masuk">
      <JudulHalaman
        judul="Memori AI"
        deskripsi="Hal yang dipelajari asisten dari dokumen dan percakapan Anda. Disimpan terenkripsi di server dan hanya Anda yang dapat melihatnya."
        aksi={
          (daftar.data?.length ?? 0) > 0 ? (
            <Tombol varian="hantu" onClick={() => confirm("Hapus seluruh memori?") && hapusSemua.mutate()}>
              <Trash2 className="h-4 w-4" aria-hidden /> Hapus semua
            </Tombol>
          ) : undefined
        }
      />
      <Kartu className="mb-4">
        <label className="flex items-start gap-3">
          <input type="checkbox" role="switch" className="mt-1" checked={utama} onChange={(e) => saklar.mutate(e.target.checked)} aria-label="Pakai memori saat menjawab" />
          <span>
            <span className="block text-sm font-bold text-navy">Pakai memori saat menjawab</span>
            <span className="block text-sm text-ink">Hidup: jawaban lebih personal dan pintar, tetapi sedikit lebih lambat dan lebih berat. Mati: jawaban umum, lebih cepat.</span>
          </span>
        </label>
        {stat.data && (
          <p className="mt-3 border-t border-c4 pt-3 text-sm font-semibold text-ink">
            Dipakai {stat.data.jumlah_dipakai} dari {stat.data.jumlah} butir, menambah sekitar {stat.data.perkiraan_token} token pada tiap pertanyaan.
          </p>
        )}
      </Kartu>
      <form
        className="mb-4 flex flex-wrap gap-2"
        onSubmit={(e) => {
          e.preventDefault();
          if (!baru.trim()) return;
          tambah.mutate({ jenis, isi: baru.trim() });
          setBaru("");
        }}
      >
        <Pilihan aria-label="Jenis memori" value={jenis} onChange={(e) => setJenis(e.target.value)}>
          {JENIS.map((j) => (
            <option key={j}>{j}</option>
          ))}
        </Pilihan>
        <div className="min-w-[200px] flex-1">
          <Masukan aria-label="Memori baru" placeholder="Contoh: Aktif sebagai relawan mengajar 2 tahun" maxLength={480} value={baru} onChange={(e) => setBaru(e.target.value)} />
        </div>
        <Tombol type="submit" disabled={!baru.trim()}>
          <Plus className="h-4 w-4" aria-hidden /> Tambah
        </Tombol>
      </form>
      {daftar.isPending ? (
        <MemuatState baris={3} />
      ) : daftar.isError ? (
        <GalatState galat={daftar.error} onCoba={() => daftar.refetch()} />
      ) : daftar.data.length === 0 ? (
        <p className="text-sm text-ink">Belum ada memori. Lampirkan CV atau sertifikat di chatbot, atau unggah di Dokumen Saya.</p>
      ) : (
        <ul className="space-y-2">
          {daftar.data.map((b) => (
            <Butir key={b.id} b={b} utama={utama} />
          ))}
        </ul>
      )}
    </div>
  );
}

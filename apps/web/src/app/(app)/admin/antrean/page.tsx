"use client";
import { CircleCheck, Flag } from "lucide-react";
import Link from "next/link";
import { BantuanAdmin } from "@/components/BantuanAdmin";
import { KosongState, Tampil } from "@/components/state";
import { useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { ChipFilter, Kartu, JudulHalaman, Masukan, TautanTombol, Tombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { useAntrean, usePengaturan } from "@/lib/hooks";
import { tanggalIndo } from "@/lib/format";

function PanelAi() {
  const qc = useQueryClient();
  const pengaturan = usePengaturan();
  const [info, setInfo] = useState<string | null>(null);
  const [sibuk, setSibuk] = useState(false);
  const aktif = pengaturan.data?.auto_validasi_ai ?? true;

  async function ubah(nilai: boolean) {
    await kirim("/admin/pengaturan", "PUT", { auto_validasi_ai: nilai });
    await qc.invalidateQueries({ queryKey: ["admin", "pengaturan"] });
  }
  async function jalankan() {
    setSibuk(true);
    setInfo(null);
    try {
      const r = await kirim<Record<string, number>>("/admin/validasi-ai/jalankan", "POST");
      setInfo(`Diproses ${r.data.diproses}: terbit ${r.data.terbit}, kedaluwarsa ${r.data.kedaluwarsa}, tetap menunggu ${r.data.menunggu}.`);
      await qc.invalidateQueries({ queryKey: ["admin"] });
    } catch (e) {
      setInfo(e instanceof Error ? e.message : "Validasi AI gagal");
    } finally {
      setSibuk(false);
    }
  }
  return (
    <Kartu className="mb-4">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <label className="flex min-h-11 items-start gap-3 text-sm text-ink">
          <input type="checkbox" checked={aktif} onChange={(e) => ubah(e.target.checked)} className="mt-1 h-5 w-5 accent-primary" />
          <span>
            <span className="font-semibold text-navy">Validasi otomatis oleh AI</span>
            <span className="block text-xs text-muted">
              AI membaca laman resmi dan menormalkan datanya. Beasiswa terbit hanya bila tenggat tertulis jelas di laman (minimal 3 hari lagi). Tiap beasiswa
              diproses AI satu kali.
            </span>
          </span>
        </label>
        <Tombol onClick={jalankan} disabled={sibuk}>
          {sibuk ? "Memproses" : "Validasi AI sekarang"}
        </Tombol>
      </div>
      {info && <p role="status" className="mt-3 text-sm text-ink">{info}</p>}
    </Kartu>
  );
}

type Saring = "semua" | "ditandai";

export default function Antrean() {
  const kueri = useAntrean();
  const qc = useQueryClient();
  const [saring, setSaring] = useState<Saring>("semua");
  const [cari, setCari] = useState("");
  const [pilih, setPilih] = useState<Set<string>>(new Set());
  const [alasan, setAlasan] = useState("");
  const [sibuk, setSibuk] = useState(false);
  const [info, setInfo] = useState<string | null>(null);

  const data = kueri.data;
  const daftar = useMemo(() => data ?? [], [data]);
  const tampil = useMemo(() => {
    const k = cari.trim().toLowerCase();
    return daftar.filter((a) => (saring === "semua" || a.alasan_ditandai) && (!k || `${a.nama} ${a.penyelenggara ?? ""} ${a.nama_sumber}`.toLowerCase().includes(k)));
  }, [daftar, saring, cari]);
  const ditandai = daftar.filter((a) => a.alasan_ditandai).length;

  const ubahPilih = (id: string, ya: boolean) =>
    setPilih((s) => {
      const n = new Set(s);
      if (ya) n.add(id);
      else n.delete(id);
      return n;
    });
  const pilihSemuaTampil = () => setPilih(new Set(tampil.map((a) => a.id)));

  async function tolakTerpilih() {
    const teks = alasan.trim();
    if (pilih.size === 0 || teks.length < 3) return;
    if (!window.confirm(`Tolak ${pilih.size} beasiswa dengan alasan "${teks}"? Beasiswa yang ditolak tidak muncul lagi di antrean.`)) return;
    setSibuk(true);
    setInfo(null);
    let berhasil = 0;
    let gagal = 0;
    for (const id of pilih) {
      try {
        await kirim(`/admin/beasiswa/${id}/tolak`, "POST", { alasan: teks });
        berhasil += 1;
      } catch {
        gagal += 1;
      }
    }
    setPilih(new Set());
    setAlasan("");
    setInfo(`${berhasil} beasiswa ditolak${gagal ? `, ${gagal} gagal diproses` : ""}.`);
    setSibuk(false);
    await qc.invalidateQueries({ queryKey: ["admin"] });
  }

  return (
    <div className="halaman-masuk">
      <JudulHalaman judul="Antrean Validasi" deskripsi="Beasiswa hasil pemantauan yang perlu diperiksa sebelum terbit." />
      <BantuanAdmin>
        <p>Buka satu beasiswa lewat Periksa untuk memperbaiki data, lalu Terbitkan atau Tolak. Untuk banyak sekaligus, centang beasiswa, isi alasan, lalu Tolak yang dipilih.</p>
        <p>Beasiswa yang laman resminya menolak robot (403) ditandai merah. Pakai filter Ditandai, Pilih semua, lalu tolak sekali jalan. Yang ditolak tidak dicoba lagi pada pemantauan berikutnya.</p>
      </BantuanAdmin>
      <PanelAi />
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <ChipFilter aktif={saring === "semua"} onClick={() => setSaring("semua")}>Semua ({daftar.length})</ChipFilter>
        <ChipFilter aktif={saring === "ditandai"} onClick={() => setSaring("ditandai")}>Ditandai ({ditandai})</ChipFilter>
        <Masukan aria-label="Cari di antrean" placeholder="Cari nama, penyelenggara, atau sumber" value={cari} onChange={(e) => setCari(e.target.value)} className="min-w-0 flex-1 sm:max-w-xs" />
      </div>
      {pilih.size > 0 && (
        <div role="region" aria-label="Aksi massal" className="mb-4 flex flex-wrap items-center gap-3 rounded-kartu border border-primary/40 bg-c2 p-4 text-sm">
          <span className="font-semibold text-navy">{pilih.size} dipilih</span>
          <Masukan aria-label="Alasan penolakan" placeholder="Alasan penolakan (wajib)" value={alasan} onChange={(e) => setAlasan(e.target.value)} className="min-w-0 flex-1 sm:max-w-sm" />
          <Tombol onClick={tolakTerpilih} disabled={sibuk || alasan.trim().length < 3}>
            {sibuk ? "Menolak" : "Tolak yang dipilih"}
          </Tombol>
          <Tombol varian="sekunder" onClick={() => setPilih(new Set())} disabled={sibuk}>Batal</Tombol>
        </div>
      )}
      {info && <p role="status" className="mb-4 rounded-kontrol bg-c1 px-3 py-2 text-sm text-ink">{info}</p>}
      <Tampil kueri={kueri} kosong={<KosongState ikon={CircleCheck} judul="Antrean kosong" pesan="Semua beasiswa sudah divalidasi. Jalankan pemantauan sumber untuk menemukan yang baru." aksi={<TautanTombol href="/admin/sumber" varian="sekunder">Kelola sumber</TautanTombol>} />}>
        {() =>
          tampil.length === 0 ? (
            <KosongState ikon={CircleCheck} judul="Tidak ada yang cocok" pesan="Ubah filter atau kata pencarian." aksi={<Tombol varian="sekunder" onClick={() => { setSaring("semua"); setCari(""); }}>Hapus filter</Tombol>} />
          ) : (
            <>
              <div className="mb-2 flex items-center justify-between text-sm">
                <span className="text-muted">{tampil.length} beasiswa</span>
                <button type="button" onClick={pilihSemuaTampil} className="min-h-11 font-semibold text-primary underline">
                  Pilih semua yang tampil
                </button>
              </div>
              <ul className="space-y-3">
                {tampil.map((a) => (
                  <li key={a.id} className="rounded-kartu border border-c4/60 bg-card p-5 shadow-kartu">
                    <div className="flex flex-wrap items-start justify-between gap-3">
                      <label className="flex min-w-0 flex-1 items-start gap-3">
                        <input type="checkbox" aria-label={`Pilih ${a.nama}`} checked={pilih.has(a.id)} onChange={(e) => ubahPilih(a.id, e.target.checked)} className="mt-1 h-5 w-5 shrink-0 accent-primary" />
                        <span className="min-w-0">
                          <Link href={`/admin/antrean/${a.id}`} className="text-base font-bold text-navy hover:underline">
                            {a.nama}
                          </Link>
                          <span className="block text-sm text-ink">
                            {a.penyelenggara ?? "Penyelenggara belum terbaca"} | Sumber: {a.nama_sumber}
                          </span>
                          <span className="block text-xs text-muted">Tenggat {tanggalIndo(a.tenggat)}</span>
                        </span>
                      </label>
                      <TautanTombol href={`/admin/antrean/${a.id}`}>Periksa</TautanTombol>
                    </div>
                    {a.alasan_ditandai && (
                      <p className="mt-3 flex items-start gap-2 rounded-[14px] bg-danger-soft px-3 py-2 text-sm text-danger-ink">
                        <Flag className="mt-0.5 h-4 w-4 shrink-0" aria-hidden /> {a.alasan_ditandai}
                      </p>
                    )}
                  </li>
                ))}
              </ul>
            </>
          )
        }
      </Tampil>
    </div>
  );
}

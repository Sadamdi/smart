"use client";
import { Flag } from "lucide-react";
import Link from "next/link";
import { KosongState, Tampil } from "@/components/state";
import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { Kartu, JudulHalaman, Tombol } from "@/components/ui";
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
        <label className="flex items-start gap-3 text-sm text-ink">
          <input type="checkbox" checked={aktif} onChange={(e) => ubah(e.target.checked)} className="mt-1 h-4 w-4 accent-primary" />
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

export default function Antrean() {
  const kueri = useAntrean();
  return (
    <div>
      <JudulHalaman judul="Antrean Validasi" deskripsi="Beasiswa hasil pemantauan yang perlu diperiksa sebelum terbit." />
      <PanelAi />
      <Tampil kueri={kueri} kosong={<KosongState judul="Antrean kosong" pesan="Semua beasiswa sudah divalidasi." />}>
        {(daftar) => (
          <ul className="space-y-3">
            {daftar.map((a) => (
              <li key={a.id} className="rounded-2xl border border-c4/60 bg-white p-5 shadow-kartu">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <Link href={`/admin/antrean/${a.id}`} className="text-base font-bold text-navy hover:underline">
                      {a.nama}
                    </Link>
                    <p className="text-sm text-ink">
                      {a.penyelenggara ?? "Penyelenggara belum terbaca"} | Sumber: {a.nama_sumber}
                    </p>
                    <p className="text-xs text-muted">Tenggat {tanggalIndo(a.tenggat)}</p>
                  </div>
                  <Link href={`/admin/antrean/${a.id}`} className="rounded-full bg-primary px-4 py-2 text-sm font-semibold text-white hover:bg-[#1b4d8f]">
                    Periksa
                  </Link>
                </div>
                {a.alasan_ditandai && (
                  <p className="mt-3 flex items-start gap-2 rounded-xl bg-danger-soft px-3 py-2 text-sm text-[#8c1212]">
                    <Flag className="mt-0.5 h-4 w-4 shrink-0" aria-hidden /> {a.alasan_ditandai}
                  </p>
                )}
              </li>
            ))}
          </ul>
        )}
      </Tampil>
    </div>
  );
}

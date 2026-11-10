"use client";
import { CircleCheck } from "lucide-react";
import Link from "next/link";
import { KosongState, Tampil } from "@/components/state";
import { JudulHalaman, Kartu, Metrik, TautanTombol } from "@/components/ui";
import { useAntrean, useLaporan } from "@/lib/hooks";
import { tanggalIndo } from "@/lib/format";

export default function AdminDashboard() {
  const laporan = useLaporan();
  const antrean = useAntrean();
  return (
    <div className="halaman-masuk space-y-8">
      <JudulHalaman judul="Dashboard Admin" deskripsi="Ringkasan data beasiswa, sumber pemantauan, dan antrean yang menunggu validasi." aksi={<TautanTombol href="/admin/antrean">Buka antrean validasi</TautanTombol>} />
      <Tampil
        kueri={laporan}
        memuat={
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {[0, 1, 2, 3].map((i) => (
              <Metrik key={i} label="Memuat" nilai="-" memuat />
            ))}
          </div>
        }
      >
        {(l) => (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <Metrik label="Menunggu validasi" nilai={l.beasiswa_per_status.menunggu_validasi ?? 0} />
            <Metrik label="Beasiswa terbit" nilai={l.beasiswa_per_status.terbit ?? 0} />
            <Metrik label="Sumber terpantau" nilai={l.jumlah_sumber} catatan={`${l.sumber_per_status.gagal ?? 0} gagal pada pemeriksaan terakhir`} />
            <Metrik label="Mahasiswa terdaftar" nilai={l.jumlah_mahasiswa} />
          </div>
        )}
      </Tampil>
      <Kartu>
        <h2 className="mb-4 text-lg font-bold text-navy">Antrean terbaru</h2>
        <Tampil kueri={antrean} baris={2} kosong={<KosongState ikon={CircleCheck} judul="Antrean kosong" pesan="Tidak ada beasiswa yang menunggu validasi. Pantau sumber untuk menemukan beasiswa baru." aksi={<TautanTombol href="/admin/sumber" varian="sekunder">Kelola sumber</TautanTombol>} />}>
          {(daftar) => (
            <ul className="divide-y divide-c4/60">
              {daftar.slice(0, 5).map((a) => (
                <li key={a.id} className="flex flex-wrap items-center justify-between gap-2 py-3 text-sm">
                  <Link href={`/admin/antrean/${a.id}`} className="inline-flex min-h-11 items-center font-semibold text-navy hover:underline">
                    {a.nama}
                  </Link>
                  <span className="text-muted">
                    {a.nama_sumber} | tenggat {tanggalIndo(a.tenggat)}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </Tampil>
      </Kartu>
    </div>
  );
}

"use client";
import { BantuanAdmin } from "@/components/BantuanAdmin";
import { Tampil } from "@/components/state";
import { BarProgres, JudulHalaman, Kartu, Metrik } from "@/components/ui";
import { useLaporan } from "@/lib/hooks";

const BEASISWA: Record<string, string> = { menunggu_validasi: "Menunggu validasi", terbit: "Terbit", kedaluwarsa: "Kedaluwarsa", ditolak: "Ditolak" };
const SUMBER: Record<string, string> = { berhasil: "Berhasil", gagal: "Gagal", belum_pernah: "Belum pernah diperiksa" };

function Sebaran({ judul, data, label }: { judul: string; data: Record<string, number>; label: Record<string, string> }) {
  const total = Object.values(data).reduce((a, b) => a + b, 0);
  return (
    <Kartu>
      <h2 className="mb-4 text-lg font-bold text-navy">{judul}</h2>
      <ul className="space-y-4">
        {Object.keys(label).map((k) => (
          <li key={k}>
            <div className="mb-1 flex justify-between text-sm">
              <span className="text-navy">{label[k]}</span>
              <span className="font-bold text-navy">{data[k] ?? 0}</span>
            </div>
            <BarProgres nilai={total ? ((data[k] ?? 0) / total) * 100 : 0} label={label[k]} />
          </li>
        ))}
      </ul>
    </Kartu>
  );
}

export default function Laporan() {
  const kueri = useLaporan();
  return (
    <div className="halaman-masuk">
      <JudulHalaman judul="Laporan Sistem" deskripsi="Kondisi data beasiswa dan keandalan sumber pemantauan." />
      <BantuanAdmin>
        <p>Halaman ini hanya membaca: tidak ada yang bisa diubah di sini. Pakai ringkasan kalimat di bawah untuk melihat apa yang perlu dikerjakan, lalu lanjut ke Antrean atau Kelola Sumber.</p>
      </BantuanAdmin>
      <Tampil kueri={kueri} adaIsi={() => true}>
        {(l) => (
          <div className="space-y-6">
            <p className="rounded-kartu border border-c4/60 bg-c1 p-4 text-sm text-ink">
              Saat ini {l.beasiswa_per_status.terbit ?? 0} beasiswa terbit dan tampil ke {l.jumlah_mahasiswa} mahasiswa. {l.beasiswa_per_status.menunggu_validasi ?? 0} menunggu validasi,{" "}
              {l.beasiswa_per_status.ditolak ?? 0} ditolak, dan {l.beasiswa_per_status.kedaluwarsa ?? 0} sudah kedaluwarsa. Dari {l.jumlah_sumber} sumber, {l.sumber_per_status.berhasil ?? 0} berhasil
              diperiksa, {l.sumber_per_status.gagal ?? 0} gagal, dan {l.sumber_per_status.belum_pernah ?? 0} belum pernah dipantau.
            </p>
            <div className="grid gap-4 sm:grid-cols-2">
              <Metrik label="Jumlah sumber" nilai={l.jumlah_sumber} />
              <Metrik label="Mahasiswa terdaftar" nilai={l.jumlah_mahasiswa} />
            </div>
            <div className="grid gap-6 lg:grid-cols-2">
              <Sebaran judul="Beasiswa per status" data={l.beasiswa_per_status} label={BEASISWA} />
              <Sebaran judul="Pemeriksaan sumber terakhir" data={l.sumber_per_status} label={SUMBER} />
            </div>
          </div>
        )}
      </Tampil>
    </div>
  );
}

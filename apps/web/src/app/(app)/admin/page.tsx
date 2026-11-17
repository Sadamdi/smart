"use client";
import { ArrowRight, CircleCheck, Database, ListChecks } from "lucide-react";
import Link from "next/link";
import { BantuanAdmin } from "@/components/BantuanAdmin";
import { KosongState, Tampil } from "@/components/state";
import { JudulHalaman, Kartu, Metrik, TautanTombol } from "@/components/ui";
import { useAntrean, useLaporan } from "@/lib/hooks";
import { tanggalIndo } from "@/lib/format";
import { daftarTindakan } from "@/lib/admin";

export default function AdminDashboard() {
  const laporan = useLaporan();
  const antrean = useAntrean();
  return (
    <div className="halaman-masuk space-y-8">
      <JudulHalaman judul="Dashboard Admin" deskripsi="Ringkasan data beasiswa, sumber pemantauan, dan pekerjaan yang menunggu Anda." aksi={<TautanTombol href="/admin/antrean">Buka antrean validasi</TautanTombol>} />
      <BantuanAdmin judul="Alur kerja admin" terbuka>
        <ol className="list-decimal space-y-1 pl-5">
          <li><b>Pantau sumber.</b> Di Kelola Sumber, tekan Pantau sekarang. Sistem membaca laman resmi dan menyimpan beasiswa yang ditemukan.</li>
          <li><b>Periksa antrean.</b> Beasiswa baru masuk ke Antrean Validasi. Buka, perbaiki data bila perlu, lalu Terbitkan atau Tolak. Validasi AI dapat membantu menerbitkan yang terbukti di laman resmi.</li>
          <li><b>Mahasiswa melihat hasilnya.</b> Hanya beasiswa berstatus terbit yang tampil di aplikasi.</li>
        </ol>
        <p>Laman yang menolak robot (kode 401, 403, atau dilarang robots.txt) otomatis ditolak dan tidak dicoba lagi. Tidak perlu diperiksa ulang.</p>
      </BantuanAdmin>
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
        {(l) => {
          const tindakan = daftarTindakan(l);
          return (
            <div className="space-y-6">
              <Kartu>
                <h2 className="mb-3 text-lg font-bold text-navy">Perlu tindakan</h2>
                {tindakan.length === 0 ? (
                  <p className="flex items-center gap-2 text-sm text-ink">
                    <CircleCheck className="h-5 w-5 text-ok" aria-hidden /> Tidak ada yang perlu dikerjakan. Antrean kosong dan semua sumber berhasil diperiksa.
                  </p>
                ) : (
                  <ul className="divide-y divide-c4/60">
                    {tindakan.map((t) => (
                      <li key={t.teks}>
                        <Link href={t.href} className="flex min-h-12 items-center justify-between gap-3 py-2 text-sm font-semibold text-navy hover:underline">
                          {t.teks}
                          <span className="inline-flex shrink-0 items-center gap-1 text-primary">
                            {t.aksi} <ArrowRight className="h-4 w-4" aria-hidden />
                          </span>
                        </Link>
                      </li>
                    ))}
                  </ul>
                )}
              </Kartu>
              <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <Link href="/admin/antrean" className="block rounded-kartu focus-visible:outline-2">
                  <Metrik label="Menunggu validasi" nilai={l.beasiswa_per_status.menunggu_validasi ?? 0} catatan="Buka antrean" nada={(l.beasiswa_per_status.menunggu_validasi ?? 0) > 0 ? "utama" : undefined} />
                </Link>
                <Metrik label="Beasiswa terbit" nilai={l.beasiswa_per_status.terbit ?? 0} catatan="Tampil ke mahasiswa" />
                <Link href="/admin/sumber" className="block rounded-kartu focus-visible:outline-2">
                  <Metrik label="Sumber terpantau" nilai={l.jumlah_sumber} catatan={`${l.sumber_per_status.gagal ?? 0} gagal pada pemeriksaan terakhir`} nada={(l.sumber_per_status.gagal ?? 0) > 0 ? "bahaya" : undefined} />
                </Link>
                <Metrik label="Mahasiswa terdaftar" nilai={l.jumlah_mahasiswa} />
              </div>
            </div>
          );
        }}
      </Tampil>
      <Kartu>
        <h2 className="mb-4 flex items-center gap-2 text-lg font-bold text-navy">
          <ListChecks className="h-5 w-5 text-primary" aria-hidden /> Antrean terbaru
        </h2>
        <Tampil kueri={antrean} baris={2} kosong={<KosongState ikon={Database} judul="Antrean kosong" pesan="Tidak ada beasiswa yang menunggu validasi. Pantau sumber untuk menemukan beasiswa baru." aksi={<TautanTombol href="/admin/sumber" varian="sekunder">Kelola sumber</TautanTombol>} />}>
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

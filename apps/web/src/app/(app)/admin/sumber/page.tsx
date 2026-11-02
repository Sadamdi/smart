"use client";
import Link from "next/link";
import { JENIS_SUMBER } from "@/components/FormSumber";
import { KosongState, Tampil } from "@/components/state";
import { JudulHalaman, TautanTombol, cx } from "@/components/ui";
import { useSumber } from "@/lib/hooks";

const STATUS: Record<string, string> = { berhasil: "Berhasil", gagal: "Gagal", belum_pernah: "Belum pernah diperiksa" };

export default function KelolaSumber() {
  const kueri = useSumber();
  return (
    <div>
      <JudulHalaman judul="Kelola Sumber" deskripsi="Laman resmi yang dipantau untuk menemukan beasiswa." aksi={<TautanTombol href="/admin/sumber/baru">Tambah sumber</TautanTombol>} />
      <Tampil kueri={kueri} kosong={<KosongState judul="Belum ada sumber" pesan="Tambahkan laman resmi beasiswa untuk dipantau." aksi={<TautanTombol href="/admin/sumber/baru">Tambah sumber</TautanTombol>} />}>
        {(daftar) => (
          <div className="overflow-x-auto rounded-2xl border border-c4/60 bg-white shadow-kartu">
            <table className="w-full min-w-[640px] text-left text-sm">
              <thead className="bg-c1 text-[11px] uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-4 py-3">Nama</th>
                  <th className="px-4 py-3">Jenis</th>
                  <th className="px-4 py-3">Pemeriksaan terakhir</th>
                  <th className="px-4 py-3">Aktif</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-c4/60">
                {daftar.map((s) => (
                  <tr key={s.id}>
                    <td className="px-4 py-3">
                      <p className="font-semibold text-navy">{s.nama}</p>
                      <p className="max-w-xs truncate text-xs text-muted">{s.url}</p>
                    </td>
                    <td className="px-4 py-3">{JENIS_SUMBER[s.jenis] ?? s.jenis}</td>
                    <td className="px-4 py-3">
                      <span className={cx("rounded-full px-2.5 py-0.5 text-xs font-semibold", s.status_terakhir === "gagal" ? "bg-danger-soft text-[#8c1212]" : s.status_terakhir === "berhasil" ? "bg-ok-soft text-ok" : "bg-c2 text-navy")}>
                        {STATUS[s.status_terakhir] ?? s.status_terakhir}
                      </span>
                    </td>
                    <td className="px-4 py-3">{s.aktif ? "Ya" : "Tidak"}</td>
                    <td className="px-4 py-3 text-right">
                      <Link href={`/admin/sumber/${s.id}`} className="font-semibold text-primary underline">
                        Ubah
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Tampil>
    </div>
  );
}

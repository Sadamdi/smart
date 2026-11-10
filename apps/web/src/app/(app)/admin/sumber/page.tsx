"use client";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useState } from "react";
import { JENIS_SUMBER } from "@/components/FormSumber";
import { Database } from "lucide-react";
import { KosongState, Tampil } from "@/components/state";
import { JudulHalaman, TautanTombol, cx } from "@/components/ui";
import { kirim } from "@/lib/api";
import { useSumber } from "@/lib/hooks";

const STATUS: Record<string, string> = { berhasil: "Berhasil", gagal: "Gagal", belum_pernah: "Belum pernah diperiksa" };

function TombolPantau({ id }: { id: string }) {
  const qc = useQueryClient();
  const [teks, setTeks] = useState<string | null>(null);
  const [sibuk, setSibuk] = useState(false);
  async function pantau() {
    setSibuk(true);
    setTeks(null);
    try {
      const r = await kirim<{ ditemukan: number; baru: number }>(`/admin/sumber/${id}/pantau`, "POST");
      setTeks(`${r.data.ditemukan} ditemukan, ${r.data.baru} baru`);
    } catch (e) {
      setTeks(e instanceof Error ? e.message : "Gagal");
    } finally {
      setSibuk(false);
      await qc.invalidateQueries({ queryKey: ["admin"] });
    }
  }
  return (
    <span className="mr-3 inline-flex flex-col items-end">
      <button type="button" onClick={pantau} disabled={sibuk} className="inline-flex min-h-11 items-center font-semibold text-primary underline disabled:opacity-60">
        {sibuk ? "Memantau" : "Pantau sekarang"}
      </button>
      {teks && <span className="text-xs text-muted">{teks}</span>}
    </span>
  );
}

export default function KelolaSumber() {
  const kueri = useSumber();
  return (
    <div className="halaman-masuk">
      <JudulHalaman judul="Kelola Sumber" deskripsi="Laman resmi yang dipantau untuk menemukan beasiswa." aksi={<TautanTombol href="/admin/sumber/baru">Tambah sumber</TautanTombol>} />
      <Tampil kueri={kueri} kosong={<KosongState ikon={Database} judul="Belum ada sumber" pesan="Tambahkan laman resmi beasiswa untuk dipantau." aksi={<TautanTombol href="/admin/sumber/baru">Tambah sumber</TautanTombol>} />}>
        {(daftar) => (
          <div className="overflow-x-auto rounded-kartu border border-c4/60 bg-card shadow-kartu">
            <table className="w-full min-w-[640px] text-left text-sm">
              <thead className="bg-c1 text-[11px] uppercase tracking-wide text-muted">
                <tr>
                  <th scope="col" className="px-4 py-3">Nama</th>
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
                      <span className={cx("rounded-full px-2.5 py-0.5 text-xs font-bold", s.status_terakhir === "gagal" ? "bg-danger-soft text-danger-ink" : s.status_terakhir === "berhasil" ? "bg-ok-soft text-ok" : "bg-c2 text-navy")}>
                        {STATUS[s.status_terakhir] ?? s.status_terakhir}
                      </span>
                    </td>
                    <td className="px-4 py-3">{s.aktif ? "Ya" : "Tidak"}</td>
                    <td className="px-4 py-3 text-right">
                      {s.jenis === "pantau_otomatis" && <TombolPantau id={s.id} />}
                      <Link href={`/admin/sumber/${s.id}`} className="inline-flex min-h-11 items-center font-semibold text-primary underline">
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

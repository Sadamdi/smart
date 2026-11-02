"use client";
import { Flag } from "lucide-react";
import Link from "next/link";
import { KosongState, Tampil } from "@/components/state";
import { JudulHalaman } from "@/components/ui";
import { useAntrean } from "@/lib/hooks";
import { tanggalIndo } from "@/lib/format";

export default function Antrean() {
  const kueri = useAntrean();
  return (
    <div>
      <JudulHalaman judul="Antrean Validasi" deskripsi="Beasiswa hasil pemantauan yang perlu diperiksa sebelum terbit." />
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

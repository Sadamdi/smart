import { BellRing, ShieldCheck, Sparkles } from "lucide-react";
import type { ReactNode } from "react";

const MANFAAT = [
  { ikon: Sparkles, judul: "Rekomendasi sesuai profil", teks: "Mesin Rekomendasi menilai syarat satu per satu dan menjelaskan alasannya." },
  { ikon: BellRing, judul: "Pengingat tenggat", teks: "Beasiswa tersimpan, checklist berkas, dan kalender tenggat dalam satu tempat." },
  { ikon: ShieldCheck, judul: "Sumber resmi", teks: "Setiap beasiswa menautkan ke laman resmi penyelenggara dan waktu pemeriksaannya." },
];

export function PanelAuth({ judul, deskripsi, children }: { judul: string; deskripsi: string; children: ReactNode }) {
  return (
    <div className="grid min-h-screen lg:grid-cols-2">
      <aside className="hidden flex-col justify-between bg-primary p-12 text-white lg:flex">
        <div className="flex items-center gap-3">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo.svg" alt="" width={44} height={44} className="h-11 w-11" />
          <span className="text-xl font-bold">SMART</span>
        </div>
        <div>
          <h2 className="max-w-md text-[32px] font-bold leading-tight">Temukan beasiswa yang layak diperjuangkan.</h2>
          <ul className="mt-10 space-y-6">
            {MANFAAT.map((m) => (
              <li key={m.judul} className="flex gap-4">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/15">
                  <m.ikon className="h-5 w-5" aria-hidden />
                </span>
                <span>
                  <span className="block font-semibold">{m.judul}</span>
                  <span className="block max-w-sm text-sm text-white/90">{m.teks}</span>
                </span>
              </li>
            ))}
          </ul>
        </div>
        <p className="text-sm text-white/85">Sistem tidak pernah menyatakan pasti diterima atau ditolak. Keputusan akhir ada pada penyelenggara.</p>
      </aside>
      <main className="flex items-center justify-center px-6 py-12">
        <div className="w-full max-w-md">
          <div className="mb-8 flex items-center gap-3 lg:hidden">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/logo.svg" alt="" width={40} height={40} className="h-10 w-10" />
            <span className="text-lg font-bold text-navy">SMART</span>
          </div>
          <h1 className="text-[28px] font-bold text-navy">{judul}</h1>
          <p className="mb-8 mt-1 text-sm text-ink">{deskripsi}</p>
          {children}
        </div>
      </main>
    </div>
  );
}

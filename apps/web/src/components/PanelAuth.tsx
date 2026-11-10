import { BellRing, ShieldCheck, Sparkles } from "lucide-react";
import type { ReactNode } from "react";

const MANFAAT = [
  { ikon: Sparkles, judul: "Rekomendasi sesuai profil", teks: "Mesin Rekomendasi menilai syarat satu per satu dan menjelaskan alasannya." },
  { ikon: BellRing, judul: "Pengingat tenggat", teks: "Beasiswa tersimpan, checklist berkas, dan kalender tenggat dalam satu tempat." },
  { ikon: ShieldCheck, judul: "Sumber resmi", teks: "Setiap beasiswa menautkan ke laman resmi penyelenggara dan waktu pemeriksaannya." },
];

export function PanelAuth({ judul, deskripsi, children }: { judul: string; deskripsi: string; children: ReactNode }) {
  return (
    <div className="grid min-h-screen bg-surface lg:grid-cols-2">
      <aside className="relative hidden flex-col justify-between overflow-hidden bg-gradient-to-br from-[var(--hero-a)] to-[var(--hero-b)] p-12 text-white lg:flex">
        <span aria-hidden className="pointer-events-none absolute -right-24 -top-24 h-72 w-72 rounded-full bg-gold/15" />
        <span aria-hidden className="pointer-events-none absolute -bottom-32 -left-16 h-80 w-80 rounded-full bg-white/5" />
        <div className="relative flex items-center gap-3">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo.svg" alt="" width={44} height={44} className="h-11 w-11" />
          <span className="text-xl font-extrabold">SMART</span>
        </div>
        <div className="relative">
          <h2 className="max-w-md text-[32px] font-bold leading-tight">Temukan beasiswa yang layak diperjuangkan.</h2>
          <ul className="mt-10 space-y-6">
            {MANFAAT.map((m) => (
              <li key={m.judul} className="flex gap-4">
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[14px] bg-white/15 text-gold">
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
        <p className="relative text-sm text-white/90">Sistem tidak pernah menyatakan pasti diterima atau ditolak. Keputusan akhir ada pada penyelenggara.</p>
      </aside>
      <main className="flex items-center justify-center px-4 py-10 sm:px-6 sm:py-12">
        <div className="halaman-masuk w-full max-w-md rounded-[24px] border border-c4/60 bg-card p-6 shadow-kartu sm:p-8">
          <div className="mb-8 flex items-center gap-3 lg:hidden">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/logo.svg" alt="" width={40} height={40} className="h-10 w-10" />
            <span className="text-lg font-extrabold text-navy">SMART</span>
          </div>
          <h1 className="text-2xl font-bold text-navy sm:text-[28px]">{judul}</h1>
          <p className="mb-6 mt-1 text-sm text-ink">{deskripsi}</p>
          {children}
        </div>
      </main>
    </div>
  );
}

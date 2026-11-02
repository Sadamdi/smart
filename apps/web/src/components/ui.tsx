"use client";
import Link from "next/link";
import type { ButtonHTMLAttributes, InputHTMLAttributes, ReactNode, SelectHTMLAttributes } from "react";
import { LABEL_KATEGORI } from "@/lib/format";

export const cx = (...k: (string | false | null | undefined)[]) => k.filter(Boolean).join(" ");

type Varian = "utama" | "sekunder" | "hantu" | "bahaya";
const VARIAN: Record<Varian, string> = {
  utama: "bg-primary text-white hover:bg-[#1b4d8f] disabled:bg-outline disabled:text-muted",
  sekunder: "bg-c2 text-primary hover:bg-c3 disabled:opacity-60",
  hantu: "bg-transparent text-primary hover:bg-c2 disabled:opacity-60",
  bahaya: "bg-danger text-white hover:bg-[#93000a] disabled:opacity-60",
};
const DASAR =
  "inline-flex items-center justify-center gap-2 rounded-full px-5 py-2.5 text-sm font-semibold transition-colors disabled:cursor-not-allowed";

export function Tombol({
  varian = "utama",
  className,
  ...p
}: ButtonHTMLAttributes<HTMLButtonElement> & { varian?: Varian }) {
  return <button type="button" {...p} className={cx(DASAR, VARIAN[varian], className)} />;
}

export function TautanTombol({
  varian = "utama",
  className,
  href,
  children,
  luar,
}: {
  varian?: Varian;
  className?: string;
  href: string;
  children: ReactNode;
  luar?: boolean;
}) {
  const kelas = cx(DASAR, VARIAN[varian], className);
  return luar ? (
    <a href={href} target="_blank" rel="noopener noreferrer" className={kelas}>
      {children}
    </a>
  ) : (
    <Link href={href} className={kelas}>
      {children}
    </Link>
  );
}

export function Medan({ label, galat, children }: { label: string; galat?: string; children: ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[11px] font-semibold uppercase tracking-wide text-muted">{label}</span>
      {children}
      {galat && (
        <span role="alert" className="mt-1 block text-xs text-danger">
          {galat}
        </span>
      )}
    </label>
  );
}

const KONTROL =
  "w-full rounded-lg border border-outline bg-white px-3.5 py-2.5 text-sm text-navy placeholder:text-muted focus:border-primary disabled:bg-c1";

export function Masukan({ className, ...p }: InputHTMLAttributes<HTMLInputElement>) {
  return <input {...p} className={cx(KONTROL, className)} />;
}

export function Pilihan({ className, children, ...p }: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select {...p} className={cx(KONTROL, className)}>
      {children}
    </select>
  );
}

export function Kartu({ className, children }: { className?: string; children: ReactNode }) {
  return <section className={cx("rounded-2xl border border-c4/60 bg-white p-6 shadow-kartu", className)}>{children}</section>;
}

export function JudulHalaman({ judul, deskripsi, aksi }: { judul: string; deskripsi?: string; aksi?: ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 className="text-[28px] font-bold leading-tight text-navy">{judul}</h1>
        {deskripsi && <p className="mt-1 max-w-2xl text-sm text-ink">{deskripsi}</p>}
      </div>
      {aksi}
    </div>
  );
}

export function ChipFilter({ aktif, onClick, children }: { aktif?: boolean; onClick?: () => void; children: ReactNode }) {
  return (
    <button
      type="button"
      aria-pressed={aktif}
      onClick={onClick}
      className={cx(
        "rounded-full px-4 py-1.5 text-sm font-medium transition-colors",
        aktif ? "bg-primary text-white" : "bg-c2 text-navy hover:bg-c3",
      )}
    >
      {children}
    </button>
  );
}

const WARNA_KATEGORI: Record<string, string> = {
  memenuhi: "bg-ok-soft text-ok",
  hampir_memenuhi: "bg-c4 text-[#12407a]",
  belum_memenuhi: "bg-danger-soft text-[#8c1212]",
};

export function ChipStatus({ kategori, teks }: { kategori: string; teks?: string }) {
  return (
    <span className={cx("inline-block rounded-full px-3 py-1 text-xs font-semibold", WARNA_KATEGORI[kategori] ?? "bg-c2 text-navy")}>
      {teks ?? LABEL_KATEGORI[kategori] ?? kategori}
    </span>
  );
}

export function Metrik({ label, nilai, catatan }: { label: string; nilai: ReactNode; catatan?: ReactNode }) {
  return (
    <div className="rounded-2xl border border-c4/60 bg-white p-5 shadow-kartu">
      <p className="text-[11px] font-semibold uppercase tracking-wide text-muted">{label}</p>
      <p className="mt-2 text-2xl font-bold text-navy">{nilai}</p>
      {catatan && <p className="mt-1 text-xs text-muted">{catatan}</p>}
    </div>
  );
}

export function BarProgres({ nilai, label }: { nilai: number; label?: string }) {
  const n = Math.max(0, Math.min(100, Math.round(nilai)));
  return (
    <div
      role="progressbar"
      aria-valuenow={n}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-label={label ?? "Kemajuan"}
      className="h-2 w-full overflow-hidden rounded-full bg-c4"
    >
      <div className="h-full rounded-full bg-primary" style={{ width: `${n}%` }} />
    </div>
  );
}

/** Donat jumlah per kategori. Tidak menampilkan persen. */
export function Donat({ bagian }: { bagian: { label: string; nilai: number; warna: string }[] }) {
  const total = bagian.reduce((a, b) => a + b.nilai, 0);
  const r = 40;
  const k = 2 * Math.PI * r;
  let geser = 0;
  return (
    <div className="flex items-center gap-6">
      <svg viewBox="0 0 100 100" className="h-32 w-32 shrink-0 -rotate-90" role="img" aria-label={`Total ${total} beasiswa`}>
        <circle cx="50" cy="50" r={r} fill="none" stroke="var(--c4)" strokeWidth="12" />
        {total > 0 &&
          bagian.map((b) => {
            const panjang = (b.nilai / total) * k;
            const el = (
              <circle
                key={b.label}
                cx="50"
                cy="50"
                r={r}
                fill="none"
                stroke={b.warna}
                strokeWidth="12"
                strokeDasharray={`${panjang} ${k - panjang}`}
                strokeDashoffset={-geser}
              />
            );
            geser += panjang;
            return el;
          })}
      </svg>
      <ul className="space-y-2 text-sm">
        {bagian.map((b) => (
          <li key={b.label} className="flex items-center gap-2">
            <span className="h-3 w-3 rounded-full" style={{ background: b.warna }} aria-hidden />
            <span className="text-ink">{b.label}</span>
            <span className="font-bold text-navy">{b.nilai}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

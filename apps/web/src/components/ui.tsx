"use client";
import Link from "next/link";
import { Eye, EyeOff } from "lucide-react";
import { useState, type ButtonHTMLAttributes, type ComponentProps, type ReactNode, type SelectHTMLAttributes } from "react";
import { LABEL_KATEGORI } from "@/lib/format";

export const cx = (...k: (string | false | null | undefined)[]) => k.filter(Boolean).join(" ");

type Varian = "utama" | "sekunder" | "hantu" | "bahaya";
const VARIAN: Record<Varian, string> = {
  utama: "bg-fill text-white shadow-sm hover:bg-fill-hover disabled:bg-c3 disabled:text-muted disabled:shadow-none",
  sekunder: "bg-c2 text-primary hover:bg-c3 disabled:opacity-60",
  hantu: "bg-transparent text-primary hover:bg-c2 disabled:opacity-60",
  bahaya: "bg-danger-fill text-white hover:bg-danger-fill-hover disabled:opacity-60",
};
const DASAR =
  "inline-flex min-h-11 items-center justify-center gap-2 rounded-kontrol px-5 py-2.5 text-sm font-semibold transition-colors duration-150 active:scale-[0.99] disabled:cursor-not-allowed";

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

export function Medan({
  label,
  galat,
  wajib,
  bantuan,
  children,
}: {
  label: string;
  galat?: string;
  /** true: wajib untuk rekomendasi; false: opsional; tanpa nilai: tanpa penanda. */
  wajib?: boolean;
  bantuan?: string;
  children: ReactNode;
}) {
  return (
    <label className="block">
      <span className="mb-1.5 flex flex-wrap items-center gap-2 text-[11px] font-bold uppercase tracking-wide text-muted">
        {label}
        {wajib === true && (
          <span className="rounded-full bg-c3 px-2 py-0.5 text-[10px] normal-case tracking-normal text-primary">Wajib untuk rekomendasi</span>
        )}
        {wajib === false && <span className="text-[10px] font-medium normal-case tracking-normal">opsional</span>}
      </span>
      {children}
      {bantuan && !galat && <span className="mt-1 block text-xs text-muted">{bantuan}</span>}
      {galat && (
        <span role="alert" className="mt-1 block text-xs text-danger">
          {galat}
        </span>
      )}
    </label>
  );
}

const KONTROL =
  "min-h-11 w-full rounded-kontrol border border-line bg-card px-3.5 py-2.5 text-[15px] text-navy transition-colors duration-150 placeholder:text-muted focus:border-primary disabled:bg-c1 disabled:text-muted";

export function Masukan({ className, ...p }: ComponentProps<"input">) {
  return <input {...p} className={cx(KONTROL, className)} />;
}

/** Kolom kata sandi dengan tombol lihat. */
export function MasukanSandi({ className, ...p }: Omit<ComponentProps<"input">, "type">) {
  const [lihat, setLihat] = useState(false);
  return (
    <span className="relative block">
      <Masukan {...p} type={lihat ? "text" : "password"} className={cx("pr-12", className)} />
      <button
        type="button"
        aria-pressed={lihat}
        aria-label={lihat ? "Sembunyikan karakter" : "Tampilkan karakter"}
        onClick={() => setLihat((v) => !v)}
        className="absolute right-0.5 top-1/2 flex h-11 w-11 -translate-y-1/2 items-center justify-center rounded-full text-muted transition-colors hover:text-navy"
      >
        {lihat ? <EyeOff className="h-5 w-5" aria-hidden /> : <Eye className="h-5 w-5" aria-hidden />}
      </button>
    </span>
  );
}

export function Pilihan({ className, children, ...p }: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select {...p} className={cx(KONTROL, className)}>
      {children}
    </select>
  );
}

export function Kartu({ className, children }: { className?: string; children: ReactNode }) {
  return <section className={cx("rounded-kartu border border-c4/60 bg-card p-5 shadow-kartu sm:p-6", className)}>{children}</section>;
}

export function JudulHalaman({ judul, deskripsi, aksi }: { judul: string; deskripsi?: string; aksi?: ReactNode }) {
  return (
    <div className="halaman-masuk mb-6 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 className="text-2xl font-bold leading-tight text-navy sm:text-[28px]">{judul}</h1>
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
        "inline-flex min-h-11 items-center rounded-full border px-4 py-1.5 text-sm font-semibold transition-colors duration-150",
        aktif ? "border-fill bg-fill text-white" : "border-c4 bg-card text-navy hover:bg-c2",
      )}
    >
      {children}
    </button>
  );
}

const WARNA_KATEGORI: Record<string, string> = {
  memenuhi: "bg-ok-soft text-ok",
  hampir_memenuhi: "bg-info-soft text-info-ink",
  belum_memenuhi: "bg-danger-soft text-danger-ink",
};

export function ChipStatus({ kategori, teks }: { kategori: string; teks?: string }) {
  return (
    <span className={cx("inline-block rounded-full px-3 py-1 text-xs font-bold", WARNA_KATEGORI[kategori] ?? "bg-c2 text-navy")}>
      {teks ?? LABEL_KATEGORI[kategori] ?? kategori}
    </span>
  );
}

export function Metrik({ label, nilai, catatan, memuat, nada }: { label: string; nilai: ReactNode; catatan?: ReactNode; memuat?: boolean; nada?: "utama" | "bahaya" }) {
  return (
    <div className="rounded-kartu border border-c4/60 bg-card p-5 shadow-kartu">
      <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{label}</p>
      {memuat ? (
        <>
          <span className="sr-only" role="status">Memuat</span>
          <div aria-hidden className="skeleton mt-2 h-8 w-16" />
          <div aria-hidden className="skeleton mt-2 h-3 w-24" />
        </>
      ) : (
        <>
          <p className={cx("mt-2 text-2xl font-extrabold", nada === "utama" ? "text-primary" : nada === "bahaya" ? "text-danger" : "text-navy")}>{nilai}</p>
          {catatan && <p className="mt-1 text-xs text-muted">{catatan}</p>}
        </>
      )}
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
      className="h-2 w-full overflow-hidden rounded-full bg-c3"
    >
      <div className="h-full rounded-full bg-fill transition-[width] duration-300" style={{ width: `${n}%` }} />
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
    <div className="flex flex-wrap items-center gap-x-5 gap-y-3">
      <svg viewBox="0 0 100 100" className="h-28 w-28 shrink-0 -rotate-90" role="img" aria-label={`Total ${total} beasiswa`}>
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

/** Penanda kecil bergaya chip untuk metadata (jenjang, negara, dan sejenisnya). */
export function Lencana({ children, nada = "netral", className }: { children: ReactNode; nada?: "netral" | "info" | "ok" | "waspada" | "bahaya" | "emas"; className?: string }) {
  const WARNA = {
    netral: "bg-c2 text-navy",
    info: "bg-info-soft text-info-ink",
    ok: "bg-ok-soft text-ok",
    waspada: "bg-warn-soft text-warn",
    bahaya: "bg-danger-soft text-danger-ink",
    emas: "bg-gold/20 text-navy",
  } as const;
  return <span className={cx("inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-bold", WARNA[nada], className)}>{children}</span>;
}

/** Latar ikon bulat bersudut untuk kepala kartu dan keadaan kosong. */
export function KotakIkon({ children, className }: { children: ReactNode; className?: string }) {
  return <span className={cx("flex h-11 w-11 shrink-0 items-center justify-center rounded-[14px] bg-c2 text-primary", className)}>{children}</span>;
}

/** Judul bagian di dalam halaman (20/700). */
export function JudulBagian({ children, aksi }: { children: ReactNode; aksi?: ReactNode }) {
  return (
    <div className="mb-3 flex items-center justify-between gap-3">
      <h2 className="text-lg font-bold text-navy sm:text-xl">{children}</h2>
      {aksi}
    </div>
  );
}

"use client";
import type { UseQueryResult } from "@tanstack/react-query";
import { CloudOff, Inbox, RefreshCw, Sparkles, type LucideIcon } from "lucide-react";
import type { ReactNode } from "react";
import { ApiError } from "@/lib/api";
import { Tombol } from "./ui";

/** Skeleton berbentuk kartu: status dibacakan sekali, bentuknya menahan tata letak agar tidak melompat. */
export function MemuatState({ baris = 3 }: { baris?: number }) {
  return (
    <div role="status" aria-live="polite" aria-busy="true" className="space-y-3">
      <span className="sr-only">Memuat</span>
      {Array.from({ length: baris }, (_, i) => (
        <div key={i} aria-hidden className="rounded-kartu border border-c4/60 bg-card p-5">
          <div className="flex items-center gap-3">
            <div className="skeleton h-11 w-11 shrink-0 !rounded-[14px]" />
            <div className="flex-1 space-y-2">
              <div className="skeleton h-4 w-2/3" />
              <div className="skeleton h-3 w-1/3" />
            </div>
          </div>
          <div className="skeleton mt-4 h-3 w-full" />
          <div className="skeleton mt-2 h-3 w-4/5" />
        </div>
      ))}
    </div>
  );
}

/** Skeleton kisi untuk daftar kartu (Jelajah, Tersimpan, Rekomendasi). */
export function MemuatKisi({ jumlah = 6 }: { jumlah?: number }) {
  return (
    <div role="status" aria-live="polite" aria-busy="true" className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
      <span className="sr-only">Memuat</span>
      {Array.from({ length: jumlah }, (_, i) => (
        <div key={i} aria-hidden className="rounded-kartu border border-c4/60 bg-card p-5">
          <div className="skeleton h-5 w-4/5" />
          <div className="skeleton mt-3 h-3 w-1/2" />
          <div className="mt-4 flex gap-2">
            <div className="skeleton h-5 w-10 !rounded-full" />
            <div className="skeleton h-5 w-14 !rounded-full" />
          </div>
          <div className="skeleton mt-4 h-9 w-full" />
        </div>
      ))}
    </div>
  );
}

export function KosongState({ judul, pesan, aksi, ikon: Ikon = Inbox }: { judul: string; pesan?: string; aksi?: ReactNode; ikon?: LucideIcon }) {
  return (
    <div className="flex flex-col items-center rounded-kartu border border-dashed border-line/60 bg-card px-6 py-12 text-center">
      <span className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-c2 text-primary">
        <Ikon className="h-7 w-7" aria-hidden />
      </span>
      <p className="text-base font-bold text-navy">{judul}</p>
      {pesan && <p className="mt-1 max-w-md text-sm text-ink">{pesan}</p>}
      {aksi && <div className="mt-5">{aksi}</div>}
    </div>
  );
}

export function pesanGalat(e: unknown): { judul: string; pesan: string; ai: boolean; jaringan: boolean } {
  if (e instanceof ApiError) {
    if (e.code === "UPSTREAM_UNAVAILABLE" || e.status === 503)
      return { judul: "Layanan AI sedang tidak tersedia", pesan: e.message, ai: true, jaringan: false };
    if (e.code === "NETWORK") return { judul: "Tidak terhubung ke server", pesan: e.message, ai: false, jaringan: true };
    return { judul: "Terjadi kesalahan", pesan: e.message, ai: false, jaringan: false };
  }
  return { judul: "Terjadi kesalahan", pesan: "Coba lagi beberapa saat.", ai: false, jaringan: false };
}

export function GalatState({ galat, onCoba }: { galat: unknown; onCoba?: () => void }) {
  const g = pesanGalat(galat);
  const Ikon = g.ai ? Sparkles : CloudOff;
  return (
    <div role="alert" className="flex flex-col items-center rounded-kartu border border-danger/40 bg-card px-6 py-10 text-center">
      <span className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-danger-soft text-danger">
        <Ikon className="h-7 w-7" aria-hidden />
      </span>
      <p className="text-base font-bold text-navy">{g.judul}</p>
      <p className="mt-1 max-w-md text-sm text-ink">{g.pesan}</p>
      {g.ai && <p className="mt-1 max-w-md text-sm text-ink">Fitur lain tetap dapat dipakai, dan profil dapat diisi secara manual.</p>}
      {onCoba && (
        <Tombol varian="sekunder" className="mt-4" onClick={onCoba}>
          <RefreshCw className="h-4 w-4" aria-hidden /> Coba lagi
        </Tombol>
      )}
    </div>
  );
}

/** Membungkus hasil kueri: memuat, galat dengan coba lagi, kosong, lalu isi. */
export function Tampil<T>({
  kueri,
  kosong,
  adaIsi,
  baris,
  memuat,
  children,
}: {
  kueri: Pick<UseQueryResult<T>, "data" | "isPending" | "isError" | "error" | "refetch">;
  kosong?: ReactNode;
  adaIsi?: (d: T) => boolean;
  baris?: number;
  /** Pengganti skeleton bawaan, mis. kisi kartu. */
  memuat?: ReactNode;
  children: (d: T) => ReactNode;
}) {
  if (kueri.isPending) return <>{memuat ?? <MemuatState baris={baris} />}</>;
  if (kueri.isError) return <GalatState galat={kueri.error} onCoba={() => kueri.refetch()} />;
  const d = kueri.data as T;
  const kosongkah = adaIsi ? !adaIsi(d) : Array.isArray(d) && d.length === 0;
  if (kosongkah && kosong) return <>{kosong}</>;
  return <>{children(d)}</>;
}

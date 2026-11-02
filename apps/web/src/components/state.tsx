"use client";
import type { UseQueryResult } from "@tanstack/react-query";
import { CloudOff, Inbox, Loader2, Sparkles } from "lucide-react";
import type { ReactNode } from "react";
import { ApiError } from "@/lib/api";
import { Tombol } from "./ui";

export function MemuatState({ baris = 3 }: { baris?: number }) {
  return (
    <div role="status" aria-live="polite" className="space-y-3">
      <span className="sr-only">Memuat</span>
      {Array.from({ length: baris }, (_, i) => (
        <div key={i} className="h-20 animate-pulse rounded-2xl bg-c2" />
      ))}
    </div>
  );
}

export function KosongState({ judul, pesan, aksi }: { judul: string; pesan?: string; aksi?: ReactNode }) {
  return (
    <div className="flex flex-col items-center rounded-2xl border border-dashed border-outline bg-white px-6 py-12 text-center">
      <Inbox className="mb-3 h-8 w-8 text-muted" aria-hidden />
      <p className="text-base font-semibold text-navy">{judul}</p>
      {pesan && <p className="mt-1 max-w-md text-sm text-ink">{pesan}</p>}
      {aksi && <div className="mt-4">{aksi}</div>}
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
    <div role="alert" className="flex flex-col items-center rounded-2xl border border-danger-soft bg-white px-6 py-10 text-center">
      <Ikon className="mb-3 h-8 w-8 text-danger" aria-hidden />
      <p className="text-base font-semibold text-navy">{g.judul}</p>
      <p className="mt-1 max-w-md text-sm text-ink">{g.pesan}</p>
      {g.ai && <p className="mt-1 max-w-md text-sm text-ink">Fitur lain tetap dapat dipakai, dan profil dapat diisi secara manual.</p>}
      {onCoba && (
        <Tombol varian="sekunder" className="mt-4" onClick={onCoba}>
          <Loader2 className="h-4 w-4" aria-hidden /> Coba lagi
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
  children,
}: {
  kueri: Pick<UseQueryResult<T>, "data" | "isPending" | "isError" | "error" | "refetch">;
  kosong?: ReactNode;
  adaIsi?: (d: T) => boolean;
  baris?: number;
  children: (d: T) => ReactNode;
}) {
  if (kueri.isPending) return <MemuatState baris={baris} />;
  if (kueri.isError) return <GalatState galat={kueri.error} onCoba={() => kueri.refetch()} />;
  const d = kueri.data as T;
  const kosongkah = adaIsi ? !adaIsi(d) : Array.isArray(d) && d.length === 0;
  if (kosongkah && kosong) return <>{kosong}</>;
  return <>{children(d)}</>;
}

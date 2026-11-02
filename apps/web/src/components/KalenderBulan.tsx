"use client";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { NAMA_BULAN } from "@/lib/format";
import type { Acara } from "@/lib/types";
import { cx } from "./ui";

const HARI = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
const dua = (n: number) => String(n).padStart(2, "0");
export const isoTanggal = (t: number, b: number, h: number) => `${t}-${dua(b + 1)}-${dua(h)}`;

export function KalenderBulan({
  tahun,
  bulan,
  acara,
  dipilih,
  onPilih,
  onGeser,
}: {
  tahun: number;
  bulan: number; // 0-11
  acara: Acara[];
  dipilih?: string | null;
  onPilih: (iso: string) => void;
  onGeser: (selisih: number) => void;
}) {
  const jumlahHari = new Date(tahun, bulan + 1, 0).getDate();
  const awal = (new Date(tahun, bulan, 1).getDay() + 6) % 7; // Senin = 0
  const sel: (number | null)[] = [...Array(awal).fill(null), ...Array.from({ length: jumlahHari }, (_, i) => i + 1)];
  while (sel.length % 7) sel.push(null);
  const per = new Map<string, Acara[]>();
  for (const a of acara) per.set(a.tanggal.slice(0, 10), [...(per.get(a.tanggal.slice(0, 10)) ?? []), a]);
  const hariIni = new Date();
  const iniIso = isoTanggal(hariIni.getFullYear(), hariIni.getMonth(), hariIni.getDate());

  return (
    <div>
      <div className="mb-4 flex items-center justify-between">
        <h3 className="text-base font-bold text-navy" aria-live="polite">
          {NAMA_BULAN[bulan]} {tahun}
        </h3>
        <div className="flex gap-1">
          <button type="button" aria-label="Bulan sebelumnya" onClick={() => onGeser(-1)} className="rounded-full p-2 text-navy hover:bg-c2">
            <ChevronLeft className="h-4 w-4" />
          </button>
          <button type="button" aria-label="Bulan berikutnya" onClick={() => onGeser(1)} className="rounded-full p-2 text-navy hover:bg-c2">
            <ChevronRight className="h-4 w-4" />
          </button>
        </div>
      </div>
      <div className="grid grid-cols-7 gap-1 text-center text-[11px] font-semibold uppercase text-muted">
        {HARI.map((h) => (
          <div key={h} className="py-1">
            {h}
          </div>
        ))}
      </div>
      <div className="mt-1 grid grid-cols-7 gap-1">
        {sel.map((h, i) => {
          if (!h) return <div key={i} />;
          const iso = isoTanggal(tahun, bulan, h);
          const ada = per.get(iso) ?? [];
          const tenggat = ada.some((a) => a.jenis === "tenggat");
          return (
            <button
              key={i}
              type="button"
              onClick={() => onPilih(iso)}
              aria-label={`${h} ${NAMA_BULAN[bulan]}${ada.length ? `, ${ada.length} acara` : ""}`}
              aria-pressed={dipilih === iso}
              className={cx(
                "relative flex aspect-square flex-col items-center justify-center rounded-xl text-sm font-medium",
                dipilih === iso ? "bg-primary text-white" : iso === iniIso ? "bg-c3 text-navy" : "text-navy hover:bg-c1",
              )}
            >
              {h}
              {ada.length > 0 && (
                <span
                  aria-hidden
                  className={cx("absolute bottom-1.5 h-1.5 w-1.5 rounded-full", dipilih === iso ? "bg-white" : tenggat ? "bg-danger" : "bg-primary-soft")}
                />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

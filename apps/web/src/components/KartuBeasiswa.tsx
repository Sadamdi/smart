import { Building2, CalendarDays, GraduationCap, Globe } from "lucide-react";
import Link from "next/link";
import type { ReactNode } from "react";
import { labelSisa, sisaHari, tanggalIndo } from "@/lib/format";
import type { BeasiswaRingkas } from "@/lib/types";
import { cx, KotakIkon, Lencana } from "./ui";

export function KartuBeasiswa({
  beasiswa,
  kepala,
  children,
}: {
  beasiswa: BeasiswaRingkas;
  kepala?: ReactNode;
  children?: ReactNode;
}) {
  const sisa = sisaHari(beasiswa.tenggat);
  const dekat = sisa !== null && sisa >= 0 && sisa <= 7;
  return (
    <article className="relative flex h-full flex-col rounded-kartu border border-c4/60 bg-card p-5 shadow-kartu transition-[border-color,box-shadow] duration-200 hover:border-primary-soft/70">
      {kepala && <div className="relative mb-3">{kepala}</div>}
      <div className="flex items-start gap-3">
        <KotakIkon>
          <GraduationCap className="h-5 w-5" aria-hidden />
        </KotakIkon>
        <div className="min-w-0">
          <h3 className="text-base font-bold leading-snug text-navy">
            <Link href={`/beasiswa/${beasiswa.id}`} className="after:absolute after:inset-0 hover:text-primary hover:underline">
              {beasiswa.nama}
            </Link>
          </h3>
          {beasiswa.penyelenggara && <p className="mt-0.5 flex items-center gap-1.5 text-xs text-muted"><Building2 className="h-3.5 w-3.5 shrink-0" aria-hidden />{beasiswa.penyelenggara}</p>}
        </div>
      </div>
      <div className="mt-3 flex flex-wrap gap-1.5">
        {beasiswa.jenjang?.map((j) => (
          <Lencana key={j}>{j}</Lencana>
        ))}
        {beasiswa.negara && (
          <Lencana nada="info">
            <Globe className="h-3 w-3" aria-hidden />
            {beasiswa.negara}
          </Lencana>
        )}
      </div>
      <div
        className={cx(
          "mt-4 flex items-center gap-2 rounded-[14px] px-3 py-2 text-xs font-semibold",
          dekat ? "bg-danger-soft text-danger-ink" : "bg-c1 text-navy",
        )}
      >
        <CalendarDays className="h-4 w-4 shrink-0" aria-hidden />
        <span>Tenggat {beasiswa.tenggat ? tanggalIndo(beasiswa.tenggat) : "belum diumumkan"}</span>
        <span className="ml-auto shrink-0">{labelSisa(beasiswa.tenggat)}</span>
      </div>
      {children && <div className="relative mt-4 flex-1">{children}</div>}
    </article>
  );
}

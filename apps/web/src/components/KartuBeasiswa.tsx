import { CalendarDays, Globe, Building2 } from "lucide-react";
import Link from "next/link";
import type { ReactNode } from "react";
import { labelSisa, sisaHari, tanggalIndo } from "@/lib/format";
import type { BeasiswaRingkas } from "@/lib/types";
import { cx } from "./ui";

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
    <article className="flex h-full flex-col rounded-2xl border border-c4/60 bg-white p-5 shadow-kartu">
      {kepala && <div className="mb-3">{kepala}</div>}
      <h3 className="text-base font-bold leading-snug text-navy">
        <Link href={`/beasiswa/${beasiswa.id}`} className="hover:text-primary hover:underline">
          {beasiswa.nama}
        </Link>
      </h3>
      <ul className="mt-3 space-y-1.5 text-sm text-ink">
        {beasiswa.penyelenggara && (
          <li className="flex items-center gap-2">
            <Building2 className="h-4 w-4 shrink-0 text-muted" aria-hidden />
            {beasiswa.penyelenggara}
          </li>
        )}
        {beasiswa.negara && (
          <li className="flex items-center gap-2">
            <Globe className="h-4 w-4 shrink-0 text-muted" aria-hidden />
            {beasiswa.negara}
          </li>
        )}
      </ul>
      {beasiswa.jenjang && beasiswa.jenjang.length > 0 && (
        <div className="mt-3 flex flex-wrap gap-1.5">
          {beasiswa.jenjang.map((j) => (
            <span key={j} className="rounded-full bg-c2 px-2.5 py-0.5 text-xs font-semibold text-navy">
              {j}
            </span>
          ))}
        </div>
      )}
      <div
        className={cx(
          "mt-4 flex items-center gap-2 rounded-xl px-3 py-2 text-xs font-semibold",
          dekat ? "bg-danger-soft text-[#8c1212]" : "bg-c1 text-navy",
        )}
      >
        <CalendarDays className="h-4 w-4" aria-hidden />
        <span>Tenggat {beasiswa.tenggat ? tanggalIndo(beasiswa.tenggat) : "belum diumumkan"}</span>
        <span className="ml-auto">{labelSisa(beasiswa.tenggat)}</span>
      </div>
      {children && <div className="mt-4 flex-1">{children}</div>}
    </article>
  );
}

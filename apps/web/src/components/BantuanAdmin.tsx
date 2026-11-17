import { HelpCircle } from "lucide-react";
import type { ReactNode } from "react";

/** Kotak "Cara memakai" yang dapat dilipat, dipakai di tiap halaman admin supaya jelas urutan kerjanya. */
export function BantuanAdmin({ judul = "Cara memakai halaman ini", terbuka = false, children }: { judul?: string; terbuka?: boolean; children: ReactNode }) {
  return (
    <details open={terbuka} className="group mb-6 rounded-kartu border border-c4/60 bg-c1 p-4 text-sm text-ink">
      <summary className="flex min-h-11 cursor-pointer list-none items-center gap-2 font-bold text-navy [&::-webkit-details-marker]:hidden">
        <HelpCircle className="h-5 w-5 text-primary" aria-hidden />
        {judul}
        <span className="ml-auto text-xs font-semibold text-muted group-open:hidden">Tampilkan</span>
        <span className="ml-auto hidden text-xs font-semibold text-muted group-open:inline">Sembunyikan</span>
      </summary>
      <div className="mt-2 space-y-2 leading-relaxed">{children}</div>
    </details>
  );
}

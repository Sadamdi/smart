import { Suspense } from "react";
import { Gerbang } from "@/components/Gerbang";
import { MemuatState } from "@/components/state";

// Seluruh data halaman dimuat di sisi klien setelah token diperiksa, jadi navigasi ke sini tidak instan.
export const instant = false;

export default function LayoutAplikasi({ children }: { children: React.ReactNode }) {
  return (
    <Suspense
      fallback={
        <div className="mx-auto max-w-lg px-4 py-16">
          <MemuatState baris={2} />
        </div>
      }
    >
      <Gerbang>{children}</Gerbang>
    </Suspense>
  );
}

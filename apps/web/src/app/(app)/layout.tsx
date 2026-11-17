import { Suspense } from "react";
import { Gerbang } from "@/components/Gerbang";
import { MemuatHalaman } from "@/components/Ilustrasi";

// Seluruh data halaman dimuat di sisi klien setelah token diperiksa, jadi navigasi ke sini tidak instan.
export const instant = false;

export default function LayoutAplikasi({ children }: { children: React.ReactNode }) {
  return (
    <Suspense
      fallback={
        <div className="mx-auto max-w-lg px-4 py-16">
          <MemuatHalaman />
        </div>
      }
    >
      <Gerbang>{children}</Gerbang>
    </Suspense>
  );
}

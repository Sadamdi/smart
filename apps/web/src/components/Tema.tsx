"use client";
import { createContext, useCallback, useContext, useEffect, useMemo, useSyncExternalStore, type ReactNode } from "react";
import { bacaPilihan, selesaikan, simpanPilihan, terapkan, type PilihanTema, type TemaTerpakai } from "@/lib/tema";

type Nilai = { pilihan: PilihanTema; terpakai: TemaTerpakai; atur: (p: PilihanTema) => void };
const Konteks = createContext<Nilai>({ pilihan: "sistem", terpakai: "terang", atur: () => undefined });

export const useTema = () => useContext(Konteks);

const pendengar = new Set<() => void>();
function langgananPilihan(cb: () => void) {
  pendengar.add(cb);
  window.addEventListener("storage", cb);
  return () => {
    pendengar.delete(cb);
    window.removeEventListener("storage", cb);
  };
}

// Tema yang sedang terpasang dibaca dari atribut data-theme pada elemen html.
function langgananTerpakai(cb: () => void) {
  const mo = new MutationObserver(cb);
  mo.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });
  return () => mo.disconnect();
}
const bacaTerpakai = (): TemaTerpakai => (document.documentElement.dataset.theme === "dark" ? "gelap" : "terang");

export function TemaProvider({ children }: { children: ReactNode }) {
  const pilihan = useSyncExternalStore(langgananPilihan, bacaPilihan, (): PilihanTema => "sistem");
  const terpakai = useSyncExternalStore(langgananTerpakai, bacaTerpakai, (): TemaTerpakai => "terang");

  // Saat memilih Sistem, ikuti perubahan tema perangkat.
  useEffect(() => {
    if (pilihan !== "sistem") return;
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    const f = () => terapkan(selesaikan("sistem"));
    mq.addEventListener("change", f);
    return () => mq.removeEventListener("change", f);
  }, [pilihan]);

  const atur = useCallback((p: PilihanTema) => {
    simpanPilihan(p);
    terapkan(selesaikan(p));
    pendengar.forEach((f) => f());
  }, []);

  const nilai = useMemo(() => ({ pilihan, terpakai, atur }), [pilihan, terpakai, atur]);
  return <Konteks.Provider value={nilai}>{children}</Konteks.Provider>;
}

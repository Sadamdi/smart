"use client";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import { AppShell } from "./AppShell";
import { GalatState, MemuatState } from "./state";
import { TautanTombol } from "./ui";
import { ApiError } from "@/lib/api";
import { useSaya } from "@/lib/hooks";
import { tokenStore } from "@/lib/token";

export function Gerbang({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const path = usePathname();
  const saya = useSaya();
  const admin = path.startsWith("/admin");

  useEffect(() => {
    if (!tokenStore.ada()) router.replace("/masuk");
  }, [router]);

  if (saya.isError && !(saya.error instanceof ApiError && saya.error.status === 401)) {
    return (
      <div className="mx-auto max-w-lg px-4 py-16">
        <GalatState galat={saya.error} onCoba={() => saya.refetch()} />
      </div>
    );
  }
  if (!saya.data) {
    return (
      <div className="mx-auto max-w-lg px-4 py-16">
        <MemuatState baris={2} />
      </div>
    );
  }
  if (admin && saya.data.peran !== "admin") {
    return (
      <AppShell pengguna={saya.data} admin={false}>
        <div role="alert" className="rounded-kartu bg-card p-10 text-center shadow-kartu">
          <p className="text-lg font-semibold text-navy">Halaman khusus admin</p>
          <p className="mt-1 text-sm text-ink">Akun ini tidak memiliki peran admin.</p>
          <TautanTombol href="/" className="mt-4">
            Kembali ke dashboard
          </TautanTombol>
        </div>
      </AppShell>
    );
  }
  return (
    <AppShell pengguna={saya.data} admin={admin}>
      {children}
    </AppShell>
  );
}

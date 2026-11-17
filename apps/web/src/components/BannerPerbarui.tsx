"use client";
import { CircleCheck } from "lucide-react";
import { JamPasir } from "./Ilustrasi";
import { useStatusPerbarui } from "@/lib/perbarui";

/** Spanduk di atas isi semua halaman: tampil saat rekomendasi dihitung ulang setelah profil berubah, lalu centang singkat. */
export function BannerPerbarui() {
  const s = useStatusPerbarui();
  if (s === "diam") return null;
  const menghitung = s === "menghitung";
  return (
    <div
      role="status"
      aria-live="polite"
      className={
        "mb-4 overflow-hidden rounded-kartu border px-4 py-3 text-sm font-semibold " +
        (menghitung ? "border-c4 bg-c2 text-navy" : "border-ok bg-ok-soft text-ok")
      }
    >
      <div className="flex items-center gap-3">
        {menghitung ? <JamPasir ukuran={30} /> : <CircleCheck className="h-7 w-7 shrink-0" aria-hidden />}
        <span>
          {menghitung ? "Memperbarui rekomendasi sesuai profil Anda. Daftar akan berubah sebentar lagi." : "Rekomendasi sudah diperbarui sesuai profil Anda."}
        </span>
      </div>
      {menghitung && (
        <div aria-hidden className="mt-2 h-1 overflow-hidden rounded-full bg-c4">
          <div className="h-full w-1/3 animate-[geser_1.2s_ease-in-out_infinite] rounded-full bg-primary" />
        </div>
      )}
    </div>
  );
}

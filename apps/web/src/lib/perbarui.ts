"use client";
import { useQueryClient } from "@tanstack/react-query";
import { useCallback, useSyncExternalStore } from "react";
import { kirim } from "./api";

export type StatusPerbarui = "diam" | "menghitung" | "selesai";

/** Status bersama untuk spanduk "Memperbarui rekomendasi": satu proses hitung ulang pada satu waktu. */
let status: StatusPerbarui = "diam";
const pendengar = new Set<() => void>();
const atur = (s: StatusPerbarui) => {
  status = s;
  pendengar.forEach((p) => p());
};
const langganan = (p: () => void) => {
  pendengar.add(p);
  return () => pendengar.delete(p);
};

export const useStatusPerbarui = () => useSyncExternalStore(langganan, () => status, () => "diam" as StatusPerbarui);

/** Menghitung ulang rekomendasi di latar belakang setelah profil berubah, dengan spanduk yang terlihat di semua halaman. */
export function usePerbaruiRekomendasi() {
  const qc = useQueryClient();
  return useCallback(async () => {
    if (status === "menghitung") return;
    atur("menghitung");
    try {
      await kirim("/rekomendasi/hitung-ulang", "POST");
      await qc.invalidateQueries({ queryKey: ["rekomendasi"] });
      atur("selesai");
      setTimeout(() => {
        if (status === "selesai") atur("diam");
      }, 3200);
    } catch {
      atur("diam");
    }
  }, [qc]);
}

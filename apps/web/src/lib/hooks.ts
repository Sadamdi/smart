"use client";
import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, kirim } from "./api";
import type {
  Acara,
  AntreanItem,
  BeasiswaDetail,
  BeasiswaRingkas,
  Chat,
  ChecklistBeasiswa,
  DetailAdmin,
  Dokumen,
  Laporan,
  Notifikasi,
  PengaturanAdmin,
  Pengguna,
  ReferensiWilayah,
  Rekomendasi,
  Ringkasan,
  Sumber,
  Tersimpan,
  Tugas,
} from "./types";

export const kunci = {
  saya: ["saya"] as const,
  rekom: (k?: string) => ["rekomendasi", k ?? "semua"] as const,
  ringkasan: ["rekomendasi", "ringkasan"] as const,
  tersimpan: ["tersimpan"] as const,
  checklist: ["checklist"] as const,
  kalender: ["kalender"] as const,
  dokumen: ["dokumen"] as const,
  notif: ["notifikasi"] as const,
};

const ambil = async <T>(path: string) => (await api<T>(path)).data;

export const useSaya = (aktif = true) => useQuery({ queryKey: kunci.saya, queryFn: () => ambil<Pengguna>("/me"), enabled: aktif, retry: false });
export const useWilayah = () =>
  useQuery({ queryKey: ["referensi", "wilayah"], queryFn: () => ambil<ReferensiWilayah>("/referensi/wilayah"), staleTime: Infinity });
export const useRekomendasi = (kategori?: string) =>
  useQuery({
    queryKey: kunci.rekom(kategori),
    queryFn: () => ambil<Rekomendasi[]>(`/rekomendasi${kategori ? `?kategori=${kategori}` : ""}`),
  });
export const useRingkasan = () => useQuery({ queryKey: kunci.ringkasan, queryFn: () => ambil<Ringkasan>("/rekomendasi/ringkasan") });
export const useTersimpan = () => useQuery({ queryKey: kunci.tersimpan, queryFn: () => ambil<Tersimpan[]>("/me/tersimpan") });
export const useChecklist = () => useQuery({ queryKey: kunci.checklist, queryFn: () => ambil<ChecklistBeasiswa[]>("/me/checklist") });
export const useKalender = (dari?: string, sampai?: string) =>
  useQuery({
    queryKey: [...kunci.kalender, dari, sampai],
    queryFn: () => {
      const q = new URLSearchParams();
      if (dari) q.set("dari", dari);
      if (sampai) q.set("sampai", sampai);
      return ambil<Acara[]>(`/me/kalender${q.size ? `?${q}` : ""}`);
    },
  });
export const useDokumen = () => useQuery({ queryKey: kunci.dokumen, queryFn: () => ambil<Dokumen[]>("/me/dokumen") });
export const useNotifikasi = () => useQuery({ queryKey: kunci.notif, queryFn: () => ambil<Notifikasi[]>("/notifikasi") });
export const useDetail = (id: string) =>
  useQuery({ queryKey: ["beasiswa", id], queryFn: () => ambil<BeasiswaDetail>(`/beasiswa/${id}`) });

export function useJelajah(filter: { q: string; jenjang: string; negara: string }) {
  return useInfiniteQuery({
    queryKey: ["jelajah", filter],
    initialPageParam: "",
    queryFn: async ({ pageParam }) => {
      const q = new URLSearchParams({ batas: "12" });
      if (filter.q) q.set("q", filter.q);
      if (filter.jenjang) q.set("jenjang", filter.jenjang);
      if (filter.negara) q.set("negara", filter.negara);
      if (pageParam) q.set("kursor", pageParam);
      const r = await api<BeasiswaRingkas[]>(`/beasiswa?${q}`);
      return { item: r.data, berikut: r.meta?.kursor_berikut ?? null };
    },
    getNextPageParam: (h) => h.berikut ?? undefined,
  });
}

export const useStatusChat = () => useQuery({ queryKey: ["chat", "status"], queryFn: () => ambil<{ tersedia: boolean }>("/chat/status") });
export const useRiwayatChat = () => useQuery({ queryKey: ["chat", "riwayat"], queryFn: () => ambil<Chat[]>("/chat/riwayat") });

// Admin
export const useAntrean = () => useQuery({ queryKey: ["admin", "antrean"], queryFn: () => ambil<AntreanItem[]>("/admin/antrean-validasi") });
export const useDetailAdmin = (id: string) =>
  useQuery({ queryKey: ["admin", "beasiswa", id], queryFn: () => ambil<DetailAdmin>(`/admin/beasiswa/${id}`) });
export const useSumber = () => useQuery({ queryKey: ["admin", "sumber"], queryFn: () => ambil<Sumber[]>("/admin/sumber") });
export const usePengaturan = () =>
  useQuery({ queryKey: ["admin", "pengaturan"], queryFn: () => ambil<PengaturanAdmin>("/admin/pengaturan") });
export const useLaporan = () => useQuery({ queryKey: ["admin", "laporan"], queryFn: () => ambil<Laporan>("/admin/laporan") });

/** Mutasi generik: kirim lalu batalkan cache kunci terkait. */
export function useAksi<V, R = unknown>(fn: (v: V) => Promise<R>, ...batal: (readonly unknown[])[]) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: fn,
    onSuccess: () => Promise.all(batal.map((k) => qc.invalidateQueries({ queryKey: k as unknown[] }))),
  });
}

export const aksiTugas = {
  buat: (v: { judul: string; tanggal: string }) => kirim<Tugas>("/me/tugas", "POST", v),
  ubah: (v: { id: string; selesai?: boolean; judul?: string; tanggal?: string }) => {
    const { id, ...isi } = v;
    return kirim<Tugas>(`/me/tugas/${id}`, "PUT", isi);
  },
  hapus: (id: string) => kirim(`/me/tugas/${id}`, "DELETE"),
};

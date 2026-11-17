import type { Laporan } from "./types";

/** Pekerjaan admin yang menunggu, tiap baris langsung menuju halaman tempat mengerjakannya. */
export function daftarTindakan(l: Laporan) {
  const menunggu = l.beasiswa_per_status.menunggu_validasi ?? 0;
  const gagal = l.sumber_per_status.gagal ?? 0;
  const belum = l.sumber_per_status.belum_pernah ?? 0;
  const hasil: { teks: string; href: string; aksi: string }[] = [];
  if (menunggu > 0) hasil.push({ teks: `${menunggu} beasiswa menunggu validasi`, href: "/admin/antrean", aksi: "Buka antrean" });
  if (gagal > 0) hasil.push({ teks: `${gagal} sumber gagal pada pemeriksaan terakhir`, href: "/admin/sumber", aksi: "Periksa sumber" });
  if (belum > 0) hasil.push({ teks: `${belum} sumber belum pernah dipantau`, href: "/admin/sumber", aksi: "Pantau sekarang" });
  return hasil;
}

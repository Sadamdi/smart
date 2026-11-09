const BULAN = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
export const NAMA_BULAN = BULAN;

/** Tanggal "2026-12-01" menjadi "1 Desember 2026". Nilai kosong atau tak valid menjadi tanda hubung. */
export function tanggalIndo(iso?: string | null): string {
  if (!iso) return "-";
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso);
  if (!m) return "-";
  return `${Number(m[3])} ${BULAN[Number(m[2]) - 1]} ${m[1]}`;
}

/** Selisih hari dari hari ini (zona waktu lokal) ke tanggal ISO. */
export function sisaHari(iso?: string | null, sekarang: Date = new Date()): number | null {
  if (!iso) return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso);
  if (!m) return null;
  const target = Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
  const hariIni = Date.UTC(sekarang.getFullYear(), sekarang.getMonth(), sekarang.getDate());
  return Math.round((target - hariIni) / 86400000);
}

export function labelSisa(iso?: string | null): string {
  const s = sisaHari(iso);
  if (s === null) return "Cek laman resmi";
  if (s < 0) return "Sudah lewat";
  if (s === 0) return "Hari ini";
  return `${s} hari lagi`;
}

export const LABEL_KATEGORI: Record<string, string> = {
  memenuhi: "Memenuhi",
  hampir_memenuhi: "Hampir memenuhi",
  belum_memenuhi: "Belum memenuhi",
};

export const LABEL_SYARAT: Record<string, string> = {
  ipk_minimum: "IPK minimum",
  semester_minimum: "Semester minimum",
  semester_maksimum: "Semester maksimum",
  jenjang: "Jenjang",
  jenis_kampus: "Jenis kampus",
  domisili: "Domisili",
  usia_maksimum: "Usia maksimum",
  sertifikat_bahasa: "Sertifikat bahasa",
  penghasilan_maksimum: "Penghasilan orang tua maksimum",
  kewarganegaraan: "Kewarganegaraan",
  berkas_pendukung: "Berkas pendukung",
  lainnya: "Persyaratan lain",
};

export function nilaiBatas(v?: Record<string, unknown> | null): string {
  if (!v) return "";
  return Object.entries(v)
    .map(([k, x]) => `${k.replace(/_/g, " ")}: ${Array.isArray(x) ? x.join(", ") : String(x)}`)
    .join("; ");
}

export function inisial(nama: string): string {
  return nama
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((k) => k[0]?.toUpperCase())
    .join("");
}

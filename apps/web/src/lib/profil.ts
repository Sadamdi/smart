import type { Pengguna } from "./types";

const BUTIR: [keyof Pengguna, string][] = [
  ["kampus", "Kampus"],
  ["jenis_kampus", "Jenis kampus"],
  ["program_studi", "Program studi"],
  ["jenjang", "Jenjang"],
  ["semester", "Semester"],
  ["ipk", "IPK"],
  ["kota_domisili", "Kota domisili"],
  ["tanggal_lahir", "Tanggal lahir"],
  ["kewarganegaraan", "Kewarganegaraan"],
  ["penghasilan_orang_tua", "Penghasilan orang tua"],
  ["minat", "Minat"],
];

/** Kelengkapan profil sebagai bilangan 0-100 dan daftar kolom yang masih kosong. */
export function kelengkapanProfil(p: Pengguna): { nilai: number; kosong: string[] } {
  const kosong = BUTIR.filter(([k]) => {
    const v = p[k];
    return v === null || v === undefined || v === "" || (Array.isArray(v) && v.length === 0);
  }).map(([, l]) => l);
  return { nilai: Math.round(((BUTIR.length - kosong.length) / BUTIR.length) * 100), kosong };
}

export type IsianProfil = {
  nama: string;
  tanggal_lahir: string;
  kota_domisili: string;
  kampus: string;
  jenis_kampus: string;
  program_studi: string;
  jenjang: string;
  semester: string;
  ipk: string;
  ips_terakhir: string;
  minat: string;
  penghasilan_orang_tua: string;
  toefl: string;
  ielts: string;
  kewarganegaraan: string;
};

export function isianDariPengguna(p: Pengguna): IsianProfil {
  const s = (v: unknown) => (v === null || v === undefined ? "" : String(v));
  return {
    nama: p.nama,
    tanggal_lahir: s(p.tanggal_lahir),
    kota_domisili: s(p.kota_domisili),
    kampus: s(p.kampus),
    jenis_kampus: s(p.jenis_kampus),
    program_studi: s(p.program_studi),
    jenjang: s(p.jenjang),
    semester: s(p.semester),
    ipk: s(p.ipk),
    ips_terakhir: s(p.ips_terakhir),
    minat: (p.minat ?? []).join(", "),
    penghasilan_orang_tua: s(p.penghasilan_orang_tua),
    toefl: s(p.skor_bahasa?.toefl),
    ielts: s(p.skor_bahasa?.ielts),
    kewarganegaraan: s(p.kewarganegaraan),
  };
}

/** Mengubah isian formulir menjadi muatan PUT /me/profil. Kolom kosong dikirim null agar dapat dikosongkan. */
export function muatanProfil(i: IsianProfil) {
  const teks = (v: string) => (v.trim() === "" ? null : v.trim());
  const angka = (v: string) => (v.trim() === "" ? null : Number(v.replace(",", ".")));
  const bahasa: Record<string, number> = {};
  const toefl = angka(i.toefl);
  const ielts = angka(i.ielts);
  if (toefl !== null) bahasa.toefl = toefl;
  if (ielts !== null) bahasa.ielts = ielts;
  const minat = i.minat.split(",").map((x) => x.trim()).filter(Boolean);
  return {
    nama: teks(i.nama) ?? undefined,
    tanggal_lahir: teks(i.tanggal_lahir),
    kota_domisili: teks(i.kota_domisili),
    kampus: teks(i.kampus),
    jenis_kampus: teks(i.jenis_kampus),
    program_studi: teks(i.program_studi),
    jenjang: teks(i.jenjang),
    semester: angka(i.semester),
    ipk: angka(i.ipk),
    ips_terakhir: angka(i.ips_terakhir),
    minat: minat.length ? minat : null,
    penghasilan_orang_tua: angka(i.penghasilan_orang_tua),
    skor_bahasa: Object.keys(bahasa).length ? bahasa : null,
    kewarganegaraan: teks(i.kewarganegaraan),
  };
}

// Tipe data mengikuti Dokument/02-Backend/openapi.json.
export type Jenjang = "D3" | "D4" | "S1" | "S2" | "S3";
export type Kategori = "memenuhi" | "hampir_memenuhi" | "belum_memenuhi";

export type TokenOut = { token_akses: string; token_penyegar: string; kedaluwarsa_detik: number };
export type Pengguna = {
  id: string;
  email: string;
  peran: "mahasiswa" | "admin" | string;
  nama: string;
  tanggal_lahir?: string | null;
  kota_domisili?: string | null;
  kampus?: string | null;
  jenis_kampus?: string | null;
  program_studi?: string | null;
  jenjang?: string | null;
  semester?: number | null;
  ipk?: string | null;
  ips_terakhir?: string | null;
  minat?: string[] | null;
  penghasilan_orang_tua?: number | null;
  skor_bahasa?: Record<string, number> | null;
  kewarganegaraan?: string | null;
  kondisi_khusus?: string[] | null;
  catatan_tambahan?: string | null;
  profil_lanjutan?: ProfilLanjutan | null;
  preferensi_notifikasi: { email?: boolean; push?: boolean };
};
export type ProfilLanjutan = {
  provinsi_asal?: string | null;
  kota_asal?: string | null;
  sekolah_asal?: string | null;
  jenis_sekolah?: "SMA" | "SMK" | "MA" | "Pesantren" | "Lainnya" | null;
  jurusan_sekolah?: string | null;
  tahun_lulus?: number | null;
  fakultas?: string | null;
  organisasi?: Record<string, string | number>[];
  prestasi?: Record<string, string | number>[];
  sertifikat?: Record<string, string | number>[];
  pengalaman?: Record<string, string | number>[];
  keahlian?: string[];
  target_studi?: { jenjang: string[]; negara: string[]; bidang: string[] } | null;
};
export type HasilDaftar = TokenOut & { pengguna: Pengguna };

export type BeasiswaRingkas = {
  id: string;
  nama: string;
  penyelenggara?: string | null;
  negara?: string | null;
  jenjang?: string[] | null;
  tenggat?: string | null;
  tautan_resmi: string;
};
export type Persyaratan = { jenis: string; nilai_batas?: Record<string, unknown> | null; dapat_dikejar: boolean };
export type BerkasWajib = { id: string; nama_berkas: string };
export type BeasiswaDetail = BeasiswaRingkas & {
  manfaat?: string | null;
  tanggal_diperiksa?: string | null;
  persyaratan?: Persyaratan[];
  berkas_wajib?: BerkasWajib[];
};
export type DetailAdmin = BeasiswaDetail & { status: string; alasan_ditandai?: string | null };
export type AntreanItem = BeasiswaRingkas & { status: string; alasan_ditandai?: string | null; nama_sumber: string };

export type Rekomendasi = {
  beasiswa: BeasiswaRingkas;
  kategori: Kategori;
  alasan: string[];
  catatan_kekurangan: string[];
  tenggat?: string | null;
};
export type Ringkasan = { memenuhi: number; hampir_memenuhi: number; belum_memenuhi: number };

export type Dokumen = {
  id: string;
  jenis: string;
  nama_berkas: string;
  status_baca: string;
  hasil_baca?: Record<string, unknown> | null;
  tanggal_unggah: string;
};

export type Tersimpan = { beasiswa: BeasiswaRingkas; status_rencana?: string | null };
export type ChecklistBeasiswa = {
  beasiswa: BeasiswaRingkas;
  berkas: { id: string; nama_berkas: string; selesai: boolean }[];
};
export type Acara = { jenis: "tenggat" | "tugas"; tanggal: string; judul: string; ref_id: string; selesai: boolean };
export type Tugas = { id: string; judul: string; tanggal: string; selesai: boolean };
export type Notifikasi = {
  id: string;
  jenis: string;
  dibaca: boolean;
  tanggal_acuan: string;
  judul: string;
  pesan: string;
  beasiswa_id: string;
};
export type Chat = {
  id: string;
  pesan: string;
  jawaban?: string | null;
  waktu: string;
  rujukan: { id: string; nama: string; tautan_resmi: string }[];
};
export type Sumber = {
  id: string;
  nama: string;
  url: string;
  jenis: "pantau_otomatis" | "tautan_keluar" | "input_manual" | "rujukan" | string;
  negara?: string | null;
  jadwal?: string | null;
  status_terakhir: string;
  aktif: boolean;
};
export type Laporan = {
  beasiswa_per_status: Record<string, number>;
  sumber_per_status: Record<string, number>;
  jumlah_sumber: number;
  jumlah_mahasiswa: number;
  divalidasi_ai?: number;
};
export type PengaturanAdmin = { auto_validasi_ai: boolean };

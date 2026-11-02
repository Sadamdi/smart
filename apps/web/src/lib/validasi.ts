export type IsianSyarat = { jenis: string; nilai: string; dapat_dikejar: boolean };
export type IsianValidasi = {
  nama: string;
  penyelenggara: string;
  negara: string;
  jenjang: string[];
  tenggat: string;
  tautan_resmi: string;
  manfaat: string;
  persyaratan: IsianSyarat[];
  berkas: string;
};

/** Mengurai nilai batas JSON dari isian. Melempar Error berpesan Indonesia bila tidak valid. */
export function bacaSyarat(s: IsianSyarat) {
  let nilai_batas: Record<string, unknown> | null = null;
  if (s.nilai.trim()) {
    try {
      const v = JSON.parse(s.nilai);
      if (typeof v !== "object" || v === null || Array.isArray(v)) throw new Error("bukan objek");
      nilai_batas = v;
    } catch {
      throw new Error(`Nilai batas untuk syarat "${s.jenis}" harus berupa JSON objek, misalnya {"nilai": 3.0}.`);
    }
  }
  return { jenis: s.jenis, nilai_batas, dapat_dikejar: s.dapat_dikejar };
}

export function muatanPerbaikan(i: IsianValidasi) {
  if (!i.nama.trim()) throw new Error("Nama beasiswa wajib diisi.");
  if (!i.tautan_resmi.trim()) throw new Error("Tautan resmi wajib diisi.");
  const teks = (v: string) => (v.trim() === "" ? null : v.trim());
  return {
    nama: i.nama.trim(),
    penyelenggara: teks(i.penyelenggara),
    negara: teks(i.negara),
    jenjang: i.jenjang.length ? i.jenjang : null,
    manfaat: teks(i.manfaat),
    tenggat: teks(i.tenggat),
    tautan_resmi: i.tautan_resmi.trim(),
    persyaratan: i.persyaratan.map(bacaSyarat),
    berkas_wajib: i.berkas.split("\n").map((x) => x.trim()).filter(Boolean),
  };
}

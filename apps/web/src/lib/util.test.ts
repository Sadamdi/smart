import { describe, expect, it } from "vitest";
import { labelSisa, sisaHari, tanggalIndo } from "./format";
import { isianDariPengguna, kelengkapanProfil, muatanProfil } from "./profil";
import { muatanPerbaikan } from "./validasi";
import type { Pengguna } from "./types";

const pengguna: Pengguna = { id: "1", email: "a@b.id", peran: "mahasiswa", nama: "Uji Coba", preferensi_notifikasi: {} };

describe("format", () => {
  it("memformat tanggal Indonesia", () => {
    expect(tanggalIndo("2026-12-08")).toBe("8 Desember 2026");
    expect(tanggalIndo(null)).toBe("-");
  });
  it("menghitung sisa hari", () => {
    const hariIni = new Date(2026, 10, 3);
    expect(sisaHari("2026-11-10", hariIni)).toBe(7);
    expect(sisaHari("2026-11-01", hariIni)).toBe(-2);
    expect(labelSisa(undefined)).toBe("Tenggat belum diketahui");
  });
});

describe("profil", () => {
  it("menghitung kelengkapan dan kolom kosong", () => {
    const k = kelengkapanProfil(pengguna);
    expect(k.nilai).toBe(0);
    expect(k.kosong).toContain("IPK");
    const sebagian = kelengkapanProfil({ ...pengguna, ipk: "3.50", kampus: "UIN", minat: ["riset"] });
    expect(sebagian.nilai).toBeGreaterThan(0);
    expect(sebagian.kosong).not.toContain("IPK");
  });
  it("menyusun muatan: kolom kosong menjadi null, angka menjadi number", () => {
    const i = { ...isianDariPengguna(pengguna), ipk: "3,5", semester: "5", minat: "riset, teknologi", toefl: "550" };
    const m = muatanProfil(i);
    expect(m.ipk).toBe(3.5);
    expect(m.semester).toBe(5);
    expect(m.minat).toEqual(["riset", "teknologi"]);
    expect(m.skor_bahasa).toEqual({ toefl: 550 });
    expect(m.kampus).toBeNull();
  });
});

describe("validasi admin", () => {
  const dasar = { nama: "Beasiswa", penyelenggara: "", negara: "", jenjang: ["S1"], tenggat: "2026-12-01", tautan_resmi: "https://x.id", manfaat: "", persyaratan: [], berkas: "KTP\n\nCV" };
  it("menyusun muatan perbaikan", () => {
    const m = muatanPerbaikan(dasar);
    expect(m.berkas_wajib).toEqual(["KTP", "CV"]);
    expect(m.penyelenggara).toBeNull();
  });
  it("menolak JSON nilai batas yang rusak", () => {
    expect(() => muatanPerbaikan({ ...dasar, persyaratan: [{ jenis: "ipk_minimum", nilai: "tiga", dapat_dikejar: false }] })).toThrow(/JSON/);
  });
  it("mewajibkan nama", () => {
    expect(() => muatanPerbaikan({ ...dasar, nama: " " })).toThrow(/Nama/);
  });
});

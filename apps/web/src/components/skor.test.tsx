import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

vi.mock("next/link", () => ({ default: ({ href, children, ...p }: { href: string; children: React.ReactNode }) => <a href={href} {...p}>{children}</a> }));

import { JamPasir, MemuatHalaman } from "./Ilustrasi";
import { KartuBeasiswa } from "./KartuBeasiswa";
import { TabWilayah } from "./Skor";

const dasar = { id: "1", nama: "Beasiswa Uji", tautan_resmi: "https://contoh.id", tenggat: null };

describe("KartuBeasiswa dengan skor kelayakan", () => {
  it("menampilkan cincin skor dan syarat terpenuhi X dari Y", () => {
    render(<KartuBeasiswa beasiswa={dasar} kelayakan={{ kategori: "memenuhi", skor_kelayakan: 82, syarat_terpenuhi: 5, syarat_total: 6 }} />);
    expect(screen.getByRole("img", { name: "Skor kelayakan 82 persen" })).toBeTruthy();
    expect(screen.getByText("Syarat terpenuhi 5 dari 6")).toBeTruthy();
  });

  it("tanpa syarat terukur tidak menampilkan angka", () => {
    render(<KartuBeasiswa beasiswa={dasar} kelayakan={{ kategori: "hampir_memenuhi", skor_kelayakan: null, syarat_terpenuhi: 0, syarat_total: 0 }} />);
    expect(screen.getByRole("img", { name: "Skor kelayakan belum tersedia" })).toBeTruthy();
    expect(screen.getByText("Syarat belum tercatat, cek laman resmi")).toBeTruthy();
    expect(screen.queryByText(/Syarat terpenuhi/)).toBeNull();
  });

  it("memakai penilaian milik beasiswa (daftar Jelajah)", () => {
    render(<KartuBeasiswa beasiswa={{ ...dasar, kategori: "hampir_memenuhi", skor_kelayakan: 64, syarat_terpenuhi: 4, syarat_total: 7 }} />);
    expect(screen.getByText("Syarat terpenuhi 4 dari 7")).toBeTruthy();
  });

  it("server lama tanpa kolom skor tetap tampil seperti semula", () => {
    render(<KartuBeasiswa beasiswa={dasar} />);
    expect(screen.queryByText(/Syarat/)).toBeNull();
    expect(screen.getByText("Beasiswa Uji")).toBeTruthy();
  });
});

describe("TabWilayah", () => {
  it("memilih luar negeri memanggil onPilih", () => {
    const pilih = vi.fn();
    render(<TabWilayah nilai="dalam" onPilih={pilih} />);
    expect(screen.getByRole("tab", { name: "Dalam negeri" }).getAttribute("aria-selected")).toBe("true");
    fireEvent.click(screen.getByRole("tab", { name: "Luar negeri" }));
    expect(pilih).toHaveBeenCalledWith("luar");
  });
});

describe("Ilustrasi bergerak", () => {
  it("jam pasir dan halaman memuat dapat dibaca pembaca layar", () => {
    render(<MemuatHalaman pesan="Memuat akun" />);
    expect(screen.getByRole("status")).toBeTruthy();
    expect(screen.getByText("Memuat akun")).toBeTruthy();
    expect(screen.getAllByRole("img", { name: "Memuat" }).length).toBeGreaterThan(0);
    render(<JamPasir />);
  });
});

import { daftarTindakan } from "@/lib/admin";

describe("daftarTindakan admin", () => {
  const dasar = { jumlah_sumber: 3, jumlah_mahasiswa: 2 };
  it("kosong bila tidak ada pekerjaan", () => {
    expect(daftarTindakan({ ...dasar, beasiswa_per_status: { menunggu_validasi: 0 }, sumber_per_status: { berhasil: 3 } })).toEqual([]);
  });
  it("mengarahkan ke antrean dan sumber", () => {
    const t = daftarTindakan({ ...dasar, beasiswa_per_status: { menunggu_validasi: 4 }, sumber_per_status: { gagal: 1, belum_pernah: 2 } });
    expect(t.map((x) => x.href)).toEqual(["/admin/antrean", "/admin/sumber", "/admin/sumber"]);
    expect(t[0].teks).toBe("4 beasiswa menunggu validasi");
  });
});

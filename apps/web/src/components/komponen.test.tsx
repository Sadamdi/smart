import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

const dorong = vi.fn();
vi.mock("next/navigation", () => ({ useRouter: () => ({ push: dorong, replace: dorong }) }));
vi.mock("next/link", () => ({ default: ({ href, children, ...p }: { href: string; children: React.ReactNode }) => <a href={href} {...p}>{children}</a> }));

const masuk = vi.fn();
const daftar = vi.fn();
vi.mock("@/lib/auth", () => ({ masuk: (...a: unknown[]) => masuk(...a), daftar: (...a: unknown[]) => daftar(...a) }));

import { ApiError } from "@/lib/api";
import { FormDaftar } from "./FormDaftar";
import { FormMasuk } from "./FormMasuk";
import { GalatState } from "./state";
import { KartuBeasiswa } from "./KartuBeasiswa";
import { KolomUnggah, periksaBerkas } from "./KolomUnggah";
import { Donat } from "./ui";

beforeEach(() => {
  vi.clearAllMocks();
});

function isi(label: RegExp | string, nilai: string) {
  fireEvent.change(screen.getByLabelText(label), { target: { value: nilai } });
}

describe("FormMasuk", () => {
  it("menampilkan galat validasi tanpa memanggil API", async () => {
    render(<FormMasuk />);
    fireEvent.click(screen.getByRole("button", { name: "Masuk" }));
    expect(await screen.findByText("Email wajib diisi")).toBeInTheDocument();
    expect(masuk).not.toHaveBeenCalled();
  });

  it("masuk lalu mengarahkan ke dashboard", async () => {
    masuk.mockResolvedValue(undefined);
    render(<FormMasuk />);
    isi(/email/i, "uji@kampus.ac.id");
    isi(/kata sandi/i, "rahasia-uji");
    fireEvent.click(screen.getByRole("button", { name: "Masuk" }));
    await waitFor(() => expect(masuk).toHaveBeenCalledWith("uji@kampus.ac.id", "rahasia-uji"));
    expect(dorong).toHaveBeenCalledWith("/");
  });

  it("menampilkan pesan galat dari server", async () => {
    masuk.mockRejectedValue(new ApiError("UNAUTHORIZED", "Email atau kata sandi salah", 401));
    render(<FormMasuk />);
    isi(/email/i, "uji@kampus.ac.id");
    isi(/kata sandi/i, "salah");
    fireEvent.click(screen.getByRole("button", { name: "Masuk" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("Email atau kata sandi salah");
  });
});

describe("FormDaftar", () => {
  it("menolak kata sandi pendek dan yang tidak sama", async () => {
    render(<FormDaftar />);
    isi(/nama lengkap/i, "Uji");
    isi(/^email/i, "uji@kampus.ac.id");
    isi(/^kata sandi/i, "pendek");
    isi(/ulangi/i, "beda");
    fireEvent.click(screen.getByRole("button", { name: "Buat akun" }));
    expect(await screen.findByText("Kata sandi minimal 8 karakter")).toBeInTheDocument();
    expect(daftar).not.toHaveBeenCalled();
  });

  it("mendaftar dengan data valid lalu ke profil", async () => {
    daftar.mockResolvedValue(undefined);
    render(<FormDaftar />);
    isi(/nama lengkap/i, "Uji Coba");
    isi(/^email/i, "uji@kampus.ac.id");
    isi(/^kata sandi/i, "kata-sandi-uji");
    isi(/ulangi/i, "kata-sandi-uji");
    fireEvent.click(screen.getByRole("button", { name: "Buat akun" }));
    await waitFor(() => expect(daftar).toHaveBeenCalledWith("Uji Coba", "uji@kampus.ac.id", "kata-sandi-uji"));
    expect(dorong).toHaveBeenCalledWith("/profil");
  });
});

describe("KartuBeasiswa", () => {
  const b = { id: "b1", nama: "Beasiswa Uji", penyelenggara: "Yayasan Uji", negara: "Indonesia", jenjang: ["S1", "S2"], tenggat: "2099-01-01", tautan_resmi: "https://x.id" };
  it("menampilkan nama, penyelenggara, jenjang, dan tautan ke detail", () => {
    render(<KartuBeasiswa beasiswa={b} />);
    expect(screen.getByRole("link", { name: "Beasiswa Uji" })).toHaveAttribute("href", "/beasiswa/b1");
    expect(screen.getByText("Yayasan Uji")).toBeInTheDocument();
    expect(screen.getByText("S2")).toBeInTheDocument();
    expect(screen.getByText(/Tenggat 1 Januari 2099/)).toBeInTheDocument();
  });
  it("tidak menampilkan persen kecocokan", () => {
    const { container } = render(<KartuBeasiswa beasiswa={b} />);
    expect(container.textContent).not.toMatch(/%|cocok/i);
  });
});

describe("GalatState", () => {
  it("menawarkan coba lagi pada galat jaringan", () => {
    const coba = vi.fn();
    render(<GalatState galat={new ApiError("NETWORK", "Tidak dapat terhubung", 0)} onCoba={coba} />);
    fireEvent.click(screen.getByRole("button", { name: /coba lagi/i }));
    expect(coba).toHaveBeenCalled();
  });
  it("menjelaskan layanan AI tidak tersedia pada 503", () => {
    render(<GalatState galat={new ApiError("UPSTREAM_UNAVAILABLE", "Layanan AI sedang tidak dapat dihubungi", 503)} />);
    expect(screen.getByText("Layanan AI sedang tidak tersedia")).toBeInTheDocument();
    expect(screen.getByText(/diisi secara manual/)).toBeInTheDocument();
  });
});

describe("KolomUnggah", () => {
  it("memeriksa tipe dan ukuran berkas", () => {
    expect(periksaBerkas({ name: "cv.pdf", size: 1000 })).toBeNull();
    expect(periksaBerkas({ name: "cv.exe", size: 1000 })).toMatch(/Tipe/);
    expect(periksaBerkas({ name: "cv.pdf", size: 6 * 1024 * 1024 })).toMatch(/5 MB/);
  });
  it("meneruskan berkas valid dan menolak yang tidak valid", () => {
    const onPilih = vi.fn();
    render(<KolomUnggah onPilih={onPilih} />);
    const input = screen.getByLabelText("Pilih berkas", { selector: "input" });
    fireEvent.change(input, { target: { files: [new File(["x"], "cv.pdf")] } });
    expect(onPilih).toHaveBeenCalledOnce();
    fireEvent.change(input, { target: { files: [new File(["x"], "virus.exe")] } });
    expect(onPilih).toHaveBeenCalledOnce();
    expect(screen.getByRole("alert")).toHaveTextContent("Tipe berkas");
  });
});

describe("Donat", () => {
  it("menampilkan jumlah per kategori, bukan persen", () => {
    const { container } = render(<Donat bagian={[{ label: "Memenuhi", nilai: 3, warna: "#1b6b3a" }, { label: "Belum memenuhi", nilai: 1, warna: "#ba1a1a" }]} />);
    expect(screen.getByText("Memenuhi")).toBeInTheDocument();
    expect(container.textContent).not.toContain("%");
  });
});

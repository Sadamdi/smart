import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { tokenStore } from "@/lib/token";
import MemoriAI from "./page";

function balas(status: number, body: unknown) {
  return { status, ok: status < 400, json: async () => body };
}

type Butir = { id: string; jenis: string; isi: string; aktif: boolean; sumber: string | null; dibuat_pada: string };

function pasang(awal: Butir[]) {
  let daftar = awal;
  let utama = true;
  const panggilan: { url: string; method?: string; body?: string }[] = [];
  const f = vi.fn(async (url: string, init?: RequestInit) => {
    const u = String(url);
    const m = init?.method ?? "GET";
    panggilan.push({ url: u, method: m, body: init?.body as string | undefined });
    if (u.endsWith("/me/memori/statistik")) {
      const dipakai = utama ? daftar.filter((b) => b.aktif).length : 0;
      return balas(200, { success: true, data: { memori_aktif: utama, jumlah: daftar.length, jumlah_dipakai: dipakai, perkiraan_token: dipakai * 10, per_jenis: {} } });
    }
    if (u.endsWith("/me/memori/pengaturan") && m === "PUT") {
      utama = JSON.parse(String(init?.body)).aktif;
      return balas(200, { success: true, data: {} });
    }
    if (/\/me\/memori\/[^/]+$/.test(u) && m === "PATCH") {
      const id = u.split("/").pop();
      const isi = JSON.parse(String(init?.body));
      daftar = daftar.map((b) => (b.id === id ? { ...b, ...isi } : b));
      return balas(200, { success: true, data: {} });
    }
    if (/\/me\/memori\/[^/]+$/.test(u) && m === "DELETE") {
      const id = u.split("/").pop();
      daftar = daftar.filter((b) => b.id !== id);
      return balas(200, { success: true, data: {} });
    }
    if (u.endsWith("/me/memori") && m === "POST") {
      const v = JSON.parse(String(init?.body));
      daftar = [...daftar, { id: "baru", jenis: v.jenis, isi: v.isi, aktif: true, sumber: "manual", dibuat_pada: "2026-11-18T00:00:00Z" }];
      return balas(201, { success: true, data: {} });
    }
    if (u.endsWith("/me/memori")) return balas(200, { success: true, data: daftar });
    return balas(404, { success: false, error: { code: "NOT_FOUND", message: "x" } });
  });
  vi.stubGlobal("fetch", f);
  return panggilan;
}

function tampil() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <MemoriAI />
    </QueryClientProvider>,
  );
}

const B1: Butir = { id: "a1", jenis: "organisasi", isi: "Ketua BEM Fakultas 2025", aktif: true, sumber: "dokumen", dibuat_pada: "2026-11-18T00:00:00Z" };

beforeEach(() => {
  tokenStore.simpan({ token_akses: "a", token_penyegar: "b" });
});
afterEach(() => {
  vi.unstubAllGlobals();
  tokenStore.hapus();
});

describe("Memori AI (web)", () => {
  it("menampilkan butir dan beban token, lalu mematikan satu butir lewat saklar", async () => {
    const panggilan = pasang([B1]);
    tampil();
    expect(await screen.findByText("Ketua BEM Fakultas 2025")).toBeTruthy();
    expect(await screen.findByText(/Dipakai 1 dari 1 butir, menambah sekitar 10 token/)).toBeTruthy();
    fireEvent.click(screen.getByLabelText("Pakai memori: Ketua BEM Fakultas 2025"));
    await waitFor(() => expect(panggilan.some((p) => p.method === "PATCH" && p.body === JSON.stringify({ aktif: false }))).toBe(true));
    expect(await screen.findByText(/Dipakai 0 dari 1 butir, menambah sekitar 0 token/)).toBeTruthy();
  });

  it("saklar utama mematikan seluruh memori dan menyatakannya ke server", async () => {
    const panggilan = pasang([B1]);
    tampil();
    await screen.findByText("Ketua BEM Fakultas 2025");
    fireEvent.click(screen.getByLabelText("Pakai memori saat menjawab"));
    await waitFor(() => expect(panggilan.some((p) => p.method === "PUT" && p.body === JSON.stringify({ aktif: false }))).toBe(true));
    expect(await screen.findByText(/Dipakai 0 dari 1 butir/)).toBeTruthy();
  });

  it("menambah butir manual dan menghapus satu butir", async () => {
    const panggilan = pasang([B1]);
    tampil();
    await screen.findByText("Ketua BEM Fakultas 2025");
    fireEvent.change(screen.getByLabelText("Memori baru"), { target: { value: "Relawan mengajar 2 tahun" } });
    fireEvent.click(screen.getByRole("button", { name: /Tambah/ }));
    expect(await screen.findByText("Relawan mengajar 2 tahun")).toBeTruthy();
    fireEvent.click(screen.getAllByLabelText("Hapus memori")[0]);
    await waitFor(() => expect(panggilan.some((p) => p.method === "DELETE" && p.url.endsWith("/me/memori/a1"))).toBe(true));
    await waitFor(() => expect(screen.queryByText("Ketua BEM Fakultas 2025")).toBeNull());
  });

  it("memori kosong memberi petunjuk cara mengisinya", async () => {
    pasang([]);
    tampil();
    expect(await screen.findByText(/Belum ada memori/)).toBeTruthy();
  });
});

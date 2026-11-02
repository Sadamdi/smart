import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { tokenStore } from "@/lib/token";
import ChatbotAI from "./page";

vi.mock("next/link", () => ({ default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a> }));

function balas(status: number, body: unknown) {
  return { status, json: async () => body };
}
function pasang(opsi: { tersedia: boolean; kirim: ReturnType<typeof balas> }) {
  const f = vi.fn(async (url: string, init?: RequestInit) => {
    const u = String(url);
    if (u.endsWith("/chat/status")) return balas(200, { success: true, data: { tersedia: opsi.tersedia } });
    if (u.endsWith("/chat/riwayat")) return balas(200, { success: true, data: [] });
    if (u.endsWith("/chat") && init?.method === "POST") return opsi.kirim;
    return balas(404, { success: false, error: { code: "NOT_FOUND", message: "x" } });
  });
  vi.stubGlobal("fetch", f);
  return f;
}
function tampil() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <ChatbotAI />
    </QueryClientProvider>,
  );
}

beforeEach(() => {
  tokenStore.simpan({ token_akses: "a", token_penyegar: "b" });
  Element.prototype.scrollIntoView = vi.fn();
});
afterEach(() => {
  vi.unstubAllGlobals();
  tokenStore.hapus();
});

describe("Chatbot AI", () => {
  it("menampilkan jawaban dan rujukan", async () => {
    pasang({
      tersedia: true,
      kirim: balas(200, { success: true, data: { id: "1", pesan: "Tenggat?", jawaban: "Tenggat 1 Desember.", waktu: "2026-11-03T00:00:00", rujukan: [{ id: "b1", nama: "Beasiswa Uji", tautan_resmi: "https://x.id" }] } }),
    });
    tampil();
    expect(await screen.findByText("Layanan AI tersedia")).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("Pesan"), { target: { value: "Tenggat?" } });
    fireEvent.click(screen.getByRole("button", { name: "Kirim" }));
    expect(await screen.findByText(/Tenggat 1 Desember/)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Beasiswa Uji" })).toHaveAttribute("href", "/beasiswa/b1");
  });

  it("menampilkan pesan jelas saat layanan AI 503 dan mempertahankan teks", async () => {
    pasang({ tersedia: true, kirim: balas(503, { success: false, error: { code: "UPSTREAM_UNAVAILABLE", message: "AI mati" } }) });
    tampil();
    await screen.findByText("Layanan AI tersedia");
    fireEvent.change(screen.getByLabelText("Pesan"), { target: { value: "Halo" } });
    fireEvent.click(screen.getByRole("button", { name: "Kirim" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("Layanan AI sedang tidak tersedia");
    await waitFor(() => expect(screen.getByLabelText("Pesan")).toHaveValue("Halo"));
  });

  it("menonaktifkan kolom pesan dan menjelaskan jalur manual bila AI tidak tersedia", async () => {
    pasang({ tersedia: false, kirim: balas(503, {}) });
    tampil();
    expect(await screen.findByText("Layanan AI sedang tidak tersedia")).toBeInTheDocument();
    expect(screen.getByLabelText("Pesan")).toBeDisabled();
    expect(screen.getByText(/secara manual/)).toBeInTheDocument();
  });
});

import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { tokenStore } from "@/lib/token";
import ChatbotAI from "./page";

vi.mock("next/link", () => ({ default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a> }));

function balas(status: number, body: unknown) {
  return { status, ok: status < 400, json: async () => body };
}
/** Respons SSE palsu: potongan teks lalu peristiwa selesai (atau galat). */
function sse(peristiwa: { e: string; d: unknown }[]) {
  const enc = new TextEncoder();
  const isi = peristiwa.map((p) => "event: " + p.e + "\ndata: " + JSON.stringify(p.d) + "\n\n").join("");
  return { status: 200, ok: true, json: async () => ({}), body: new ReadableStream({ start(c) { c.enqueue(enc.encode(isi)); c.close(); } }) };
}
const SESI = (id: string, judul: string) => ({ id, judul, dibuat_pada: "2026-11-22T10:00:00Z", diubah_pada: "2026-11-22T10:00:00Z", jumlah: 1 });
function pasang(opsi: {
  tersedia: boolean;
  kirim: ReturnType<typeof balas> | ReturnType<typeof sse>;
  sesi?: ReturnType<typeof SESI>[];
  riwayat?: Record<string, unknown[]>;
}) {
  const sesiServer = [...(opsi.sesi ?? [])];
  const f = vi.fn(async (url: string, init?: RequestInit) => {
    const u = String(url);
    if (u.endsWith("/chat/status")) return balas(200, { success: true, data: { tersedia: opsi.tersedia } });
    if (u.endsWith("/chat/sesi") && init?.method === "POST") {
      sesiServer.unshift(SESI("baru", "Percakapan baru"));
      return balas(201, { success: true, data: sesiServer[0] });
    }
    if (u.endsWith("/chat/sesi")) return balas(200, { success: true, data: sesiServer });
    if (u.includes("/chat/riwayat")) return balas(200, { success: true, data: opsi.riwayat?.[new URL(u, "http://x").searchParams.get("sesi_id") ?? ""] ?? [] });
    if (u.endsWith("/chat/stream") && init?.method === "POST") return opsi.kirim;
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
      kirim: sse([
        { e: "token", d: { t: "Tenggat " } },
        { e: "token", d: { t: "1 **Desember**." } },
        { e: "selesai", d: { id: "1", pesan: "Tenggat?", jawaban: "Tenggat 1 **Desember**.", waktu: "2026-11-03T00:00:00", rujukan: [{ id: "b1", nama: "Beasiswa Uji", tautan_resmi: "https://x.id" }] } },
      ]),
    });
    tampil();
    expect(await screen.findByText("Layanan AI tersedia")).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("Pesan"), { target: { value: "Tenggat?" } });
    fireEvent.click(screen.getByRole("button", { name: "Kirim" }));
    expect(await screen.findByText("Desember")).toBeInTheDocument();
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

  it("membuka sesi terbaru, berpindah sesi, dan memberi sesi baru saat pesan pertama dikirim", async () => {
    const f = pasang({
      tersedia: true,
      sesi: [SESI("s2", "Beasiswa Jepang"), SESI("s1", "Syarat IPK")],
      riwayat: {
        s2: [{ id: "c2", sesi_id: "s2", pesan: "Cari beasiswa Jepang", jawaban: "Ini daftarnya", waktu: "2026-11-22T10:00:00", rujukan: [] }],
        s1: [{ id: "c1", sesi_id: "s1", pesan: "Berapa IPK minimal?", jawaban: "IPK 3.0", waktu: "2026-11-22T09:00:00", rujukan: [] }],
      },
      kirim: sse([{ e: "selesai", d: { id: "9", sesi_id: "baru", pesan: "Halo", jawaban: "Hai", waktu: "2026-11-22T11:00:00", rujukan: [] } }]),
    });
    tampil();
    expect(await screen.findByText("Ini daftarnya")).toBeInTheDocument(); // sesi terbaru terbuka otomatis
    fireEvent.click(screen.getByRole("button", { name: "Syarat IPK" }));
    expect(await screen.findByText("IPK 3.0")).toBeInTheDocument();
    expect(screen.queryByText("Ini daftarnya")).not.toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: /Percakapan baru/ }));
    fireEvent.change(screen.getByLabelText("Pesan"), { target: { value: "Halo" } });
    fireEvent.click(screen.getByRole("button", { name: "Kirim" }));
    expect(await screen.findByText("Hai")).toBeInTheDocument();
    const panggilan = f.mock.calls.find((c) => String(c[0]).endsWith("/chat/stream"));
    expect(JSON.parse(String((panggilan?.[1] as RequestInit).body)).sesi_id).toBe("baru");
  });

  it("menonaktifkan kolom pesan dan menjelaskan jalur manual bila AI tidak tersedia", async () => {
    pasang({ tersedia: false, kirim: balas(503, {}) });
    tampil();
    expect(await screen.findByText("Layanan AI sedang tidak tersedia")).toBeInTheDocument();
    expect(screen.getByLabelText("Pesan")).toBeDisabled();
    expect(screen.getByText(/secara manual/)).toBeInTheDocument();
  });
});

import { afterEach, describe, expect, it, vi } from "vitest";
import { ApiError, apiFetch } from "./api";

function balas(status: number, body: unknown) {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue({ status, json: async () => body }));
}

afterEach(() => vi.unstubAllGlobals());

describe("apiFetch", () => {
  it("mengembalikan isi respons sukses", async () => {
    balas(200, { success: true, data: { status: "hidup" } });
    const r = await apiFetch<{ status: string }>("/health");
    expect(r.data.status).toBe("hidup");
  });

  it("melempar ApiError dengan kode dari server", async () => {
    balas(404, { success: false, error: { code: "NOT_FOUND", message: "Tidak ditemukan" } });
    await expect(apiFetch("/x")).rejects.toMatchObject({ code: "NOT_FOUND", status: 404 });
  });

  it("melempar ApiError NETWORK bila jaringan gagal", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("gagal")));
    const err = await apiFetch("/x").catch((e) => e);
    expect(err).toBeInstanceOf(ApiError);
    expect(err.code).toBe("NETWORK");
  });
});

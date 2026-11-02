import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { api, aturSaatKedaluwarsa } from "./api";
import { tokenStore } from "./token";

type Balasan = { status: number; body: unknown };
function pasangFetch(urutan: Balasan[]) {
  const f = vi.fn();
  for (const b of urutan) f.mockResolvedValueOnce({ status: b.status, json: async () => b.body });
  vi.stubGlobal("fetch", f);
  return f;
}
const galat401 = { status: 401, body: { success: false, error: { code: "UNAUTHORIZED", message: "Token tidak valid" } } };

beforeEach(() => tokenStore.simpan({ token_akses: "akses-lama", token_penyegar: "penyegar-lama" }));
afterEach(() => {
  vi.unstubAllGlobals();
  aturSaatKedaluwarsa(null);
  tokenStore.hapus();
});

describe("api dengan penyegaran token", () => {
  it("mengirim token akses pada header Authorization", async () => {
    const f = pasangFetch([{ status: 200, body: { success: true, data: { ok: 1 } } }]);
    await api("/me");
    const headers = f.mock.calls[0][1].headers as Headers;
    expect(headers.get("Authorization")).toBe("Bearer akses-lama");
  });

  it("menyegarkan token satu kali pada 401 lalu mengulang permintaan", async () => {
    const f = pasangFetch([
      galat401,
      { status: 200, body: { success: true, data: { token_akses: "akses-baru", token_penyegar: "penyegar-baru", kedaluwarsa_detik: 900 } } },
      { status: 200, body: { success: true, data: { nama: "Uji" } } },
    ]);
    const r = await api<{ nama: string }>("/me");
    expect(r.data.nama).toBe("Uji");
    expect(f).toHaveBeenCalledTimes(3);
    expect(String(f.mock.calls[1][0])).toContain("/auth/refresh");
    expect((f.mock.calls[2][1].headers as Headers).get("Authorization")).toBe("Bearer akses-baru");
    expect(tokenStore.penyegar()).toBe("penyegar-baru");
  });

  it("membersihkan token dan memanggil penanganan kedaluwarsa bila penyegaran gagal", async () => {
    const saatKedaluwarsa = vi.fn();
    aturSaatKedaluwarsa(saatKedaluwarsa);
    pasangFetch([galat401, galat401]);
    await expect(api("/me")).rejects.toMatchObject({ status: 401 });
    expect(saatKedaluwarsa).toHaveBeenCalledOnce();
    expect(tokenStore.ada()).toBe(false);
  });

  it("permintaan serentak yang 401 berbagi satu penyegaran", async () => {
    const f = vi.fn(async (url: string) => {
      if (String(url).includes("/auth/refresh"))
        return { status: 200, json: async () => ({ success: true, data: { token_akses: "baru", token_penyegar: "baru2", kedaluwarsa_detik: 900 } }) };
      const lama = f.mock.calls.filter((c) => !String(c[0]).includes("/auth/refresh")).length <= 2;
      return lama ? { status: 401, json: async () => galat401.body } : { status: 200, json: async () => ({ success: true, data: {} }) };
    });
    vi.stubGlobal("fetch", f);
    await Promise.all([api("/a"), api("/b")]);
    expect(f.mock.calls.filter((c) => String(c[0]).includes("/auth/refresh"))).toHaveLength(1);
  });

  it("tidak menyegarkan untuk galat selain 401", async () => {
    const f = pasangFetch([{ status: 503, body: { success: false, error: { code: "UPSTREAM_UNAVAILABLE", message: "AI mati" } } }]);
    await expect(api("/chat")).rejects.toMatchObject({ code: "UPSTREAM_UNAVAILABLE" });
    expect(f).toHaveBeenCalledTimes(1);
  });
});

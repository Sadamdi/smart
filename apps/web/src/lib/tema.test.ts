import { beforeEach, describe, expect, it, vi } from "vitest";
import { KUNCI_TEMA, SKRIP_TEMA, bacaPilihan, selesaikan, simpanPilihan, terapkan } from "./tema";

function pasangMedia(gelap: boolean) {
  vi.stubGlobal("matchMedia", () => ({ matches: gelap }));
}

beforeEach(() => {
  window.localStorage.clear();
  vi.unstubAllGlobals();
  pasangMedia(false);
  delete document.documentElement.dataset.theme;
});

describe("tema", () => {
  it("memakai sistem bila belum ada pilihan", () => {
    expect(bacaPilihan()).toBe("sistem");
  });

  it("menyimpan dan membaca pilihan", () => {
    simpanPilihan("gelap");
    expect(window.localStorage.getItem(KUNCI_TEMA)).toBe("gelap");
    expect(bacaPilihan()).toBe("gelap");
  });

  it("menyelesaikan sistem sesuai preferensi perangkat", () => {
    pasangMedia(true);
    expect(selesaikan("sistem")).toBe("gelap");
    expect(selesaikan("terang")).toBe("terang");
    pasangMedia(false);
    expect(selesaikan("sistem")).toBe("terang");
    expect(selesaikan("gelap")).toBe("gelap");
  });

  it("tidak gagal bila localStorage diblokir", () => {
    vi.spyOn(Storage.prototype, "getItem").mockImplementation(() => {
      throw new Error("diblokir");
    });
    vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new Error("diblokir");
    });
    expect(() => simpanPilihan("terang")).not.toThrow();
    expect(bacaPilihan()).toBe("terang");
    vi.restoreAllMocks();
  });

  it("menerapkan atribut data-theme", () => {
    terapkan("gelap");
    expect(document.documentElement.dataset.theme).toBe("dark");
    terapkan("terang");
    expect(document.documentElement.dataset.theme).toBe("light");
  });

  it("skrip pra-render menetapkan tema sebelum cat pertama", () => {
    window.localStorage.setItem(KUNCI_TEMA, "gelap");
    new Function(SKRIP_TEMA)();
    expect(document.documentElement.dataset.theme).toBe("dark");
    window.localStorage.setItem(KUNCI_TEMA, "terang");
    pasangMedia(true);
    new Function(SKRIP_TEMA)();
    expect(document.documentElement.dataset.theme).toBe("light");
  });
});

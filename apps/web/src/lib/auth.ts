import { apiFetch, api } from "./api";
import { tokenStore } from "./token";
import type { HasilDaftar, TokenOut } from "./types";

export async function masuk(email: string, kataSandi: string) {
  const r = await apiFetch<TokenOut>("/auth/login", {
    method: "POST",
    body: JSON.stringify({ email, kata_sandi: kataSandi }),
  });
  tokenStore.simpan(r.data);
}

export async function daftar(nama: string, email: string, kataSandi: string) {
  const r = await apiFetch<HasilDaftar>("/auth/register", {
    method: "POST",
    body: JSON.stringify({ nama, email, kata_sandi: kataSandi }),
  });
  tokenStore.simpan(r.data);
}

export async function keluar() {
  try {
    await api("/auth/logout", { method: "POST" });
  } catch {
    /* token mungkin sudah tidak berlaku; tetap hapus di sisi klien */
  }
  tokenStore.hapus();
}

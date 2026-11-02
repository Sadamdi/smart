// Klien API tunggal. Bentuk respons mengikuti Dokument/02-Backend/01-PRD-BACKEND.md:
// { success: true, data, meta? } atau { success: false, error: { code, message } }.
import { tokenStore } from "./token";

export type ApiSuccess<T> = { success: true; data: T; meta?: { kursor_berikut?: string | null } | null };
export type ApiFailure = { success: false; error: { code: string; message: string } };
export type ApiResponse<T> = ApiSuccess<T> | ApiFailure;

export class ApiError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly status: number,
  ) {
    super(message);
  }
}

// Di produksi (Vercel) default-nya lewat proxy /backend; lokal memakai NEXT_PUBLIC_API_URL ke backend langsung.
export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "/backend/api/v1";

export async function apiFetch<T>(path: string, init: RequestInit = {}, token?: string): Promise<ApiSuccess<T>> {
  const headers = new Headers(init.headers);
  if (!(init.body instanceof FormData) && init.body) headers.set("Content-Type", "application/json");
  if (token) headers.set("Authorization", `Bearer ${token}`);

  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}`, { ...init, headers });
  } catch {
    throw new ApiError("NETWORK", "Tidak dapat terhubung ke server. Periksa koneksi lalu coba lagi.", 0);
  }

  const body = (await res.json().catch(() => null)) as ApiResponse<T> | null;
  if (!body || body.success !== true) {
    const e = body && body.success === false ? body.error : { code: "INTERNAL", message: "Terjadi kesalahan pada server." };
    throw new ApiError(e.code, e.message, res.status);
  }
  return body;
}

type Token = { token_akses: string; token_penyegar: string };
let sedangMenyegar: Promise<boolean> | null = null;
let saatKedaluwarsa: (() => void) | null = null;

/** Didaftarkan oleh Providers: dipanggil bila penyegaran gagal, untuk kembali ke halaman masuk. */
export function aturSaatKedaluwarsa(fn: (() => void) | null) {
  saatKedaluwarsa = fn;
}

/** Menukar token penyegar. Permintaan serentak berbagi satu penyegaran. */
export function segarkanToken(): Promise<boolean> {
  if (sedangMenyegar) return sedangMenyegar;
  const penyegar = tokenStore.penyegar();
  if (!penyegar) return Promise.resolve(false);
  sedangMenyegar = apiFetch<Token>("/auth/refresh", { method: "POST", body: JSON.stringify({ token_penyegar: penyegar }) })
    .then((r) => {
      tokenStore.simpan(r.data);
      return true;
    })
    .catch(() => false)
    .finally(() => {
      sedangMenyegar = null;
    });
  return sedangMenyegar;
}

/** Permintaan terautentikasi. Pada 401 menyegarkan token satu kali lalu mengulang; bila gagal, sesi diakhiri. */
export async function api<T>(path: string, init: RequestInit = {}): Promise<ApiSuccess<T>> {
  try {
    return await apiFetch<T>(path, init, tokenStore.akses() ?? undefined);
  } catch (e) {
    if (!(e instanceof ApiError) || e.status !== 401) throw e;
    if (await segarkanToken()) return apiFetch<T>(path, init, tokenStore.akses() ?? undefined);
    tokenStore.hapus();
    saatKedaluwarsa?.();
    throw e;
  }
}

export const kirim = <T>(path: string, method: string, body?: unknown) =>
  api<T>(path, { method, body: body === undefined ? undefined : JSON.stringify(body) });

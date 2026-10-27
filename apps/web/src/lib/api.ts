// Klien API tunggal. Bentuk respons mengikuti Dokument/02-Backend/01-PRD-BACKEND.md:
// { success: true, data, meta? } atau { success: false, error: { code, message } }.

export type ApiSuccess<T> = { success: true; data: T; meta?: { nextCursor?: string | null } };
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

export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

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

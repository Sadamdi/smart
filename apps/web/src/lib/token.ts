// Penyimpanan token di peramban. Akses dan penyegar disimpan di localStorage; pembungkus try/catch
// karena penyimpanan dapat kosong atau ditolak (jendela pribadi).
const KUNCI_AKSES = "smart.akses";
const KUNCI_PENYEGAR = "smart.penyegar";
let akses: string | null = null;
let penyegar: string | null = null;
let dimuat = false;

function muat() {
  if (dimuat || typeof window === "undefined") return;
  dimuat = true;
  try {
    akses = window.localStorage.getItem(KUNCI_AKSES);
    penyegar = window.localStorage.getItem(KUNCI_PENYEGAR);
  } catch {
    /* penyimpanan tidak tersedia: token hanya di memori */
  }
}

export const tokenStore = {
  akses: () => (muat(), akses),
  penyegar: () => (muat(), penyegar),
  ada: () => (muat(), Boolean(akses || penyegar)),
  simpan(t: { token_akses: string; token_penyegar: string }) {
    dimuat = true;
    akses = t.token_akses;
    penyegar = t.token_penyegar;
    try {
      window.localStorage.setItem(KUNCI_AKSES, akses);
      window.localStorage.setItem(KUNCI_PENYEGAR, penyegar);
    } catch {
      /* diabaikan */
    }
  },
  hapus() {
    dimuat = true;
    akses = null;
    penyegar = null;
    try {
      window.localStorage.removeItem(KUNCI_AKSES);
      window.localStorage.removeItem(KUNCI_PENYEGAR);
    } catch {
      /* diabaikan */
    }
  },
};

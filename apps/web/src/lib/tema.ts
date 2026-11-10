// Pilihan tema: sistem, terang, gelap. Disimpan di localStorage (aman bila diblokir).
export type PilihanTema = "sistem" | "terang" | "gelap";
export type TemaTerpakai = "terang" | "gelap";

export const KUNCI_TEMA = "smart-tema";

// Cadangan di memori bila localStorage diblokir atau penuh.
let cadangan: PilihanTema = "sistem";

export function bacaPilihan(): PilihanTema {
  try {
    const v = window.localStorage.getItem(KUNCI_TEMA);
    if (v === "terang" || v === "gelap" || v === "sistem") return v;
  } catch {
    // diabaikan, pakai cadangan
  }
  return cadangan;
}

export function simpanPilihan(p: PilihanTema): void {
  cadangan = p;
  try {
    window.localStorage.setItem(KUNCI_TEMA, p);
  } catch {
    // penyimpanan diblokir; pilihan tetap berlaku selama halaman terbuka
  }
}

export function sistemGelap(): boolean {
  try {
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  } catch {
    return false;
  }
}

export function selesaikan(p: PilihanTema): TemaTerpakai {
  return p === "gelap" || (p === "sistem" && sistemGelap()) ? "gelap" : "terang";
}

export function terapkan(t: TemaTerpakai): void {
  document.documentElement.dataset.theme = t === "gelap" ? "dark" : "light";
}

/** Skrip pra-render: dipasang di head agar tema benar sebelum cat pertama (tanpa kedip). */
export const SKRIP_TEMA =
  '(function(){try{var p=null;try{p=localStorage.getItem("' +
  KUNCI_TEMA +
  '")}catch(e){}var g=p==="gelap"||(p!=="terang"&&window.matchMedia("(prefers-color-scheme: dark)").matches);document.documentElement.dataset.theme=g?"dark":"light"}catch(e){}})();';

import { cx } from "./ui";

/** Penilaian beasiswa terhadap profil untuk kartu. Skor kelayakan = seberapa banyak syarat terukur terpenuhi, bukan peluang diterima. */
export type KelayakanKartu = {
  kategori?: string | null;
  skor_kelayakan?: number | null;
  syarat_terpenuhi?: number;
  syarat_total?: number;
  luar_negeri?: boolean;
};

/** Ada penilaian bila server mengirim kolom skor (server lama tidak mengirimnya, kartu memakai tampilan lama). */
export const adaPenilaian = (k?: KelayakanKartu | null): k is KelayakanKartu =>
  !!k && ("skor_kelayakan" in k || "syarat_total" in k || "luar_negeri" in k);
export const adaAngka = (k: KelayakanKartu) => k.skor_kelayakan != null && (k.syarat_total ?? 0) > 0;

export const WARNA_SKOR: Record<string, string> = {
  memenuhi: "var(--ok)",
  hampir_memenuhi: "#e0a21b",
  belum_memenuhi: "var(--danger-fill)",
};
export const warnaSkor = (kategori?: string | null) => (kategori ? WARNA_SKOR[kategori] : undefined) ?? "var(--primary-soft)";

/** Cincin skor: busur terisi sebesar skor dari atas searah jarum jam. Skor kosong menampilkan tanda hubung, bukan angka. */
export function CincinSkor({ skor, warna, ukuran = 56, tebal = 6 }: { skor: number | null | undefined; warna: string; ukuran?: number; tebal?: number }) {
  const r = (ukuran - tebal) / 2;
  const keliling = 2 * Math.PI * r;
  const isi = skor == null ? 0 : Math.max(0, Math.min(100, skor)) / 100;
  return (
    <span className="relative inline-flex shrink-0" style={{ width: ukuran, height: ukuran }} role="img" aria-label={skor == null ? "Skor kelayakan belum tersedia" : `Skor kelayakan ${skor} persen`}>
      <svg width={ukuran} height={ukuran} viewBox={`0 0 ${ukuran} ${ukuran}`} aria-hidden>
        <circle cx={ukuran / 2} cy={ukuran / 2} r={r} fill="none" stroke="var(--c4)" strokeWidth={tebal} />
        {skor != null && skor > 0 && (
          <circle
            cx={ukuran / 2}
            cy={ukuran / 2}
            r={r}
            fill="none"
            stroke={warna}
            strokeWidth={tebal}
            strokeLinecap="round"
            strokeDasharray={`${keliling * Math.min(isi, 0.999)} ${keliling}`}
            transform={`rotate(-90 ${ukuran / 2} ${ukuran / 2})`}
            className="[transition:stroke-dasharray_700ms_cubic-bezier(.2,.7,.2,1)]"
          />
        )}
      </svg>
      <span className="absolute inset-0 flex items-center justify-center font-extrabold leading-none text-navy" style={{ fontSize: ukuran * ((skor ?? 0) >= 100 ? 0.23 : 0.3) }}>
        {skor == null ? <span className="text-muted">-</span> : <>{skor}<span className="font-bold text-muted" style={{ fontSize: ukuran * ((skor ?? 0) >= 100 ? 0.12 : 0.16) }}>%</span></>}
      </span>
    </span>
  );
}

/** Satu titik per syarat, terisi sebanyak yang terpenuhi. */
export function TitikSyarat({ terpenuhi, total, warna }: { terpenuhi: number; total: number; warna: string }) {
  return (
    <span className="inline-flex gap-[5px]" aria-hidden>
      {Array.from({ length: Math.min(total, 10) }, (_, i) => (
        <span key={i} className="h-2 w-2 rounded-full" style={{ background: i < terpenuhi ? warna : "var(--c4)" }} />
      ))}
    </span>
  );
}

/** Baris ringkas di kartu: titik syarat dan "Syarat terpenuhi X dari Y", atau penjelasan bila belum ada syarat terukur. */
export function BarisSyarat({ k }: { k: KelayakanKartu }) {
  if (!adaAngka(k)) return <p className="text-xs font-semibold text-muted">Syarat belum tercatat, cek laman resmi</p>;
  return (
    <p className="flex items-center gap-2 text-xs font-semibold text-ink">
      <TitikSyarat terpenuhi={k.syarat_terpenuhi ?? 0} total={k.syarat_total ?? 0} warna={warnaSkor(k.kategori)} />
      Syarat terpenuhi {k.syarat_terpenuhi} dari {k.syarat_total}
    </p>
  );
}

export type Wilayah = "dalam" | "luar";

/** Tab pil Dalam negeri dan Luar negeri. */
export function TabWilayah({ nilai, onPilih, className }: { nilai: Wilayah; onPilih: (w: Wilayah) => void; className?: string }) {
  const pil = (w: Wilayah, label: string) => (
    <button
      type="button"
      role="tab"
      aria-selected={nilai === w}
      onClick={() => onPilih(w)}
      className={cx(
        "min-h-10 flex-1 rounded-full border-[1.5px] px-5 text-sm font-bold transition-colors duration-150 sm:flex-none sm:min-w-40",
        nilai === w ? "border-navy bg-navy text-surface" : "border-c4 bg-card text-primary hover:bg-c1",
      )}
    >
      {label}
    </button>
  );
  return (
    <div role="tablist" aria-label="Wilayah beasiswa" className={cx("flex gap-2.5", className)}>
      {pil("dalam", "Dalam negeri")}
      {pil("luar", "Luar negeri")}
    </div>
  );
}

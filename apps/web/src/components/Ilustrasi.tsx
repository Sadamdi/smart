/**
 * Ilustrasi bergerak SMART, sebangun dengan logo Toga Lipat dan sama dengan versi mobile:
 * JamPasir (memuat satu halaman penuh), Gulungan (notifikasi kosong), LembarTerakhir (kalender tanpa tenggat).
 * Animasi ada di globals.css (kelas il-*) dan berhenti pada gambar bermakna bila pengguna mematikan animasi.
 */
const BINTANG = "0,-9 2.1,-2.9 8.6,-2.8 3.4,1.1 5.3,7.3 0,3.6 -5.3,7.3 -3.4,1.1 -8.6,-2.8 -2.1,-2.9";

export function JamPasir({ ukuran = 72 }: { ukuran?: number }) {
  return (
    <svg viewBox="0 0 120 120" width={ukuran} height={ukuran} role="img" aria-label="Memuat">
      <g className="il-balik">
        <polygon className="il-pasir-atas" points="40,25 80,25 66,48 54,48" fill="var(--emas)" />
        <polygon className="il-pasir-bawah" points="40,95 80,95 66,72 54,72" fill="var(--emas)" />
        <line className="il-aliran" x1="60" y1="50" x2="60" y2="94" stroke="var(--emas)" strokeWidth="2" />
        <path d="M36 22H84L64 60L84 98H36L56 60Z" fill="rgba(20,63,124,.07)" stroke="var(--navy)" strokeWidth="3.4" strokeLinejoin="round" />
        <rect x="30" y="14" width="60" height="8" rx="2" fill="var(--navy)" />
        <rect x="30" y="98" width="60" height="8" rx="2" fill="var(--navy)" />
      </g>
    </svg>
  );
}

export function Gulungan({ ukuran = 96 }: { ukuran?: number }) {
  return (
    <svg viewBox="0 0 120 120" width={ukuran} height={ukuran} role="img" aria-label="Belum ada pengumuman">
      <g className="il-kertas">
        <rect x="32" y="34" width="56" height="52" fill="#fff" stroke="var(--navy)" strokeWidth="3" />
        <line x1="40" y1="46" x2="80" y2="46" stroke="var(--c4)" strokeWidth="4" />
        <line x1="40" y1="55" x2="80" y2="55" stroke="var(--c4)" strokeWidth="4" />
        <line x1="40" y1="64" x2="64" y2="64" stroke="var(--c4)" strokeWidth="4" />
      </g>
      <rect className="il-gulung-kiri" x="20" y="28" width="12" height="64" rx="6" fill="var(--navy)" />
      <rect className="il-gulung-kanan" x="88" y="28" width="12" height="64" rx="6" fill="var(--navy)" />
      <g className="il-segel">
        <circle cx="60" cy="76" r="11" fill="var(--emas)" />
        <polygon points={BINTANG} transform="translate(60 76) scale(.8)" fill="var(--navy)" />
      </g>
    </svg>
  );
}

export function LembarTerakhir({ ukuran = 96 }: { ukuran?: number }) {
  return (
    <svg viewBox="0 0 120 120" width={ukuran} height={ukuran} role="img" aria-label="Tidak ada tenggat">
      <path d="M22 44V28A6 6 0 0 1 28 22H92A6 6 0 0 1 98 28V44Z" fill="var(--navy)" />
      <circle cx="42" cy="22" r="4" fill="var(--c4)" />
      <circle cx="78" cy="22" r="4" fill="var(--c4)" />
      <rect x="22" y="44" width="76" height="58" fill="var(--c2)" stroke="var(--navy)" strokeWidth="3" />
      <g className="il-bintang">
        <polygon points={BINTANG} transform="translate(60 76) scale(2.4)" fill="var(--emas)" />
      </g>
      <g className="il-depan">
        <rect x="22" y="44" width="76" height="58" fill="#fff" stroke="var(--navy)" strokeWidth="3" />
        <line x1="34" y1="62" x2="86" y2="62" stroke="var(--c4)" strokeWidth="4" />
        <line x1="34" y1="74" x2="86" y2="74" stroke="var(--c4)" strokeWidth="4" />
        <line x1="34" y1="86" x2="64" y2="86" stroke="var(--c4)" strokeWidth="4" />
      </g>
    </svg>
  );
}

/** Halaman penuh yang sedang memuat: jam pasir di tengah dengan keterangan singkat. */
export function MemuatHalaman({ pesan = "Memuat" }: { pesan?: string }) {
  return (
    <div role="status" aria-live="polite" aria-busy="true" className="flex flex-col items-center py-16">
      <JamPasir ukuran={76} />
      <p className="mt-3 text-sm text-muted">{pesan}</p>
    </div>
  );
}

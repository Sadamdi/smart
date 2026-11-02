"use client";
import { Upload } from "lucide-react";
import { useRef, useState } from "react";
import { cx } from "./ui";

export const BATAS_BYTE = 5 * 1024 * 1024;
export const EKSTENSI = [".pdf", ".docx", ".txt", ".png", ".jpg", ".jpeg"];

/** Validasi di sisi klien; server tetap memeriksa ulang. Mengembalikan pesan galat atau null. */
export function periksaBerkas(f: { name: string; size: number }): string | null {
  const ext = f.name.slice(f.name.lastIndexOf(".")).toLowerCase();
  if (!EKSTENSI.includes(ext)) return "Tipe berkas harus PDF, DOCX, TXT, PNG, atau JPG.";
  if (f.size > BATAS_BYTE) return "Ukuran berkas maksimal 5 MB.";
  if (f.size === 0) return "Berkas kosong.";
  return null;
}

export function KolomUnggah({ onPilih, sibuk }: { onPilih: (f: File) => void; sibuk?: boolean }) {
  const ref = useRef<HTMLInputElement>(null);
  const [galat, setGalat] = useState<string | null>(null);
  const [seret, setSeret] = useState(false);

  function tangani(f?: File | null) {
    if (!f) return;
    const g = periksaBerkas(f);
    setGalat(g);
    if (!g) onPilih(f);
  }

  return (
    <div>
      <div
        onDragOver={(e) => {
          e.preventDefault();
          setSeret(true);
        }}
        onDragLeave={() => setSeret(false)}
        onDrop={(e) => {
          e.preventDefault();
          setSeret(false);
          tangani(e.dataTransfer.files[0]);
        }}
        className={cx(
          "flex flex-col items-center rounded-2xl border-2 border-dashed px-6 py-8 text-center",
          seret ? "border-primary bg-c2" : "border-outline bg-c1",
        )}
      >
        <Upload className="mb-2 h-7 w-7 text-primary" aria-hidden />
        <p className="text-sm font-semibold text-navy">Tarik berkas ke sini atau pilih dari perangkat</p>
        <p className="mt-1 text-xs text-muted">PDF, DOCX, TXT, PNG, atau JPG. Maksimal 5 MB.</p>
        <button
          type="button"
          disabled={sibuk}
          onClick={() => ref.current?.click()}
          className="mt-4 rounded-full bg-primary px-5 py-2 text-sm font-semibold text-white hover:bg-[#1b4d8f] disabled:bg-outline disabled:text-muted"
        >
          {sibuk ? "Mengunggah" : "Pilih berkas"}
        </button>
        <input
          ref={ref}
          type="file"
          aria-label="Pilih berkas"
          accept={EKSTENSI.join(",")}
          className="hidden"
          onChange={(e) => {
            tangani(e.target.files?.[0]);
            e.target.value = "";
          }}
        />
      </div>
      {galat && (
        <p role="alert" className="mt-2 text-sm text-danger">
          {galat}
        </p>
      )}
    </div>
  );
}

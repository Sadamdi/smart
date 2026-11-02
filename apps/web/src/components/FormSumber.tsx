"use client";
import { useState } from "react";
import type { Sumber } from "@/lib/types";
import { pesanGalat } from "./state";
import { Kartu, Masukan, Medan, Pilihan, Tombol } from "./ui";

export const JENIS_SUMBER: Record<string, string> = {
  pantau_otomatis: "Pantau otomatis",
  tautan_keluar: "Tautan keluar",
  input_manual: "Input manual",
  rujukan: "Rujukan",
};

export type IsianSumber = { nama: string; url: string; jenis: string; negara: string; jadwal: string; aktif: boolean };

export function FormSumber({
  awal,
  edit,
  onKirim,
  sibuk,
  galat,
}: {
  awal?: Sumber;
  edit?: boolean;
  onKirim: (i: IsianSumber) => void;
  sibuk?: boolean;
  galat?: unknown;
}) {
  const [i, setI] = useState<IsianSumber>({
    nama: awal?.nama ?? "",
    url: awal?.url ?? "",
    jenis: awal?.jenis ?? "pantau_otomatis",
    negara: awal?.negara ?? "",
    jadwal: awal?.jadwal ?? "",
    aktif: awal?.aktif ?? true,
  });
  const [lokal, setLokal] = useState<string | null>(null);
  const set = <K extends keyof IsianSumber>(k: K, v: IsianSumber[K]) => setI({ ...i, [k]: v });

  return (
    <Kartu>
      <form
        className="max-w-2xl space-y-4"
        noValidate
        onSubmit={(e) => {
          e.preventDefault();
          if (!i.nama.trim()) return setLokal("Nama sumber wajib diisi.");
          if (!edit && !/^https?:\/\//i.test(i.url.trim())) return setLokal("Alamat laman harus diawali http:// atau https://.");
          setLokal(null);
          onKirim(i);
        }}
      >
        <Medan label="Nama sumber">
          <Masukan value={i.nama} onChange={(e) => set("nama", e.target.value)} />
        </Medan>
        <Medan label="Alamat laman">
          <Masukan value={i.url} onChange={(e) => set("url", e.target.value)} disabled={edit} placeholder="https://" />
        </Medan>
        {edit && <p className="-mt-2 text-xs text-muted">Alamat laman tidak dapat diubah. Buat sumber baru bila alamat berganti.</p>}
        <div className="grid gap-4 sm:grid-cols-3">
          <Medan label="Jenis">
            <Pilihan value={i.jenis} onChange={(e) => set("jenis", e.target.value)}>
              {Object.entries(JENIS_SUMBER).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </Pilihan>
          </Medan>
          <Medan label="Negara">
            <Masukan value={i.negara} onChange={(e) => set("negara", e.target.value)} />
          </Medan>
          <Medan label="Jadwal">
            <Masukan value={i.jadwal} onChange={(e) => set("jadwal", e.target.value)} placeholder="harian" />
          </Medan>
        </div>
        <label className="flex items-center gap-2 text-sm text-navy">
          <input type="checkbox" className="h-4 w-4 accent-primary" checked={i.aktif} onChange={(e) => set("aktif", e.target.checked)} />
          Sumber aktif dipantau
        </label>
        {(lokal || galat != null) && (
          <p role="alert" className="text-sm text-danger">
            {lokal ?? pesanGalat(galat).pesan}
          </p>
        )}
        <Tombol type="submit" disabled={sibuk}>
          {sibuk ? "Menyimpan" : edit ? "Simpan perubahan" : "Tambah sumber"}
        </Tombol>
      </form>
    </Kartu>
  );
}

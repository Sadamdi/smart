"use client";
import { useState } from "react";
import type { Dokumen } from "@/lib/types";
import { Masukan, Medan, Tombol } from "./ui";

type SkorBahasa = Record<string, number>;

/** Susun hasil baca dari isian formulir; kolom lain dari hasil lama dipertahankan. */
export function susunHasil(lama: Record<string, unknown>, f: { ipk: string; semester: string; toefl: string; ielts: string; organisasi: string }) {
  const hasil: Record<string, unknown> = { ...lama };
  const angka = (s: string) => (s.trim() === "" ? null : Number(s.replace(",", ".")));
  const set = (k: string, v: number | null) => {
    if (v === null || Number.isNaN(v)) delete hasil[k];
    else hasil[k] = v;
  };
  set("ipk", angka(f.ipk));
  set("semester", angka(f.semester));
  const bahasa: SkorBahasa = {};
  const toefl = angka(f.toefl);
  const ielts = angka(f.ielts);
  if (toefl !== null && !Number.isNaN(toefl)) bahasa.toefl = toefl;
  if (ielts !== null && !Number.isNaN(ielts)) bahasa.ielts = ielts;
  if (Object.keys(bahasa).length) hasil.skor_bahasa = bahasa;
  else delete hasil.skor_bahasa;
  const org = f.organisasi.split("\n").map((x) => x.trim()).filter(Boolean);
  if (org.length) hasil.pengalaman_organisasi = org;
  else delete hasil.pengalaman_organisasi;
  return hasil;
}

export function KoreksiHasilBaca({
  dokumen,
  onSimpan,
  sibuk,
  onBatal,
}: {
  dokumen: Dokumen;
  onSimpan: (hasil: Record<string, unknown>) => void;
  sibuk?: boolean;
  onBatal: () => void;
}) {
  const h = (dokumen.hasil_baca ?? {}) as Record<string, unknown>;
  const bahasa = (h.skor_bahasa ?? {}) as SkorBahasa;
  const [f, setF] = useState({
    ipk: h.ipk !== undefined ? String(h.ipk) : "",
    semester: h.semester !== undefined ? String(h.semester) : "",
    toefl: bahasa.toefl !== undefined ? String(bahasa.toefl) : "",
    ielts: bahasa.ielts !== undefined ? String(bahasa.ielts) : "",
    organisasi: Array.isArray(h.pengalaman_organisasi) ? (h.pengalaman_organisasi as string[]).join("\n") : "",
  });
  const ubah = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => setF({ ...f, [k]: e.target.value });

  return (
    <form
      className="mt-4 space-y-4 rounded-xl bg-c1 p-4"
      onSubmit={(e) => {
        e.preventDefault();
        onSimpan(susunHasil(h, f));
      }}
    >
      <p className="text-sm text-ink">Periksa hasil baca sistem dan perbaiki bila ada yang keliru.</p>
      <div className="grid gap-4 sm:grid-cols-2">
        <Medan label="IPK">
          <Masukan inputMode="decimal" value={f.ipk} onChange={ubah("ipk")} />
        </Medan>
        <Medan label="Semester">
          <Masukan inputMode="numeric" value={f.semester} onChange={ubah("semester")} />
        </Medan>
        <Medan label="Skor TOEFL">
          <Masukan inputMode="numeric" value={f.toefl} onChange={ubah("toefl")} />
        </Medan>
        <Medan label="Skor IELTS">
          <Masukan inputMode="decimal" value={f.ielts} onChange={ubah("ielts")} />
        </Medan>
      </div>
      <Medan label="Pengalaman organisasi (satu per baris)">
        <textarea
          rows={3}
          value={f.organisasi}
          onChange={ubah("organisasi")}
          className="w-full rounded-lg border border-outline bg-white px-3.5 py-2.5 text-sm text-navy"
        />
      </Medan>
      <div className="flex gap-2">
        <Tombol type="submit" disabled={sibuk}>
          {sibuk ? "Menyimpan" : "Simpan koreksi"}
        </Tombol>
        <Tombol varian="hantu" onClick={onBatal}>
          Batal
        </Tombol>
      </div>
    </form>
  );
}

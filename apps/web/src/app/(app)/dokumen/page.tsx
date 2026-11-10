"use client";
import { FileText, Trash2 } from "lucide-react";
import { useState } from "react";
import { KoreksiHasilBaca } from "@/components/KoreksiHasilBaca";
import { KolomUnggah } from "@/components/KolomUnggah";
import { KosongState, Tampil, pesanGalat } from "@/components/state";
import { JudulHalaman, Kartu, Lencana, Medan, Metrik, Pilihan, Tombol } from "@/components/ui";
import { api, kirim } from "@/lib/api";
import { kunci, useAksi, useDokumen } from "@/lib/hooks";
import { tanggalIndo } from "@/lib/format";
import type { Dokumen } from "@/lib/types";

const JENIS: Record<string, string> = { cv: "CV", sertifikat: "Sertifikat", pengalaman_organisasi: "Pengalaman organisasi" };
const STATUS: Record<string, string> = { selesai: "Terbaca", gagal: "Gagal dibaca, isi manual", diproses: "Diproses" };
const LABEL_HASIL: Record<string, string> = {
  ipk: "IPK",
  semester: "Semester",
  skor_bahasa: "Skor bahasa",
  pengalaman_organisasi: "Organisasi",
};

function ringkasHasil(h?: Record<string, unknown> | null) {
  if (!h) return [];
  return Object.entries(h)
    .filter(([k]) => k in LABEL_HASIL)
    .map(([k, v]) => [
      LABEL_HASIL[k],
      typeof v === "object" && v !== null && !Array.isArray(v)
        ? Object.entries(v as Record<string, unknown>).map(([a, b]) => `${a.toUpperCase()} ${b}`).join(", ")
        : Array.isArray(v)
          ? v.join("; ")
          : String(v),
    ]);
}

function BarisDokumen({ d }: { d: Dokumen }) {
  const [koreksi, setKoreksi] = useState(false);
  const [info, setInfo] = useState<string | null>(null);
  const hapus = useAksi(() => kirim(`/me/dokumen/${d.id}`, "DELETE"), kunci.dokumen);
  const simpan = useAksi((hasil: Record<string, unknown>) => kirim(`/me/dokumen/${d.id}/hasil-baca`, "PUT", { hasil_baca: hasil }), kunci.dokumen);
  const terapkan = useAksi(() => kirim<{ kolom_terisi: string[] }>(`/me/dokumen/${d.id}/terapkan-ke-profil`, "POST"), kunci.saya, ["rekomendasi"]);
  const ringkas = ringkasHasil(d.hasil_baca);
  const galat = hapus.error ?? simpan.error ?? terapkan.error;

  return (
    <li className="rounded-kartu border border-c4/60 bg-card p-5 shadow-kartu">
      <div className="flex flex-wrap items-start gap-3">
        <span className="flex h-11 w-11 items-center justify-center rounded-[14px] bg-c2 text-primary">
          <FileText className="h-5 w-5" aria-hidden />
        </span>
        <div className="min-w-0 flex-1">
          <p className="truncate font-bold text-navy">{d.nama_berkas}</p>
          <p className="mt-0.5 flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-muted">
            {JENIS[d.jenis] ?? d.jenis} <span aria-hidden>·</span> diunggah {tanggalIndo(d.tanggal_unggah)}
            <Lencana nada={d.status_baca === "selesai" ? "ok" : d.status_baca === "gagal" ? "bahaya" : "waspada"}>{STATUS[d.status_baca] ?? d.status_baca}</Lencana>
          </p>
        </div>
        <button type="button" aria-label={`Hapus ${d.nama_berkas}`} onClick={() => hapus.mutate()} disabled={hapus.isPending} className="flex h-11 w-11 items-center justify-center rounded-full text-muted hover:bg-danger-soft hover:text-danger">
          <Trash2 className="h-4 w-4" />
        </button>
      </div>
      {ringkas.length > 0 && (
        <dl className="mt-3 grid gap-x-6 gap-y-1 text-sm sm:grid-cols-2">
          {ringkas.map(([k, v]) => (
            <div key={k} className="flex gap-2">
              <dt className="text-muted">{k}:</dt>
              <dd className="text-navy">{v}</dd>
            </div>
          ))}
        </dl>
      )}
      {d.status_baca === "gagal" && <p className="mt-2 text-sm text-ink">Isi berkas tidak dapat dibaca otomatis. Anda dapat mengisi hasilnya secara manual.</p>}
      <div className="mt-3 flex flex-wrap gap-2">
        <Tombol varian="sekunder" onClick={() => setKoreksi(!koreksi)}>
          {koreksi ? "Tutup koreksi" : "Koreksi hasil baca"}
        </Tombol>
        {ringkas.length > 0 && (
          <Tombol
            varian="hantu"
            disabled={terapkan.isPending}
            onClick={() =>
              terapkan.mutate(undefined, {
                onSuccess: (r) => {
                  const k = (r as { data: { kolom_terisi: string[] } }).data.kolom_terisi;
                  setInfo(k.length ? `Terisi di profil: ${k.join(", ")}.` : "Tidak ada kolom profil kosong yang bisa diisi. Data profil yang sudah ada tidak ditimpa.");
                },
              })
            }
          >
            Terapkan ke profil
          </Tombol>
        )}
      </div>
      {info && (
        <p role="status" className="mt-2 text-sm text-ok">
          {info}
        </p>
      )}
      {galat && (
        <p role="alert" className="mt-2 text-sm text-danger">
          {pesanGalat(galat).pesan}
        </p>
      )}
      {koreksi && <KoreksiHasilBaca dokumen={d} sibuk={simpan.isPending} onBatal={() => setKoreksi(false)} onSimpan={(h) => simpan.mutate(h, { onSuccess: () => setKoreksi(false) })} />}
    </li>
  );
}

export default function DokumenSaya() {
  const kueri = useDokumen();
  const [jenis, setJenis] = useState("cv");
  const unggah = useAksi(
    async (f: File) => {
      const fd = new FormData();
      fd.set("jenis", jenis);
      fd.set("berkas", f);
      return api("/me/dokumen", { method: "POST", body: fd });
    },
    kunci.dokumen,
  );
  const d = kueri.data ?? [];

  return (
    <div className="halaman-masuk">
      <JudulHalaman judul="Dokumen Saya" deskripsi="Unggah CV atau sertifikat. Sistem membaca nilai penting, lalu Anda dapat memeriksa dan menerapkannya ke profil." />
      <div className="mb-6 grid grid-cols-3 gap-3 sm:gap-4">
        <Metrik label="Total" nilai={kueri.data ? d.length : "-"} memuat={kueri.isPending} />
        <Metrik label="Terbaca" nilai={kueri.data ? d.filter((x) => x.status_baca === "selesai").length : "-"} nada="utama" memuat={kueri.isPending} />
        <Metrik label="Isi manual" nilai={kueri.data ? d.filter((x) => x.status_baca === "gagal").length : "-"} memuat={kueri.isPending} />
      </div>
      <Kartu className="mb-6">
        <div className="mb-4 max-w-xs">
          <Medan label="Jenis dokumen">
            <Pilihan value={jenis} onChange={(e) => setJenis(e.target.value)}>
              {Object.entries(JENIS).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </Pilihan>
          </Medan>
        </div>
        <KolomUnggah onPilih={(f) => unggah.mutate(f)} sibuk={unggah.isPending} />
        {unggah.isError && (
          <p role="alert" className="mt-2 text-sm text-danger">
            {pesanGalat(unggah.error).pesan}
          </p>
        )}
      </Kartu>
      <Tampil kueri={kueri} kosong={<KosongState judul="Belum ada dokumen" pesan="Pilih jenis dokumen, lalu unggah CV atau sertifikat di kotak atas. Sistem akan membaca nilai pentingnya untuk mengisi profil lebih cepat." />}>
        {(daftar) => (
          <ul className="space-y-4">
            {daftar.map((x) => (
              <BarisDokumen key={x.id} d={x} />
            ))}
          </ul>
        )}
      </Tampil>
    </div>
  );
}

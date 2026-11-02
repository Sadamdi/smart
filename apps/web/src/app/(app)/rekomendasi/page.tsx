"use client";
import { RefreshCw } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { KartuBeasiswa } from "@/components/KartuBeasiswa";
import { KosongState, Tampil, pesanGalat } from "@/components/state";
import { ChipFilter, ChipStatus, JudulHalaman, Kartu, Tombol, TautanTombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { kelengkapanProfil } from "@/lib/profil";
import { useAksi, useRekomendasi, useRingkasan, useSaya } from "@/lib/hooks";
import { LABEL_KATEGORI } from "@/lib/format";

const KATEGORI = ["", "memenuhi", "hampir_memenuhi", "belum_memenuhi"] as const;

export default function Rekomendasi() {
  const [kategori, setKategori] = useState<string>("");
  const saya = useSaya().data;
  const kueri = useRekomendasi(kategori || undefined);
  const ringkasan = useRingkasan();
  const hitung = useAksi(() => kirim("/rekomendasi/hitung-ulang", "POST"), ["rekomendasi"]);
  const kel = saya ? kelengkapanProfil(saya) : null;

  const jumlah = (k: string) => (k === "" ? undefined : ringkasan.data?.[k as keyof NonNullable<typeof ringkasan.data>]);

  return (
    <div>
      <JudulHalaman
        judul="Rekomendasi Beasiswa"
        deskripsi="Mesin Rekomendasi menilai syarat beasiswa terhadap profil Anda. Hasil ini bantuan memilih, bukan jaminan diterima."
        aksi={
          <Tombol varian="sekunder" onClick={() => hitung.mutate()} disabled={hitung.isPending}>
            <RefreshCw className="h-4 w-4" aria-hidden /> {hitung.isPending ? "Menghitung" : "Hitung ulang"}
          </Tombol>
        }
      />
      {hitung.isError && (
        <p role="alert" className="mb-4 rounded-lg bg-danger-soft px-3 py-2 text-sm text-[#8c1212]">
          {pesanGalat(hitung.error).pesan}
        </p>
      )}
      {saya && (
        <Kartu className="mb-6">
          <p className="text-[11px] font-semibold uppercase tracking-wide text-muted">Ringkasan profil</p>
          <p className="mt-1 text-sm text-navy">
            {[saya.program_studi, saya.jenjang, saya.semester ? `Semester ${saya.semester}` : null, saya.ipk ? `IPK ${saya.ipk}` : null]
              .filter(Boolean)
              .join(" | ") || "Profil akademik belum diisi."}
          </p>
          {kel && kel.nilai < 100 && (
            <p className="mt-1 text-xs text-muted">
              Profil terisi {kel.nilai}%. Data yang lebih lengkap membuat penilaian syarat lebih tepat.{" "}
              <Link href="/profil" className="font-semibold text-primary underline">
                Lengkapi
              </Link>
            </p>
          )}
        </Kartu>
      )}
      <div className="mb-6 flex flex-wrap gap-2" role="group" aria-label="Kategori">
        {KATEGORI.map((k) => (
          <ChipFilter key={k} aktif={kategori === k} onClick={() => setKategori(k)}>
            {k === "" ? "Semua" : LABEL_KATEGORI[k]}
            {jumlah(k) !== undefined ? ` (${jumlah(k)})` : ""}
          </ChipFilter>
        ))}
      </div>
      <Tampil
        kueri={kueri}
        baris={3}
        kosong={
          <KosongState
            judul="Belum ada rekomendasi"
            pesan="Lengkapi profil akademik (jenjang, semester, IPK), lalu hitung ulang rekomendasi."
            aksi={<TautanTombol href="/profil">Lengkapi profil</TautanTombol>}
          />
        }
      >
        {(daftar) => (
          <ul className="grid gap-4 lg:grid-cols-2">
            {daftar.map((r) => (
              <li key={r.beasiswa.id}>
                <KartuBeasiswa beasiswa={r.beasiswa} kepala={<ChipStatus kategori={r.kategori} />}>
                  {r.alasan.length > 0 && (
                    <div>
                      <p className="text-xs font-semibold text-navy">Alasan</p>
                      <ul className="mt-1 list-disc space-y-1 pl-5 text-sm text-ink">
                        {r.alasan.map((a) => (
                          <li key={a}>{a}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                  {r.catatan_kekurangan.length > 0 && (
                    <div className="mt-3 rounded-xl bg-c1 p-3">
                      <p className="text-xs font-semibold text-navy">Catatan kekurangan</p>
                      <ul className="mt-1 list-disc space-y-1 pl-5 text-sm text-ink">
                        {r.catatan_kekurangan.map((a) => (
                          <li key={a}>{a}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                </KartuBeasiswa>
              </li>
            ))}
          </ul>
        )}
      </Tampil>
      <div className="mt-10 flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-c2 p-6">
        <p className="max-w-md text-sm text-navy">Ingin penjelasan lebih rinci tentang syarat sebuah beasiswa? Tanyakan ke Chatbot AI.</p>
        <TautanTombol href="/chat">Buka Chatbot AI</TautanTombol>
      </div>
    </div>
  );
}

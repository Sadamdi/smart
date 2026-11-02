"use client";
import Link from "next/link";
import { DaftarChecklist } from "@/components/DaftarChecklist";
import { KartuBeasiswa } from "@/components/KartuBeasiswa";
import { KosongState, Tampil } from "@/components/state";
import { BarProgres, ChipStatus, Donat, JudulHalaman, Kartu, Metrik, TautanTombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { kunci, useAksi, useChecklist, useKalender, useRekomendasi, useRingkasan, useSaya } from "@/lib/hooks";
import { labelSisa, sisaHari, tanggalIndo } from "@/lib/format";
import { kelengkapanProfil } from "@/lib/profil";

export default function Dashboard() {
  const saya = useSaya().data;
  const ringkasan = useRingkasan();
  const rekom = useRekomendasi();
  const checklist = useChecklist();
  const kalender = useKalender();
  const centang = useAksi(
    (v: { id: string; selesai: boolean }) => kirim(`/me/checklist/${v.id}`, "PUT", { selesai: v.selesai }),
    kunci.checklist,
  );

  if (!saya) return null;
  const kel = kelengkapanProfil(saya);
  const utama = rekom.data?.find((r) => r.kategori === "memenuhi") ?? rekom.data?.[0];
  const terdekat = kalender.data?.filter((a) => a.jenis === "tenggat" && (sisaHari(a.tanggal) ?? -1) >= 0).sort((a, b) => a.tanggal.localeCompare(b.tanggal));
  const yangPertama = checklist.data?.[0];

  return (
    <div className="space-y-8">
      <JudulHalaman
        judul={`Halo, ${saya.nama.split(" ")[0]}`}
        deskripsi="Ringkasan rekomendasi, tenggat, dan berkas yang perlu disiapkan."
        aksi={
          <div className="flex gap-2">
            <TautanTombol href="/rekomendasi">Lihat rekomendasi</TautanTombol>
            <TautanTombol href="/jelajah" varian="sekunder">
              Jelajah beasiswa
            </TautanTombol>
          </div>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Metrik label="IPK" nilai={saya.ipk ?? "-"} catatan={saya.ipk ? undefined : "Belum diisi di profil"} />
        <Metrik label="Memenuhi syarat" nilai={ringkasan.data?.memenuhi ?? "-"} catatan="Rekomendasi utama" />
        <Metrik label="Hampir memenuhi" nilai={ringkasan.data?.hampir_memenuhi ?? "-"} catatan="Ada syarat yang dapat dikejar" />
        <Metrik
          label="Tenggat terdekat"
          nilai={terdekat?.[0] ? labelSisa(terdekat[0].tanggal) : "-"}
          catatan={terdekat?.[0]?.judul ?? "Belum ada beasiswa tersimpan"}
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <Kartu>
            <h2 className="mb-4 text-lg font-bold text-navy">Pilihan utama untuk Anda</h2>
            <Tampil
              kueri={rekom}
              baris={1}
              kosong={
                <KosongState
                  judul="Belum ada rekomendasi"
                  pesan="Lengkapi profil akademik agar Mesin Rekomendasi dapat memeriksa syarat beasiswa."
                  aksi={<TautanTombol href="/profil">Lengkapi profil</TautanTombol>}
                />
              }
            >
              {() =>
                utama ? (
                  <KartuBeasiswa beasiswa={utama.beasiswa} kepala={<ChipStatus kategori={utama.kategori} />}>
                    <ul className="list-disc space-y-1 pl-5 text-sm text-ink">
                      {utama.alasan.slice(0, 3).map((a) => (
                        <li key={a}>{a}</li>
                      ))}
                    </ul>
                  </KartuBeasiswa>
                ) : null
              }
            </Tampil>
          </Kartu>

          <Kartu>
            <h2 className="mb-4 text-lg font-bold text-navy">Checklist berkas</h2>
            <Tampil
              kueri={checklist}
              baris={2}
              kosong={
                <KosongState
                  judul="Belum ada berkas yang dilacak"
                  pesan="Simpan sebuah beasiswa untuk mulai melacak berkas yang harus disiapkan."
                  aksi={<TautanTombol href="/jelajah">Jelajah beasiswa</TautanTombol>}
                />
              }
            >
              {() =>
                yangPertama ? (
                  <div>
                    <p className="mb-2 text-sm font-semibold text-navy">{yangPertama.beasiswa.nama}</p>
                    <DaftarChecklist
                      butir={yangPertama.berkas.map((b) => ({ id: b.id, label: b.nama_berkas, selesai: b.selesai }))}
                      onUbah={(id, selesai) => centang.mutate({ id, selesai })}
                      sibuk={centang.isPending}
                    />
                    <Link href="/kalender" className="mt-2 inline-block text-sm font-semibold text-primary underline">
                      Lihat semua checklist
                    </Link>
                  </div>
                ) : null
              }
            </Tampil>
          </Kartu>
        </div>

        <div className="space-y-6">
          <Kartu>
            <h2 className="mb-4 text-lg font-bold text-navy">Peta kelayakan</h2>
            <Tampil kueri={ringkasan} baris={1} adaIsi={() => true}>
              {(r) => (
                <Donat
                  bagian={[
                    { label: "Memenuhi", nilai: r.memenuhi, warna: "#1b6b3a" },
                    { label: "Hampir memenuhi", nilai: r.hampir_memenuhi, warna: "#6c9fef" },
                    { label: "Belum memenuhi", nilai: r.belum_memenuhi, warna: "#ba1a1a" },
                  ]}
                />
              )}
            </Tampil>
          </Kartu>

          <Kartu>
            <h2 className="mb-3 text-lg font-bold text-navy">Kelengkapan profil</h2>
            <BarProgres nilai={kel.nilai} label="Kelengkapan profil" />
            <p className="mt-2 text-sm text-ink">{kel.nilai}% terisi</p>
            {kel.kosong.length > 0 && (
              <p className="mt-1 text-xs text-muted">Belum diisi: {kel.kosong.slice(0, 4).join(", ")}{kel.kosong.length > 4 ? ", dan lainnya" : ""}.</p>
            )}
            <Link href="/profil" className="mt-3 inline-block text-sm font-semibold text-primary underline">
              Perbarui profil
            </Link>
          </Kartu>

          <Kartu>
            <h2 className="mb-3 text-lg font-bold text-navy">Tenggat mendatang</h2>
            <Tampil kueri={kalender} baris={1} adaIsi={() => true}>
              {() =>
                terdekat && terdekat.length > 0 ? (
                  <ul className="space-y-2 text-sm">
                    {terdekat.slice(0, 4).map((a) => (
                      <li key={a.ref_id + a.tanggal} className="flex justify-between gap-3">
                        <span className="text-navy">{a.judul}</span>
                        <span className="shrink-0 text-muted">{tanggalIndo(a.tanggal)}</span>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-ink">Belum ada tenggat. Simpan beasiswa untuk melihatnya di sini.</p>
                )
              }
            </Tampil>
          </Kartu>
          <TautanTombol href="/chat" varian="sekunder" className="w-full">
            Tanya Chatbot AI
          </TautanTombol>
        </div>
      </div>
    </div>
  );
}

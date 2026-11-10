"use client";
import { CalendarClock, ChevronRight, ClipboardCheck, MessageCircle, Sparkles } from "lucide-react";
import Link from "next/link";
import { DaftarChecklist } from "@/components/DaftarChecklist";
import { KartuBeasiswa } from "@/components/KartuBeasiswa";
import { KosongState, Tampil } from "@/components/state";
import { BarProgres, ChipStatus, Donat, JudulBagian, Kartu, Metrik, TautanTombol } from "@/components/ui";
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
  const dalam7 = terdekat?.filter((a) => (sisaHari(a.tanggal) ?? 99) <= 7).length ?? 0;

  return (
    <div className="halaman-masuk space-y-8">
      {/* Hero: sapaan, kelengkapan profil, jalan pintas */}
      <section className="relative overflow-hidden rounded-hero bg-gradient-to-br from-[var(--hero-a)] to-[var(--hero-b)] p-6 text-[var(--on-hero)] shadow-kartu sm:p-8">
        <span aria-hidden className="pointer-events-none absolute -right-16 -top-16 h-56 w-56 rounded-full bg-gold/20" />
        <span aria-hidden className="pointer-events-none absolute -bottom-24 right-24 h-48 w-48 rounded-full bg-white/5" />
        <div className="relative grid gap-6 md:grid-cols-[1fr_280px] md:items-end">
          <div>
            <p className="text-xs font-bold uppercase tracking-wide text-gold">Dashboard</p>
            <h1 className="mt-1 text-2xl font-extrabold leading-tight sm:text-[28px]">Halo, {saya.nama.split(" ")[0]}</h1>
            <p className="mt-1 max-w-xl text-sm text-[var(--on-hero-muted)]">Berikut ringkasan beasiswa dan tenggat terdekat untukmu.</p>
            <div className="mt-5 flex flex-wrap gap-2">
              <Link
                href="/rekomendasi"
                className="inline-flex min-h-11 items-center gap-2 rounded-kontrol bg-gold px-5 py-2.5 text-sm font-bold text-[#051b38] transition-opacity hover:opacity-90"
              >
                <Sparkles className="h-4 w-4" aria-hidden /> Lihat rekomendasi
              </Link>
              <Link
                href="/jelajah"
                className="inline-flex min-h-11 items-center rounded-kontrol bg-white/15 px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-white/25"
              >
                Jelajah beasiswa
              </Link>
            </div>
          </div>
          <div className="rounded-[18px] bg-white/10 p-4">
            <p className="flex items-baseline justify-between text-sm font-semibold">
              Kelengkapan profil <span className="text-lg font-extrabold">{kel.nilai}%</span>
            </p>
            <div
              role="progressbar"
              aria-valuenow={kel.nilai}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-label="Kelengkapan profil"
              className="mt-2 h-2 overflow-hidden rounded-full bg-white/20"
            >
              <div className="h-full rounded-full bg-gold transition-[width] duration-300" style={{ width: `${kel.nilai}%` }} />
            </div>
            <p className="mt-2 text-xs text-[var(--on-hero-muted)]">
              {kel.kosong.length > 0 ? `Belum diisi: ${kel.kosong.slice(0, 3).join(", ")}${kel.kosong.length > 3 ? ", dan lainnya" : ""}.` : "Profil lengkap."}
            </p>
            {kel.nilai < 100 && (
              <Link href="/profil" className="mt-1 inline-flex min-h-11 items-center text-sm font-bold text-gold underline underline-offset-2">
                Lengkapi profil
              </Link>
            )}
          </div>
        </div>
      </section>

      <div className="grid gap-4 grid-cols-2 xl:grid-cols-4">
        <Metrik label="Memenuhi syarat" nilai={ringkasan.data?.memenuhi ?? "-"} catatan="Rekomendasi utama" nada="utama" memuat={ringkasan.isPending} />
        <Metrik label="Hampir memenuhi" nilai={ringkasan.data?.hampir_memenuhi ?? "-"} catatan="Ada syarat yang dapat dikejar" memuat={ringkasan.isPending} />
        <Metrik
          label="Tenggat 7 hari"
          nilai={kalender.isPending ? "-" : dalam7}
          catatan={terdekat?.[0] ? `Berikutnya: ${terdekat[0].judul}` : "Belum ada beasiswa tersimpan"}
          nada={dalam7 > 0 ? "bahaya" : undefined}
          memuat={kalender.isPending}
        />
        <Metrik label="IPK" nilai={saya.ipk ?? "-"} catatan={saya.ipk ? undefined : "Belum diisi di profil"} />
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <section>
            <JudulBagian>Pilihan utama untuk Anda</JudulBagian>
            <Tampil
              kueri={rekom}
              baris={1}
              kosong={
                <KosongState
                  ikon={Sparkles}
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
          </section>

          <Kartu>
            <JudulBagian>Checklist berkas</JudulBagian>
            <Tampil
              kueri={checklist}
              baris={2}
              kosong={
                <KosongState
                  ikon={ClipboardCheck}
                  judul="Belum ada berkas yang dilacak"
                  pesan="Simpan sebuah beasiswa untuk mulai melacak berkas yang harus disiapkan."
                  aksi={<TautanTombol href="/jelajah">Jelajah beasiswa</TautanTombol>}
                />
              }
            >
              {() =>
                yangPertama ? (
                  <div>
                    <p className="mb-2 text-sm font-bold text-navy">{yangPertama.beasiswa.nama}</p>
                    <DaftarChecklist
                      butir={yangPertama.berkas.map((b) => ({ id: b.id, label: b.nama_berkas, selesai: b.selesai }))}
                      onUbah={(id, selesai) => centang.mutate({ id, selesai })}
                      sibuk={centang.isPending}
                    />
                    <Link href="/kalender" className="mt-2 inline-flex min-h-11 items-center gap-1 text-sm font-bold text-primary">
                      Lihat semua checklist <ChevronRight className="h-4 w-4" aria-hidden />
                    </Link>
                  </div>
                ) : null
              }
            </Tampil>
          </Kartu>
        </div>

        <div className="space-y-6">
          <Kartu>
            <JudulBagian>Tenggat terdekat</JudulBagian>
            <Tampil
              kueri={kalender}
              baris={1}
              adaIsi={() => Boolean(terdekat && terdekat.length > 0)}
              kosong={
                <KosongState
                  ikon={CalendarClock}
                  judul="Belum ada tenggat"
                  pesan="Simpan beasiswa untuk melihat tenggatnya di sini."
                  aksi={<TautanTombol href="/jelajah" varian="sekunder">Jelajah beasiswa</TautanTombol>}
                />
              }
            >
              {() => (
                <ul className="space-y-2">
                  {terdekat?.slice(0, 3).map((a) => {
                    const sisa = sisaHari(a.tanggal) ?? 99;
                    return (
                      <li key={a.ref_id + a.tanggal} className="rounded-[14px] bg-c1 px-3.5 py-2.5">
                        <p className="text-sm font-bold text-navy">{a.judul}</p>
                        <p className={sisa <= 7 ? "text-xs font-semibold text-danger" : "text-xs text-muted"}>
                          {labelSisa(a.tanggal)} <span aria-hidden>·</span> {tanggalIndo(a.tanggal)}
                        </p>
                      </li>
                    );
                  })}
                </ul>
              )}
            </Tampil>
          </Kartu>

          <Kartu>
            <JudulBagian>Peta kelayakan</JudulBagian>
            <Tampil kueri={ringkasan} baris={1} adaIsi={() => true}>
              {(r) => (
                <Donat
                  bagian={[
                    { label: "Memenuhi", nilai: r.memenuhi, warna: "var(--ok)" },
                    { label: "Hampir memenuhi", nilai: r.hampir_memenuhi, warna: "var(--primary-soft)" },
                    { label: "Belum memenuhi", nilai: r.belum_memenuhi, warna: "var(--error)" },
                  ]}
                />
              )}
            </Tampil>
          </Kartu>

          <Kartu>
            <JudulBagian>Kelengkapan profil</JudulBagian>
            <BarProgres nilai={kel.nilai} label="Kelengkapan profil" />
            <p className="mt-2 text-sm text-ink">{kel.nilai}% terisi</p>
            <Link href="/profil" className="mt-1 inline-flex min-h-11 items-center text-sm font-bold text-primary">
              Perbarui profil
            </Link>
          </Kartu>
          <TautanTombol href="/chat" varian="sekunder" className="w-full">
            <MessageCircle className="h-4 w-4" aria-hidden /> Tanya Chatbot AI
          </TautanTombol>
        </div>
      </div>
    </div>
  );
}

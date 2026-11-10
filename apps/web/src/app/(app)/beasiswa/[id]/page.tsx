"use client";
import { ArrowLeft, Bookmark, BookmarkCheck, CalendarDays, CircleAlert, CircleCheck, CircleHelp, CircleX, ExternalLink, Globe, Info } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import type { ComponentType } from "react";
import { DaftarChecklist } from "@/components/DaftarChecklist";
import { Tampil, pesanGalat } from "@/components/state";
import { ChipStatus, JudulBagian, Kartu, Lencana, Pilihan, Tombol, cx } from "@/components/ui";
import { kirim } from "@/lib/api";
import { kunci, useAksi, useChecklist, useDetail, useTersimpan } from "@/lib/hooks";
import { LABEL_SYARAT, labelSisa, nilaiBatas, sisaHari, tanggalIndo } from "@/lib/format";

const RENCANA: Record<string, string> = {
  akan_daftar: "Akan mendaftar",
  sudah_daftar: "Sudah mendaftar",
  tidak_jadi: "Tidak jadi",
};

type TampilanSyarat = { label: string; ikon: ComponentType<{ className?: string }>; kelas: string };
const STATUS_SYARAT: Record<string, TampilanSyarat> = {
  terpenuhi: { label: "Terpenuhi", ikon: CircleCheck, kelas: "bg-ok-soft text-ok" },
  dalam_toleransi: { label: "Hampir memenuhi", ikon: CircleAlert, kelas: "bg-warn-soft text-warn" },
  gagal: { label: "Belum terpenuhi", ikon: CircleX, kelas: "bg-danger-soft text-danger-ink" },
  tidak_diketahui: { label: "Belum dapat dinilai", ikon: CircleHelp, kelas: "bg-c2 text-ink" },
};

export default function DetailBeasiswa() {
  const { id } = useParams<{ id: string }>();
  const detail = useDetail(id);
  const tersimpan = useTersimpan();
  const checklist = useChecklist();

  const simpanan = tersimpan.data?.find((t) => t.beasiswa.id === id);
  const tersimpanKah = Boolean(simpanan);
  const berkasSaya = checklist.data?.find((c) => c.beasiswa.id === id);

  const simpan = useAksi(
    () => (tersimpanKah ? kirim(`/beasiswa/${id}/interaksi/simpan`, "DELETE") : kirim(`/beasiswa/${id}/interaksi`, "POST", { aksi: "simpan" })),
    kunci.tersimpan,
    kunci.checklist,
    kunci.kalender,
  );
  const rencana = useAksi(
    (status: string) => kirim(`/beasiswa/${id}/interaksi`, "POST", { aksi: "rencana_daftar", status_rencana: status }),
    kunci.tersimpan,
  );
  const centang = useAksi(
    (v: { id: string; selesai: boolean }) => kirim(`/me/checklist/${v.id}`, "PUT", { selesai: v.selesai }),
    kunci.checklist,
  );

  const tombolSimpan = (kelas?: string) => (
    <Tombol
      varian={tersimpanKah ? "sekunder" : "utama"}
      className={kelas}
      onClick={() => simpan.mutate()}
      disabled={simpan.isPending || tersimpan.isPending}
    >
      {tersimpanKah ? <BookmarkCheck className="h-4 w-4" aria-hidden /> : <Bookmark className="h-4 w-4" aria-hidden />}
      {tersimpanKah ? "Tersimpan" : "Simpan beasiswa"}
    </Tombol>
  );

  return (
    <Tampil kueri={detail}>
      {(b) => {
        const sisa = sisaHari(b.tenggat);
        const dekat = sisa !== null && sisa >= 0 && sisa <= 7;
        const adaStatus = b.persyaratan?.some((s) => s.status) ?? false;
        const adaPenilaian = Boolean(b.kategori) || (b.alasan?.length ?? 0) > 0 || (b.catatan_kekurangan?.length ?? 0) > 0;
        const lamanResmi = (kelas: string) => (
          <a
            href={b.tautan_resmi}
            target="_blank"
            rel="noopener noreferrer"
            onClick={() => {
              kirim(`/beasiswa/${id}/interaksi`, "POST", { aksi: "klik" }).catch(() => undefined);
            }}
            className={cx(
              "inline-flex min-h-11 items-center justify-center gap-2 rounded-kontrol bg-fill px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-fill-hover",
              kelas,
            )}
          >
            Buka laman resmi <ExternalLink className="h-4 w-4" aria-hidden />
          </a>
        );

        return (
          <div className="halaman-masuk space-y-6 pb-24 lg:pb-0">
            <Link href="/jelajah" className="inline-flex min-h-11 items-center gap-1.5 text-sm font-semibold text-primary">
              <ArrowLeft className="h-4 w-4" aria-hidden /> Kembali ke Jelajah
            </Link>

            <section className="rounded-hero border border-c4/60 bg-card p-5 shadow-kartu sm:p-7">
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div className="min-w-0 flex-1">
                  <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{b.penyelenggara ?? "Penyelenggara belum tercatat"}</p>
                  <h1 className="mt-1 text-2xl font-extrabold leading-tight text-navy sm:text-[28px]">{b.nama}</h1>
                  <div className="mt-3 flex flex-wrap items-center gap-2">
                    {b.kategori && <ChipStatus kategori={b.kategori} />}
                    {b.negara && (
                      <Lencana nada="info">
                        <Globe className="h-3 w-3" aria-hidden />
                        {b.negara}
                      </Lencana>
                    )}
                    {b.jenjang?.map((j) => (
                      <Lencana key={j}>{j}</Lencana>
                    ))}
                  </div>
                </div>
                <div className="hidden lg:block">{tombolSimpan()}</div>
              </div>
              <div
                className={cx(
                  "mt-5 flex flex-wrap items-center gap-2 rounded-[14px] px-4 py-3 text-sm font-semibold",
                  dekat ? "bg-danger-soft text-danger-ink" : "bg-c1 text-navy",
                )}
              >
                <CalendarDays className="h-4 w-4 shrink-0" aria-hidden />
                <span>Tenggat {b.tenggat ? tanggalIndo(b.tenggat) : "belum diumumkan, cek tautan resmi"}</span>
                {b.tenggat && <span className="ml-auto">{labelSisa(b.tenggat)}</span>}
              </div>
            </section>

            {simpan.isError && (
              <p role="alert" className="rounded-kontrol bg-danger-soft px-3 py-2 text-sm text-danger-ink">
                {pesanGalat(simpan.error).pesan}
              </p>
            )}

            <div className="grid gap-6 lg:grid-cols-3">
              <div className="space-y-6 lg:col-span-2">
                {adaPenilaian && (
                  <Kartu>
                    <JudulBagian>Kesesuaian dengan profil Anda</JudulBagian>
                    {b.kategori && (
                      <p className="mb-3 flex flex-wrap items-center gap-2 text-sm text-ink">
                        Penilaian sistem: <ChipStatus kategori={b.kategori} />
                      </p>
                    )}
                    {(b.alasan?.length ?? 0) > 0 && (
                      <>
                        <p className="text-[11px] font-bold uppercase tracking-wide text-muted">Alasan</p>
                        <ul className="mb-3 mt-1 space-y-1.5">
                          {b.alasan?.map((a) => (
                            <li key={a} className="flex items-start gap-2 text-sm text-ink">
                              <CircleCheck className="mt-0.5 h-4 w-4 shrink-0 text-ok" aria-hidden />
                              {a}
                            </li>
                          ))}
                        </ul>
                      </>
                    )}
                    {(b.catatan_kekurangan?.length ?? 0) > 0 && (
                      <>
                        <p className="text-[11px] font-bold uppercase tracking-wide text-muted">Yang masih kurang</p>
                        <ul className="mt-1 space-y-1.5">
                          {b.catatan_kekurangan?.map((a) => (
                            <li key={a} className="flex items-start gap-2 text-sm text-ink">
                              <CircleAlert className="mt-0.5 h-4 w-4 shrink-0 text-warn" aria-hidden />
                              {a}
                            </li>
                          ))}
                        </ul>
                      </>
                    )}
                    <p className="mt-4 flex items-start gap-2 text-xs text-muted">
                      <Info className="mt-0.5 h-3.5 w-3.5 shrink-0" aria-hidden />
                      Penilaian ini perkiraan sistem, bukan jaminan diterima. Keputusan akhir ada pada penyelenggara.
                    </p>
                  </Kartu>
                )}

                <Kartu>
                  <JudulBagian>Manfaat</JudulBagian>
                  <p className="whitespace-pre-line text-sm leading-relaxed text-ink">{b.manfaat || "Manfaat belum dicantumkan oleh sumber."}</p>
                </Kartu>

                <Kartu>
                  <JudulBagian>Persyaratan</JudulBagian>
                  {b.persyaratan && b.persyaratan.length > 0 ? (
                    <ul className="divide-y divide-c4/60">
                      {b.persyaratan.map((s, i) => {
                        const t = s.status ? (STATUS_SYARAT[s.status] ?? STATUS_SYARAT.tidak_diketahui) : null;
                        return (
                          <li key={i} className="flex flex-wrap items-start justify-between gap-x-4 gap-y-1.5 py-3 text-sm">
                            <div className="min-w-0 flex-1">
                              <p className="font-bold text-navy">{LABEL_SYARAT[s.jenis] ?? s.jenis}</p>
                              <p className="text-ink">{nilaiBatas(s.nilai_batas) || "Sesuai ketentuan penyelenggara"}</p>
                              {s.catatan && <p className="mt-0.5 text-xs text-muted">{s.catatan}</p>}
                              {s.dapat_dikejar && <p className="mt-0.5 text-xs text-muted">Dapat dikejar</p>}
                            </div>
                            {t && (
                              <span className={cx("inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-bold", t.kelas)}>
                                <t.ikon className="h-3.5 w-3.5" aria-hidden />
                                {t.label}
                              </span>
                            )}
                          </li>
                        );
                      })}
                    </ul>
                  ) : (
                    <p className="text-sm text-ink">Syarat belum tercatat. Periksa laman resmi.</p>
                  )}
                  {b.persyaratan && b.persyaratan.length > 0 && !adaStatus && (
                    <p className="mt-3 text-xs text-muted">
                      Lengkapi <Link href="/profil" className="font-semibold text-primary underline">profil</Link> agar sistem dapat menilai tiap syarat.
                    </p>
                  )}
                </Kartu>
              </div>

              <div className="space-y-6">
                <Kartu>
                  <JudulBagian>Berkas wajib</JudulBagian>
                  {berkasSaya ? (
                    <DaftarChecklist
                      butir={berkasSaya.berkas.map((x) => ({ id: x.id, label: x.nama_berkas, selesai: x.selesai }))}
                      onUbah={(bid, selesai) => centang.mutate({ id: bid, selesai })}
                      sibuk={centang.isPending}
                    />
                  ) : b.berkas_wajib && b.berkas_wajib.length > 0 ? (
                    <>
                      <DaftarChecklist butir={b.berkas_wajib.map((x) => ({ id: x.id, label: x.nama_berkas, selesai: false }))} />
                      <p className="mt-2 text-xs text-muted">Simpan beasiswa ini untuk mulai mencentang berkas yang sudah siap.</p>
                    </>
                  ) : (
                    <p className="text-sm text-ink">Daftar berkas belum tercatat.</p>
                  )}
                </Kartu>

                {tersimpanKah && (
                  <Kartu>
                    <JudulBagian>Rencana mendaftar</JudulBagian>
                    <Pilihan
                      aria-label="Status rencana"
                      value={simpanan?.status_rencana ?? ""}
                      disabled={rencana.isPending}
                      onChange={(e) => e.target.value && rencana.mutate(e.target.value)}
                    >
                      <option value="">Belum ditentukan</option>
                      {Object.entries(RENCANA).map(([k, v]) => (
                        <option key={k} value={k}>
                          {v}
                        </option>
                      ))}
                    </Pilihan>
                  </Kartu>
                )}

                <Kartu className="hidden lg:block">
                  <JudulBagian>Laman resmi</JudulBagian>
                  <p className="mb-3 text-xs text-muted">Pendaftaran dilakukan di laman penyelenggara. SMART tidak mengirim pendaftaran.</p>
                  {lamanResmi("w-full")}
                  <p className="mt-3 text-xs text-muted">Terakhir diperiksa: {tanggalIndo(b.tanggal_diperiksa)}</p>
                </Kartu>
                <p className="text-xs text-muted lg:hidden">
                  Pendaftaran dilakukan di laman penyelenggara. SMART tidak mengirim pendaftaran. Terakhir diperiksa: {tanggalIndo(b.tanggal_diperiksa)}.
                </p>
              </div>
            </div>

            {/* Bilah aksi menetap di layar kecil */}
            <div className="fixed inset-x-0 bottom-0 z-20 flex gap-2 border-t border-c4/60 bg-card/95 px-4 py-3 backdrop-blur lg:hidden">
              {tombolSimpan("flex-1")}
              {lamanResmi("flex-1")}
            </div>
          </div>
        );
      }}
    </Tampil>
  );
}

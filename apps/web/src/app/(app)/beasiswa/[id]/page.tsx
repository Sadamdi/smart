"use client";
import { Bookmark, BookmarkCheck, ExternalLink } from "lucide-react";
import { useParams } from "next/navigation";
import { DaftarChecklist } from "@/components/DaftarChecklist";
import { Tampil, pesanGalat } from "@/components/state";
import { Kartu, Pilihan, Tombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { kunci, useAksi, useChecklist, useDetail, useTersimpan } from "@/lib/hooks";
import { LABEL_SYARAT, labelSisa, nilaiBatas, tanggalIndo } from "@/lib/format";

const RENCANA: Record<string, string> = {
  akan_daftar: "Akan mendaftar",
  sudah_daftar: "Sudah mendaftar",
  tidak_jadi: "Tidak jadi",
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

  return (
    <Tampil kueri={detail}>
      {(b) => (
        <div className="space-y-6">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-wide text-muted">{b.penyelenggara ?? "Penyelenggara belum tercatat"}</p>
              <h1 className="mt-1 text-[28px] font-bold leading-tight text-navy">{b.nama}</h1>
              <div className="mt-3 flex flex-wrap gap-2 text-xs font-semibold">
                {b.negara && <span className="rounded-full bg-c2 px-3 py-1 text-navy">{b.negara}</span>}
                {b.jenjang?.map((j) => (
                  <span key={j} className="rounded-full bg-c2 px-3 py-1 text-navy">
                    {j}
                  </span>
                ))}
                <span className="rounded-full bg-c1 px-3 py-1 text-navy">
                  Tenggat {b.tenggat ? `${tanggalIndo(b.tenggat)} (${labelSisa(b.tenggat)})` : "belum diumumkan, cek tautan resmi"}
                </span>
              </div>
            </div>
            <Tombol varian={tersimpanKah ? "sekunder" : "utama"} onClick={() => simpan.mutate()} disabled={simpan.isPending || tersimpan.isPending}>
              {tersimpanKah ? <BookmarkCheck className="h-4 w-4" aria-hidden /> : <Bookmark className="h-4 w-4" aria-hidden />}
              {tersimpanKah ? "Tersimpan" : "Simpan beasiswa"}
            </Tombol>
          </div>
          {simpan.isError && (
            <p role="alert" className="rounded-lg bg-danger-soft px-3 py-2 text-sm text-[#8c1212]">
              {pesanGalat(simpan.error).pesan}
            </p>
          )}

          <div className="grid gap-6 lg:grid-cols-3">
            <div className="space-y-6 lg:col-span-2">
              <Kartu>
                <h2 className="mb-2 text-lg font-bold text-navy">Manfaat</h2>
                <p className="whitespace-pre-line text-sm leading-relaxed text-ink">{b.manfaat || "Manfaat belum dicantumkan oleh sumber."}</p>
              </Kartu>
              <Kartu>
                <h2 className="mb-3 text-lg font-bold text-navy">Persyaratan</h2>
                {b.persyaratan && b.persyaratan.length > 0 ? (
                  <ul className="divide-y divide-c4/60">
                    {b.persyaratan.map((s, i) => (
                      <li key={i} className="flex flex-wrap items-baseline justify-between gap-2 py-2 text-sm">
                        <span className="font-semibold text-navy">{LABEL_SYARAT[s.jenis] ?? s.jenis}</span>
                        <span className="text-ink">{nilaiBatas(s.nilai_batas) || "Sesuai ketentuan penyelenggara"}</span>
                        {s.dapat_dikejar && <span className="text-xs text-muted">Dapat dikejar</span>}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-ink">Syarat belum tercatat. Periksa laman resmi.</p>
                )}
              </Kartu>
            </div>

            <div className="space-y-6">
              <Kartu>
                <h2 className="mb-3 text-lg font-bold text-navy">Berkas wajib</h2>
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
                  <h2 className="mb-3 text-lg font-bold text-navy">Rencana mendaftar</h2>
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

              <Kartu>
                <h2 className="mb-2 text-lg font-bold text-navy">Laman resmi</h2>
                <p className="mb-3 text-xs text-muted">Pendaftaran dilakukan di laman penyelenggara. SMART tidak mengirim pendaftaran.</p>
                <a
                  href={b.tautan_resmi}
                  target="_blank"
                  rel="noopener noreferrer"
                  onClick={() => {
                    kirim(`/beasiswa/${id}/interaksi`, "POST", { aksi: "klik" }).catch(() => undefined);
                  }}
                  className="inline-flex w-full items-center justify-center gap-2 rounded-full bg-primary px-5 py-2.5 text-sm font-semibold text-white hover:bg-[#1b4d8f]"
                >
                  Buka laman resmi <ExternalLink className="h-4 w-4" aria-hidden />
                </a>
                <p className="mt-3 text-xs text-muted">Terakhir diperiksa: {tanggalIndo(b.tanggal_diperiksa)}</p>
              </Kartu>
            </div>
          </div>
        </div>
      )}
    </Tampil>
  );
}

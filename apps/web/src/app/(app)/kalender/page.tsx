"use client";
import { Trash2 } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { DaftarChecklist } from "@/components/DaftarChecklist";
import { KalenderBulan, isoTanggal } from "@/components/KalenderBulan";
import { KosongState, Tampil, pesanGalat } from "@/components/state";
import { Kartu, JudulHalaman, Masukan, Tombol, TautanTombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { aksiTugas, kunci, useAksi, useChecklist, useKalender } from "@/lib/hooks";
import { tanggalIndo } from "@/lib/format";

export default function KalenderChecklist() {
  const sekarang = new Date();
  const [tahun, setTahun] = useState(sekarang.getFullYear());
  const [bulan, setBulan] = useState(sekarang.getMonth());
  const [dipilih, setDipilih] = useState<string | null>(null);
  const [judul, setJudul] = useState("");
  const [tanggal, setTanggal] = useState("");

  const dari = isoTanggal(tahun, bulan, 1);
  const sampai = isoTanggal(tahun, bulan, new Date(tahun, bulan + 1, 0).getDate());
  const kalender = useKalender(dari, sampai);
  const checklist = useChecklist();

  const centang = useAksi(
    (v: { id: string; selesai: boolean }) => kirim(`/me/checklist/${v.id}`, "PUT", { selesai: v.selesai }),
    kunci.checklist,
  );
  const buat = useAksi(aksiTugas.buat, kunci.kalender);
  const ubah = useAksi(aksiTugas.ubah, kunci.kalender);
  const hapus = useAksi(aksiTugas.hapus, kunci.kalender);

  function geser(n: number) {
    const d = new Date(tahun, bulan + n, 1);
    setTahun(d.getFullYear());
    setBulan(d.getMonth());
    setDipilih(null);
  }

  const acara = kalender.data ?? [];
  const tampilAcara = dipilih ? acara.filter((a) => a.tanggal.slice(0, 10) === dipilih) : acara;

  return (
    <div>
      <JudulHalaman judul="Kalender dan Checklist" deskripsi="Tenggat beasiswa tersimpan, berkas yang harus siap, dan tugas pribadi Anda." />
      <div className="grid gap-6 lg:grid-cols-5">
        <div className="space-y-6 lg:col-span-2">
          <Kartu>
            <KalenderBulan tahun={tahun} bulan={bulan} acara={acara} dipilih={dipilih} onPilih={(d) => setDipilih(dipilih === d ? null : d)} onGeser={geser} />
          </Kartu>
          <Kartu>
            <h2 className="mb-3 text-lg font-bold text-navy">{dipilih ? `Acara ${tanggalIndo(dipilih)}` : "Acara bulan ini"}</h2>
            <Tampil
              kueri={kalender}
              baris={2}
              adaIsi={() => true}
            >
              {() =>
                tampilAcara.length === 0 ? (
                  <p className="text-sm text-ink">Tidak ada tenggat atau tugas pada rentang ini.</p>
                ) : (
                  <ul className="space-y-2">
                    {tampilAcara.map((a) => (
                      <li key={a.jenis + a.ref_id + a.tanggal} className="flex items-center gap-3 rounded-xl bg-c1 px-3 py-2 text-sm">
                        {a.jenis === "tugas" ? (
                          <input
                            type="checkbox"
                            aria-label={`Tandai ${a.judul}`}
                            checked={a.selesai}
                            onChange={(e) => ubah.mutate({ id: a.ref_id, selesai: e.target.checked })}
                            className="h-4 w-4 accent-primary"
                          />
                        ) : (
                          <span className="h-2.5 w-2.5 rounded-full bg-danger" aria-hidden />
                        )}
                        <span className="min-w-0 flex-1">
                          {a.jenis === "tenggat" ? (
                            <Link href={`/beasiswa/${a.ref_id}`} className="font-semibold text-navy hover:underline">
                              {a.judul}
                            </Link>
                          ) : (
                            <span className={a.selesai ? "text-muted line-through" : "font-semibold text-navy"}>{a.judul}</span>
                          )}
                          <span className="block text-xs text-muted">
                            {a.jenis === "tenggat" ? "Tenggat" : "Tugas"} | {tanggalIndo(a.tanggal)}
                          </span>
                        </span>
                        {a.jenis === "tugas" && (
                          <button type="button" aria-label={`Hapus ${a.judul}`} onClick={() => hapus.mutate(a.ref_id)} className="rounded-full p-1.5 text-muted hover:bg-danger-soft hover:text-danger">
                            <Trash2 className="h-4 w-4" />
                          </button>
                        )}
                      </li>
                    ))}
                  </ul>
                )
              }
            </Tampil>
          </Kartu>
        </div>

        <div className="space-y-6 lg:col-span-3">
          <Kartu>
            <h2 className="mb-4 text-lg font-bold text-navy">Checklist berkas</h2>
            <Tampil
              kueri={checklist}
              baris={2}
              kosong={<KosongState judul="Belum ada berkas yang dilacak" pesan="Simpan beasiswa untuk melihat daftar berkas wajibnya di sini." aksi={<TautanTombol href="/jelajah">Jelajah beasiswa</TautanTombol>} />}
            >
              {(daftar) => (
                <div className="space-y-5">
                  {daftar.map((c) => (
                    <div key={c.beasiswa.id}>
                      <Link href={`/beasiswa/${c.beasiswa.id}`} className="text-sm font-bold text-navy hover:underline">
                        {c.beasiswa.nama}
                      </Link>
                      <p className="mb-1 text-xs text-muted">
                        {c.berkas.filter((b) => b.selesai).length} dari {c.berkas.length} berkas siap
                      </p>
                      <DaftarChecklist
                        butir={c.berkas.map((b) => ({ id: b.id, label: b.nama_berkas, selesai: b.selesai }))}
                        onUbah={(id, selesai) => centang.mutate({ id, selesai })}
                        sibuk={centang.isPending}
                      />
                    </div>
                  ))}
                </div>
              )}
            </Tampil>
          </Kartu>

          <Kartu>
            <h2 className="mb-4 text-lg font-bold text-navy">Tugas pribadi</h2>
            <form
              className="flex flex-col gap-3 sm:flex-row"
              onSubmit={(e) => {
                e.preventDefault();
                if (!judul.trim() || !tanggal) return;
                buat.mutate({ judul: judul.trim(), tanggal }, { onSuccess: () => setJudul("") });
              }}
            >
              <Masukan aria-label="Judul tugas" placeholder="Contoh: minta surat rekomendasi" value={judul} onChange={(e) => setJudul(e.target.value)} maxLength={200} />
              <Masukan aria-label="Tanggal tugas" type="date" className="sm:w-44" value={tanggal} onChange={(e) => setTanggal(e.target.value)} />
              <Tombol type="submit" disabled={buat.isPending || !judul.trim() || !tanggal}>
                Tambah
              </Tombol>
            </form>
            {(buat.isError || ubah.isError || hapus.isError) && (
              <p role="alert" className="mt-2 text-sm text-danger">
                {pesanGalat(buat.error ?? ubah.error ?? hapus.error).pesan}
              </p>
            )}
            <p className="mt-3 text-xs text-muted">Tugas muncul di kalender pada tanggal yang dipilih.</p>
          </Kartu>
        </div>
      </div>
    </div>
  );
}

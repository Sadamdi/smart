"use client";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { ProfilLanjutanKartu } from "@/components/ProfilLanjutan";
import { pesanGalat } from "@/components/state";
import { BarProgres, JudulHalaman, Kartu, Masukan, Medan, Pilihan, Tombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { kunci, useSaya } from "@/lib/hooks";
import { PILIHAN_KONDISI, isianDariPengguna, kelengkapanProfil, muatanProfil, type IsianProfil } from "@/lib/profil";
import type { Pengguna } from "@/lib/types";

function Formulir({ saya }: { saya: Pengguna }) {
  const qc = useQueryClient();
  const f = useForm<IsianProfil>({ defaultValues: isianDariPengguna(saya) });
  const [info, setInfo] = useState<string | null>(null);
  const [galat, setGalat] = useState<unknown>(null);

  useEffect(() => {
    f.reset(isianDariPengguna(saya));
  }, [saya, f]);

  async function simpan(v: IsianProfil) {
    setInfo(null);
    setGalat(null);
    try {
      await kirim("/me/profil", "PUT", muatanProfil(v));
      await Promise.all([qc.invalidateQueries({ queryKey: kunci.saya }), qc.invalidateQueries({ queryKey: ["rekomendasi"] })]);
      setInfo("Profil tersimpan. Hitung ulang rekomendasi untuk memakai data terbaru.");
    } catch (e) {
      setGalat(e);
    }
  }
  const r = f.register;
  const kel = kelengkapanProfil(saya);

  return (
    <form onSubmit={f.handleSubmit(simpan)} className="grid gap-6 lg:grid-cols-3" noValidate>
      <div className="space-y-6 lg:col-span-2">
        <Kartu>
          <h2 className="mb-4 text-lg font-bold text-navy">Data akademik</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            <Medan label="Kampus">
              <Masukan {...r("kampus")} />
            </Medan>
            <Medan label="Jenis kampus">
              <Pilihan {...r("jenis_kampus")}>
                <option value="">Pilih</option>
                <option value="negeri">Negeri</option>
                <option value="swasta">Swasta</option>
              </Pilihan>
            </Medan>
            <Medan label="Program studi">
              <Masukan {...r("program_studi")} />
            </Medan>
            <Medan label="Jenjang">
              <Pilihan {...r("jenjang")}>
                <option value="">Pilih</option>
                {["D3", "D4", "S1", "S2", "S3"].map((j) => (
                  <option key={j}>{j}</option>
                ))}
              </Pilihan>
            </Medan>
            <Medan label="Semester">
              <Masukan type="number" min={1} max={14} {...r("semester")} />
            </Medan>
            <Medan label="IPK">
              <Masukan type="number" step="0.01" min={0} max={4} {...r("ipk")} />
            </Medan>
            <Medan label="IPS terakhir">
              <Masukan type="number" step="0.01" min={0} max={4} {...r("ips_terakhir")} />
            </Medan>
            <Medan label="Skor TOEFL">
              <Masukan type="number" {...r("toefl")} />
            </Medan>
            <Medan label="Skor IELTS">
              <Masukan type="number" step="0.5" {...r("ielts")} />
            </Medan>
          </div>
        </Kartu>
        <Kartu>
          <h2 className="mb-4 text-lg font-bold text-navy">Data pribadi dan minat</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            <Medan label="Nama lengkap">
              <Masukan {...r("nama")} />
            </Medan>
            <Medan label="Tanggal lahir">
              <Masukan type="date" {...r("tanggal_lahir")} />
            </Medan>
            <Medan label="Kota domisili">
              <Masukan {...r("kota_domisili")} />
            </Medan>
            <Medan label="Kewarganegaraan">
              <Masukan {...r("kewarganegaraan")} />
            </Medan>
            <Medan label="Penghasilan orang tua per bulan (Rp)">
              <Masukan type="number" min={0} {...r("penghasilan_orang_tua")} />
            </Medan>
            <Medan label="Minat (pisahkan dengan koma)">
              <Masukan placeholder="riset, teknologi, kesehatan" {...r("minat")} />
            </Medan>
          </div>
          <p className="mt-3 text-xs text-muted">Nama dan tanggal lahir tidak dikirim ke layanan AI.</p>
        </Kartu>
        <Kartu>
          <h2 className="mb-1 text-lg font-bold text-navy">Profil tambahan</h2>
          <p className="mb-4 text-sm text-muted">
            Opsional. Dipakai untuk menemukan beasiswa khusus (misalnya untuk penyandang disabilitas atau mahasiswa kurang mampu).
            Data ini tidak dikirim ke layanan AI dan tidak dipakai untuk menolak beasiswa.
          </p>
          <fieldset className="grid gap-2 sm:grid-cols-2">
            <legend className="sr-only">Kondisi khusus</legend>
            {PILIHAN_KONDISI.map(([nilai, label]) => (
              <label key={nilai} className="flex items-center gap-2 text-sm text-ink">
                <input type="checkbox" value={nilai} {...f.register("kondisi_khusus")} className="h-4 w-4 accent-primary" />
                {label}
              </label>
            ))}
          </fieldset>
          <div className="mt-4">
            <Medan label="Catatan khusus">
              <textarea
                rows={3}
                maxLength={1000}
                placeholder="Contoh: penerima KIP, tinggal di asrama, aktif di organisasi sosial"
                {...f.register("catatan_tambahan")}
                className="w-full rounded-lg border border-line bg-white px-3 py-2 text-sm"
              />
            </Medan>
          </div>
        </Kartu>
        <div className="flex flex-wrap items-center gap-3">
          <Tombol type="submit" disabled={f.formState.isSubmitting}>
            {f.formState.isSubmitting ? "Menyimpan" : "Simpan profil"}
          </Tombol>
          {info && (
            <p role="status" className="text-sm text-ok">
              {info}
            </p>
          )}
          {galat != null && (
            <p role="alert" className="text-sm text-danger">
              {pesanGalat(galat).pesan}
            </p>
          )}
        </div>
      </div>
      <div className="space-y-6">
        <Kartu>
          <h2 className="mb-3 text-lg font-bold text-navy">Kelengkapan profil</h2>
          <BarProgres nilai={kel.nilai} label="Kelengkapan profil" />
          <p className="mt-2 text-sm text-ink">{kel.nilai}% terisi</p>
          {kel.kosong.length > 0 && <p className="mt-2 text-xs text-muted">Belum diisi: {kel.kosong.join(", ")}.</p>}
        </Kartu>
        <Kartu>
          <h2 className="mb-2 text-lg font-bold text-navy">Isi dari dokumen</h2>
          <p className="text-sm text-ink">Unggah CV atau sertifikat agar IPK, semester, dan skor bahasa terisi otomatis.</p>
          <Link href="/dokumen" className="mt-3 inline-block text-sm font-semibold text-primary underline">
            Buka Dokumen Saya
          </Link>
        </Kartu>
      </div>
    </form>
  );
}

export default function ProfilSaya() {
  const saya = useSaya().data;
  return (
    <div>
      <JudulHalaman judul="Profil Saya" deskripsi="Data ini dipakai Mesin Rekomendasi untuk menilai syarat beasiswa." />
      {saya && <Formulir saya={saya} />}
      {saya && (
        <div className="mt-6 max-w-4xl">
          <ProfilLanjutanKartu key={JSON.stringify(saya.profil_lanjutan ?? {})} saya={saya} />
        </div>
      )}
    </div>
  );
}

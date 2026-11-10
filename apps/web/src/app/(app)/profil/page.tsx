"use client";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useEffect, useState, type ReactNode } from "react";
import { useForm, type Resolver } from "react-hook-form";
import { ProfilLanjutanKartu } from "@/components/ProfilLanjutan";
import { pesanGalat } from "@/components/state";
import { BarProgres, JudulHalaman, Kartu, Masukan, Medan, Pilihan, Tombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { kunci, useSaya, useWilayah } from "@/lib/hooks";
import {
  NEGARA_ASAL,
  PILIHAN_KONDISI,
  galatProfil,
  isianDariPengguna,
  kelengkapanProfil,
  muatanProfil,
  type IsianProfil,
} from "@/lib/profil";
import type { Pengguna } from "@/lib/types";

const resolver: Resolver<IsianProfil> = async (values) => {
  const g = galatProfil(values);
  const errors = Object.fromEntries(Object.entries(g).map(([k, pesan]) => [k, { type: "validate", message: pesan }]));
  return Object.keys(errors).length ? { values: {}, errors } : { values, errors: {} };
};

function Bagian({ id, judul, deskripsi, children }: { id: string; judul: string; deskripsi?: string; children: ReactNode }) {
  return (
    <Kartu>
      <h2 id={id} className="flex items-center gap-2.5 text-lg font-bold text-navy">
        <span aria-hidden className="h-5 w-1 rounded-full bg-gold" />
        {judul}
      </h2>
      {deskripsi && <p className="mt-1 text-sm text-muted">{deskripsi}</p>}
      <div className="mt-4">{children}</div>
    </Kartu>
  );
}

function Formulir({ saya }: { saya: Pengguna }) {
  const qc = useQueryClient();
  const wilayah = useWilayah().data;
  const f = useForm<IsianProfil>({ defaultValues: isianDariPengguna(saya), resolver, mode: "onBlur" });
  const [tersimpanPada, setTersimpanPada] = useState<string | null>(null);
  const [galat, setGalat] = useState<unknown>(null);

  useEffect(() => {
    f.reset(isianDariPengguna(saya));
  }, [saya, f]);

  async function simpan(v: IsianProfil) {
    setGalat(null);
    try {
      await kirim("/me/profil", "PUT", muatanProfil(v));
      await Promise.all([qc.invalidateQueries({ queryKey: kunci.saya }), qc.invalidateQueries({ queryKey: ["rekomendasi"] })]);
      setTersimpanPada(new Date().toLocaleTimeString("id-ID", { hour: "2-digit", minute: "2-digit" }));
    } catch (e) {
      setGalat(e);
    }
  }
  const r = f.register;
  const e = f.formState.errors;
  const pesan = (k: keyof IsianProfil) => e[k]?.message as string | undefined;
  const kel = kelengkapanProfil(saya);
  const negara = f.watch("negara_domisili");
  const diIndonesia = negara === NEGARA_ASAL;
  const daftarNegara = wilayah?.negara ?? [NEGARA_ASAL];
  const kotakNegara = !negara || daftarNegara.includes(negara) ? daftarNegara : [negara, ...daftarNegara];
  const berubah = f.formState.isDirty;

  return (
    <form onSubmit={f.handleSubmit(simpan)} noValidate className="space-y-6 pb-4">
      <Kartu>
        <div className="grid gap-5 md:grid-cols-3 md:items-center">
          <div className="md:col-span-1">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">Profil</p>
            <p className="mt-1 text-lg font-bold text-navy">{saya.nama}</p>
            <p className="text-sm text-muted">{saya.email}</p>
          </div>
          <div className="md:col-span-2">
            <div className="mb-1 flex items-baseline justify-between">
              <h2 className="text-sm font-bold text-navy">Kelengkapan untuk rekomendasi</h2>
              <span className="text-sm font-semibold text-ink">{kel.nilai}%</span>
            </div>
            <BarProgres nilai={kel.nilai} label="Kelengkapan profil" />
            {kel.kosong.length > 0 ? (
              <p className="mt-2 text-xs text-muted">Belum diisi: {kel.kosong.join(", ")}.</p>
            ) : (
              <p className="mt-2 text-xs text-ok">Semua data utama sudah terisi.</p>
            )}
            <p className="mt-1 text-xs text-muted">
              Tujuh data utama: jenjang, semester, IPK, jenis kampus, kota domisili, kewarganegaraan, dan tanggal lahir. Isian lain
              bersifat opsional.{" "}
              <Link href="/dokumen" className="font-semibold text-primary underline">
                Isi dari dokumen
              </Link>
            </p>
          </div>
        </div>
      </Kartu>

      <Bagian id="identitas" judul="Identitas" deskripsi="Nama dan tanggal lahir tidak dikirim ke layanan AI.">
        <div className="grid gap-4 sm:grid-cols-2">
          <Medan label="Nama lengkap" galat={pesan("nama")}>
            <Masukan {...r("nama")} />
          </Medan>
          <Medan label="Tanggal lahir" wajib galat={pesan("tanggal_lahir")} bantuan="Untuk syarat batas usia.">
            <Masukan type="date" {...r("tanggal_lahir")} />
          </Medan>
          <Medan label="Kewarganegaraan" wajib bantuan="Contoh: Indonesia.">
            <Masukan {...r("kewarganegaraan")} />
          </Medan>
        </div>
      </Bagian>

      <Bagian id="akademik" judul="Akademik">
        <div className="grid gap-4 sm:grid-cols-2">
          <Medan label="Kampus" wajib={false}>
            <Masukan {...r("kampus")} />
          </Medan>
          <Medan label="Jenis kampus" wajib>
            <Pilihan {...r("jenis_kampus")}>
              <option value="">Pilih</option>
              <option value="negeri">Negeri</option>
              <option value="swasta">Swasta</option>
            </Pilihan>
          </Medan>
          <Medan label="Program studi" wajib={false}>
            <Masukan {...r("program_studi")} />
          </Medan>
          <Medan label="Jenjang" wajib>
            <Pilihan {...r("jenjang")}>
              <option value="">Pilih</option>
              {["D3", "D4", "S1", "S2", "S3"].map((j) => (
                <option key={j}>{j}</option>
              ))}
            </Pilihan>
          </Medan>
          <Medan label="Semester" wajib galat={pesan("semester")}>
            <Masukan type="number" min={1} max={14} {...r("semester")} />
          </Medan>
          <Medan label="IPK" wajib galat={pesan("ipk")}>
            <Masukan type="number" step="0.01" min={0} max={4} {...r("ipk")} />
          </Medan>
          <Medan label="IPS terakhir" wajib={false} galat={pesan("ips_terakhir")}>
            <Masukan type="number" step="0.01" min={0} max={4} {...r("ips_terakhir")} />
          </Medan>
        </div>
      </Bagian>

      <Bagian id="bahasa" judul="Bahasa" deskripsi="Opsional. Dipakai untuk beasiswa yang mensyaratkan sertifikat bahasa.">
        <div className="grid gap-4 sm:grid-cols-2">
          <Medan label="Skor TOEFL" wajib={false} galat={pesan("toefl")}>
            <Masukan type="number" {...r("toefl")} />
          </Medan>
          <Medan label="Skor IELTS" wajib={false} galat={pesan("ielts")}>
            <Masukan type="number" step="0.5" {...r("ielts")} />
          </Medan>
        </div>
      </Bagian>

      <Bagian
        id="domisili"
        judul="Domisili"
        deskripsi="Dipakai memeriksa syarat domisili beasiswa pada tingkat negara, provinsi, atau kota."
      >
        <div className="grid gap-4 sm:grid-cols-3">
          <Medan label="Negara" wajib>
            <Pilihan
              {...r("negara_domisili", {
                onChange: (ev) => {
                  if (ev.target.value !== NEGARA_ASAL) f.setValue("provinsi_domisili", "", { shouldDirty: true });
                },
              })}
            >
              {kotakNegara.map((n) => (
                <option key={n}>{n}</option>
              ))}
            </Pilihan>
          </Medan>
          {diIndonesia && (
            <Medan label="Provinsi" wajib>
              <Pilihan {...r("provinsi_domisili")}>
                <option value="">Pilih provinsi</option>
                {(wilayah?.provinsi ?? []).map((p) => (
                  <option key={p}>{p}</option>
                ))}
              </Pilihan>
            </Medan>
          )}
          <Medan label="Kota atau kabupaten" wajib bantuan="Contoh: Malang.">
            <Masukan {...r("kota_domisili")} />
          </Medan>
        </div>
      </Bagian>

      <Bagian id="ekonomi" judul="Ekonomi dan kondisi khusus" deskripsi="Opsional. Tidak dikirim ke layanan AI dan tidak dipakai untuk menolak beasiswa.">
        <div className="grid gap-4 sm:grid-cols-2">
          <Medan label="Penghasilan orang tua per bulan (Rp)" wajib={false} galat={pesan("penghasilan_orang_tua")}>
            <Masukan type="number" min={0} {...r("penghasilan_orang_tua")} />
          </Medan>
        </div>
        <fieldset className="mt-4 grid gap-2 sm:grid-cols-2">
          <legend className="sr-only">Kondisi khusus</legend>
          {PILIHAN_KONDISI.map(([nilai, label]) => (
            <label key={nilai} className="flex items-center gap-2 text-sm text-ink">
              <input type="checkbox" value={nilai} {...r("kondisi_khusus")} className="h-5 w-5 accent-primary" />
              {label}
            </label>
          ))}
        </fieldset>
      </Bagian>

      <Bagian id="minat" judul="Minat dan catatan" deskripsi="Opsional. Membantu mengurutkan beasiswa yang sesuai bidang Anda.">
        <div className="space-y-4">
          <Medan label="Minat (pisahkan dengan koma)" wajib={false}>
            <Masukan placeholder="riset, teknologi, kesehatan" {...r("minat")} />
          </Medan>
          <Medan label="Catatan khusus" wajib={false}>
            <textarea
              rows={3}
              maxLength={1000}
              placeholder="Contoh: penerima KIP, tinggal di asrama, aktif di organisasi sosial"
              {...r("catatan_tambahan")}
              className="w-full rounded-kontrol border border-line bg-card px-3.5 py-2.5 text-sm text-navy placeholder:text-muted focus:border-primary"
            />
          </Medan>
        </div>
      </Bagian>

      <div className="sticky bottom-0 z-10 -mx-1 flex flex-wrap items-center gap-3 rounded-kartu border border-c4/60 bg-card/95 px-4 py-3 shadow-kartu backdrop-blur">
        <Tombol type="submit" disabled={f.formState.isSubmitting}>
          {f.formState.isSubmitting ? "Menyimpan" : "Simpan profil"}
        </Tombol>
        <p role="status" className="text-sm">
          {galat != null ? (
            <span role="alert" className="text-danger">
              {pesanGalat(galat).pesan}
            </span>
          ) : Object.keys(e).length > 0 ? (
            <span className="text-danger">Periksa isian yang ditandai sebelum menyimpan.</span>
          ) : berubah ? (
            <span className="text-muted">Ada perubahan yang belum disimpan.</span>
          ) : tersimpanPada ? (
            <span className="text-ok">Tersimpan pukul {tersimpanPada}. Hitung ulang rekomendasi untuk memakai data terbaru.</span>
          ) : (
            <span className="text-muted">Semua perubahan tersimpan.</span>
          )}
        </p>
      </div>
    </form>
  );
}

export default function ProfilSaya() {
  const saya = useSaya().data;
  return (
    <div className="halaman-masuk max-w-4xl">
      <JudulHalaman judul="Profil Saya" deskripsi="Data ini dipakai Mesin Rekomendasi untuk menilai syarat beasiswa." />
      {saya && <Formulir saya={saya} />}
      {saya && (
        <div className="mt-6">
          <ProfilLanjutanKartu key={JSON.stringify(saya.profil_lanjutan ?? {})} saya={saya} />
        </div>
      )}
    </div>
  );
}

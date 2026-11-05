"use client";
import { useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useState } from "react";
import { pesanGalat } from "@/components/state";
import { Kartu, Masukan, Medan, Pilihan, Tombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { kunci } from "@/lib/hooks";
import type { Pengguna, ProfilLanjutan } from "@/lib/types";

type Baris = Record<string, string>;
type Kolom = { kunci: string; label: string; pilihan?: string[]; angka?: boolean; lebar?: string };

const TINGKAT = ["sekolah", "kota", "provinsi", "nasional", "internasional"];
const JENJANG = ["D3", "D4", "S1", "S2", "S3"];

const DAFTAR: { kunci: "organisasi" | "prestasi" | "sertifikat" | "pengalaman"; judul: string; kolom: Kolom[] }[] = [
  {
    kunci: "organisasi",
    judul: "Organisasi",
    kolom: [
      { kunci: "nama", label: "Nama organisasi", lebar: "sm:col-span-5" },
      { kunci: "jabatan", label: "Jabatan", lebar: "sm:col-span-4" },
      { kunci: "tahun", label: "Tahun", angka: true, lebar: "sm:col-span-2" },
    ],
  },
  {
    kunci: "prestasi",
    judul: "Prestasi",
    kolom: [
      { kunci: "nama", label: "Nama prestasi", lebar: "sm:col-span-5" },
      { kunci: "tingkat", label: "Tingkat", pilihan: TINGKAT, lebar: "sm:col-span-4" },
      { kunci: "tahun", label: "Tahun", angka: true, lebar: "sm:col-span-2" },
    ],
  },
  {
    kunci: "sertifikat",
    judul: "Sertifikat",
    kolom: [
      { kunci: "nama", label: "Nama sertifikat", lebar: "sm:col-span-5" },
      { kunci: "penerbit", label: "Penerbit", lebar: "sm:col-span-4" },
      { kunci: "tahun", label: "Tahun", angka: true, lebar: "sm:col-span-2" },
    ],
  },
  {
    kunci: "pengalaman",
    judul: "Pengalaman kerja, magang, atau relawan",
    kolom: [
      { kunci: "nama", label: "Tempat atau kegiatan", lebar: "sm:col-span-5" },
      { kunci: "peran", label: "Peran", lebar: "sm:col-span-4" },
      { kunci: "tahun", label: "Tahun", angka: true, lebar: "sm:col-span-2" },
    ],
  },
];

const daftarKeBaris = (v: unknown): Baris[] =>
  (Array.isArray(v) ? v : []).map((x) => Object.fromEntries(Object.entries(x as object).map(([k, n]) => [k, String(n ?? "")])));

const barisKeDaftar = (baris: Baris[]) =>
  baris
    .filter((b) => (b.nama ?? "").trim() !== "")
    .map((b) => {
      const o: Record<string, string | number> = {};
      for (const [k, v] of Object.entries(b)) {
        const t = v.trim();
        if (t === "") continue;
        o[k] = k === "tahun" ? Number(t) : t;
      }
      return o;
    });

const pisah = (t: string) => t.split(",").map((x) => x.trim()).filter(Boolean);

export function ProfilLanjutanKartu({ saya }: { saya: Pengguna }) {
  const qc = useQueryClient();
  const awal: ProfilLanjutan = saya.profil_lanjutan ?? {};
  const [skalar, setSkalar] = useState({
    provinsi_asal: awal.provinsi_asal ?? "",
    kota_asal: awal.kota_asal ?? "",
    sekolah_asal: awal.sekolah_asal ?? "",
    jenis_sekolah: awal.jenis_sekolah ?? "",
    jurusan_sekolah: awal.jurusan_sekolah ?? "",
    tahun_lulus: awal.tahun_lulus ? String(awal.tahun_lulus) : "",
    fakultas: awal.fakultas ?? "",
  });
  const [daftar, setDaftar] = useState<Record<string, Baris[]>>({
    organisasi: daftarKeBaris(awal.organisasi),
    prestasi: daftarKeBaris(awal.prestasi),
    sertifikat: daftarKeBaris(awal.sertifikat),
    pengalaman: daftarKeBaris(awal.pengalaman),
  });
  const [keahlian, setKeahlian] = useState((awal.keahlian ?? []).join(", "));
  const [jenjang, setJenjang] = useState<string[]>(awal.target_studi?.jenjang ?? []);
  const [negara, setNegara] = useState((awal.target_studi?.negara ?? []).join(", "));
  const [bidang, setBidang] = useState((awal.target_studi?.bidang ?? []).join(", "));
  const [info, setInfo] = useState<string | null>(null);
  const [galat, setGalat] = useState<unknown>(null);
  const [sibuk, setSibuk] = useState(false);

  const ubahBaris = (k: string, i: number, kolom: string, nilai: string) =>
    setDaftar((d) => ({ ...d, [k]: d[k].map((b, j) => (j === i ? { ...b, [kolom]: nilai } : b)) }));

  async function simpan() {
    setSibuk(true);
    setInfo(null);
    setGalat(null);
    const teks = (v: string) => (v.trim() === "" ? null : v.trim());
    const muatan: ProfilLanjutan = {
      provinsi_asal: teks(skalar.provinsi_asal),
      kota_asal: teks(skalar.kota_asal),
      sekolah_asal: teks(skalar.sekolah_asal),
      jenis_sekolah: (teks(skalar.jenis_sekolah) as ProfilLanjutan["jenis_sekolah"]) ?? null,
      jurusan_sekolah: teks(skalar.jurusan_sekolah),
      tahun_lulus: skalar.tahun_lulus.trim() === "" ? null : Number(skalar.tahun_lulus),
      fakultas: teks(skalar.fakultas),
      organisasi: barisKeDaftar(daftar.organisasi),
      prestasi: barisKeDaftar(daftar.prestasi),
      sertifikat: barisKeDaftar(daftar.sertifikat),
      pengalaman: barisKeDaftar(daftar.pengalaman),
      keahlian: pisah(keahlian),
      target_studi: { jenjang, negara: pisah(negara), bidang: pisah(bidang) },
    };
    try {
      await kirim("/me/profil", "PUT", { profil_lanjutan: muatan });
      await Promise.all([qc.invalidateQueries({ queryKey: kunci.saya }), qc.invalidateQueries({ queryKey: ["rekomendasi"] })]);
      setInfo("Profil lanjutan tersimpan. Hitung ulang rekomendasi untuk memakainya.");
    } catch (e) {
      setGalat(e);
    } finally {
      setSibuk(false);
    }
  }

  return (
    <Kartu>
      <h2 className="mb-1 text-lg font-bold text-navy">Profil lanjutan</h2>
      <p className="mb-4 text-sm text-muted">
        Opsional, makin lengkap makin terarah. Isi manual di sini atau{" "}
        <Link href="/dokumen" className="font-semibold text-primary underline">
          unggah CV dan sertifikat
        </Link>{" "}
        lalu terapkan ke profil agar AI mengisinya. Data ini tidak mengurangi peluang dan tidak dipakai untuk menolak beasiswa.
      </p>

      <h3 className="mb-2 text-sm font-semibold text-navy">Asal daerah dan sekolah</h3>
      <div className="grid gap-4 sm:grid-cols-2">
        <Medan label="Provinsi asal">
          <Masukan value={skalar.provinsi_asal} onChange={(e) => setSkalar({ ...skalar, provinsi_asal: e.target.value })} />
        </Medan>
        <Medan label="Kota atau kabupaten asal">
          <Masukan value={skalar.kota_asal} onChange={(e) => setSkalar({ ...skalar, kota_asal: e.target.value })} />
        </Medan>
        <Medan label="Sekolah asal">
          <Masukan value={skalar.sekolah_asal} onChange={(e) => setSkalar({ ...skalar, sekolah_asal: e.target.value })} />
        </Medan>
        <Medan label="Jenis sekolah">
          <Pilihan value={skalar.jenis_sekolah} onChange={(e) => setSkalar({ ...skalar, jenis_sekolah: e.target.value })}>
            <option value="">Pilih</option>
            {["SMA", "SMK", "MA", "Pesantren", "Lainnya"].map((x) => (
              <option key={x}>{x}</option>
            ))}
          </Pilihan>
        </Medan>
        <Medan label="Jurusan di sekolah">
          <Masukan value={skalar.jurusan_sekolah} onChange={(e) => setSkalar({ ...skalar, jurusan_sekolah: e.target.value })} />
        </Medan>
        <Medan label="Tahun lulus">
          <Masukan type="number" value={skalar.tahun_lulus} onChange={(e) => setSkalar({ ...skalar, tahun_lulus: e.target.value })} />
        </Medan>
        <Medan label="Fakultas">
          <Masukan value={skalar.fakultas} onChange={(e) => setSkalar({ ...skalar, fakultas: e.target.value })} />
        </Medan>
      </div>

      {DAFTAR.map((d) => (
        <div key={d.kunci} className="mt-6">
          <div className="mb-2 flex items-center justify-between">
            <h3 className="text-sm font-semibold text-navy">{d.judul}</h3>
            <button
              type="button"
              onClick={() => setDaftar((x) => ({ ...x, [d.kunci]: [...x[d.kunci], {}] }))}
              className="text-sm font-semibold text-primary underline"
            >
              Tambah
            </button>
          </div>
          {daftar[d.kunci].length === 0 && <p className="text-xs text-muted">Belum ada. Pilih Tambah untuk mengisi.</p>}
          <div className="space-y-2">
            {daftar[d.kunci].map((b, i) => (
              <div key={i} className="grid items-end gap-2 sm:grid-cols-12">
                {d.kolom.map((k) => (
                  <div key={k.kunci} className={k.lebar}>
                    {k.pilihan ? (
                      <Pilihan aria-label={k.label} value={b[k.kunci] ?? ""} onChange={(e) => ubahBaris(d.kunci, i, k.kunci, e.target.value)}>
                        <option value="">{k.label}</option>
                        {k.pilihan.map((o) => (
                          <option key={o}>{o}</option>
                        ))}
                      </Pilihan>
                    ) : (
                      <Masukan
                        aria-label={k.label}
                        placeholder={k.label}
                        type={k.angka ? "number" : "text"}
                        value={b[k.kunci] ?? ""}
                        onChange={(e) => ubahBaris(d.kunci, i, k.kunci, e.target.value)}
                      />
                    )}
                  </div>
                ))}
                <button
                  type="button"
                  onClick={() => setDaftar((x) => ({ ...x, [d.kunci]: x[d.kunci].filter((_, j) => j !== i) }))}
                  className="text-sm text-danger underline sm:col-span-1"
                  aria-label={`Hapus baris ${i + 1} ${d.judul}`}
                >
                  Hapus
                </button>
              </div>
            ))}
          </div>
        </div>
      ))}

      <div className="mt-6 grid gap-4">
        <Medan label="Keahlian (pisahkan dengan koma)">
          <Masukan placeholder="Python, analisis data, public speaking" value={keahlian} onChange={(e) => setKeahlian(e.target.value)} />
        </Medan>
        <h3 className="text-sm font-semibold text-navy">Target studi dan beasiswa</h3>
        <fieldset className="flex flex-wrap gap-4">
          <legend className="sr-only">Jenjang yang dituju</legend>
          {JENJANG.map((j) => (
            <label key={j} className="flex items-center gap-2 text-sm text-ink">
              <input
                type="checkbox"
                checked={jenjang.includes(j)}
                onChange={(e) => setJenjang((x) => (e.target.checked ? [...x, j] : x.filter((y) => y !== j)))}
                className="h-4 w-4 accent-primary"
              />
              {j}
            </label>
          ))}
        </fieldset>
        <Medan label="Negara tujuan (pisahkan dengan koma, kosongkan bila dalam negeri)">
          <Masukan placeholder="Jepang, Korea Selatan, Australia" value={negara} onChange={(e) => setNegara(e.target.value)} />
        </Medan>
        <Medan label="Bidang yang diminati (pisahkan dengan koma)">
          <Masukan placeholder="kecerdasan buatan, kesehatan masyarakat" value={bidang} onChange={(e) => setBidang(e.target.value)} />
        </Medan>
      </div>

      <div className="mt-6 flex flex-wrap items-center gap-3">
        <Tombol onClick={simpan} disabled={sibuk}>
          {sibuk ? "Menyimpan" : "Simpan profil lanjutan"}
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
    </Kartu>
  );
}

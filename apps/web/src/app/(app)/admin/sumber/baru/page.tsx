"use client";
import { useRouter } from "next/navigation";
import { FormSumber } from "@/components/FormSumber";
import { JudulHalaman } from "@/components/ui";
import { kirim } from "@/lib/api";
import { useAksi } from "@/lib/hooks";

export default function TambahSumber() {
  const router = useRouter();
  const tambah = useAksi(
    (i: { nama: string; url: string; jenis: string; negara: string; jadwal: string; aktif: boolean }) =>
      kirim("/admin/sumber", "POST", { nama: i.nama.trim(), url: i.url.trim(), jenis: i.jenis, negara: i.negara.trim() || null, jadwal: i.jadwal.trim() || null, aktif: i.aktif }),
    ["admin", "sumber"],
    ["admin", "laporan"],
  );
  return (
    <div>
      <JudulHalaman judul="Tambah Sumber" deskripsi="Daftarkan laman resmi baru untuk dipantau." />
      <FormSumber onKirim={(i) => tambah.mutate(i, { onSuccess: () => router.push("/admin/sumber") })} sibuk={tambah.isPending} galat={tambah.error} />
    </div>
  );
}

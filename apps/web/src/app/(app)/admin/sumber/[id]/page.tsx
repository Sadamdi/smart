"use client";
import { useParams, useRouter } from "next/navigation";
import { FormSumber } from "@/components/FormSumber";
import { KosongState, Tampil } from "@/components/state";
import { JudulHalaman, TautanTombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { useAksi, useSumber } from "@/lib/hooks";

export default function EditSumber() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const kueri = useSumber();
  const ubah = useAksi(
    (i: { nama: string; jenis: string; negara: string; jadwal: string; aktif: boolean }) =>
      kirim(`/admin/sumber/${id}`, "PUT", { nama: i.nama.trim(), jenis: i.jenis, negara: i.negara.trim() || null, jadwal: i.jadwal.trim() || null, aktif: i.aktif }),
    ["admin", "sumber"],
    ["admin", "laporan"],
  );
  return (
    <div>
      <JudulHalaman judul="Edit Sumber" />
      <Tampil kueri={kueri}>
        {(daftar) => {
          const s = daftar.find((x) => x.id === id);
          if (!s) return <KosongState judul="Sumber tidak ditemukan" aksi={<TautanTombol href="/admin/sumber">Kembali</TautanTombol>} />;
          return <FormSumber awal={s} edit onKirim={(i) => ubah.mutate(i, { onSuccess: () => router.push("/admin/sumber") })} sibuk={ubah.isPending} galat={ubah.error} />;
        }}
      </Tampil>
    </div>
  );
}

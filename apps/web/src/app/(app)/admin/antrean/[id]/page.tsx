"use client";
import { useQueryClient } from "@tanstack/react-query";
import { ExternalLink, Plus, Trash2 } from "lucide-react";
import { useParams, useRouter } from "next/navigation";
import { useState } from "react";
import { Tampil, pesanGalat } from "@/components/state";
import { Kartu, Masukan, Medan, Pilihan, Tombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { LABEL_SYARAT, tanggalIndo } from "@/lib/format";
import { useAksi, useDetailAdmin } from "@/lib/hooks";
import { muatanPerbaikan, type IsianValidasi } from "@/lib/validasi";
import type { DetailAdmin } from "@/lib/types";

const JENJANG = ["D3", "D4", "S1", "S2", "S3"];

function Formulir({ d }: { d: DetailAdmin }) {
  const router = useRouter();
  const qc = useQueryClient();
  const [i, setI] = useState<IsianValidasi>({
    nama: d.nama,
    penyelenggara: d.penyelenggara ?? "",
    negara: d.negara ?? "",
    jenjang: (d.jenjang ?? []).filter((j) => JENJANG.includes(j)),
    tenggat: d.tenggat ?? "",
    tautan_resmi: d.tautan_resmi,
    manfaat: d.manfaat ?? "",
    persyaratan: (d.persyaratan ?? []).map((s) => ({ jenis: s.jenis, nilai: s.nilai_batas ? JSON.stringify(s.nilai_batas) : "", dapat_dikejar: s.dapat_dikejar })),
    berkas: (d.berkas_wajib ?? []).map((b) => b.nama_berkas).join("\n"),
  });
  const [alasan, setAlasan] = useState("");
  const [galatLokal, setGalatLokal] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);

  const selesai = () => {
    qc.invalidateQueries({ queryKey: ["admin"] });
    router.push("/admin/antrean");
  };
  const simpan = useAksi((m: ReturnType<typeof muatanPerbaikan>) => kirim(`/admin/beasiswa/${d.id}`, "PUT", m), ["admin", "beasiswa", d.id]);
  const terbit = useAksi(() => kirim(`/admin/beasiswa/${d.id}/terbitkan`, "POST"));
  const tolak = useAksi(() => kirim(`/admin/beasiswa/${d.id}/tolak`, "POST", { alasan }));
  const validasiAi = useAksi(() => kirim(`/admin/beasiswa/${d.id}/validasi-ai`, "POST"));

  function siapkan() {
    setGalatLokal(null);
    setInfo(null);
    try {
      return muatanPerbaikan(i);
    } catch (e) {
      setGalatLokal(e instanceof Error ? e.message : "Isian tidak valid");
      return null;
    }
  }
  const set = <K extends keyof IsianValidasi>(k: K, v: IsianValidasi[K]) => setI({ ...i, [k]: v });
  const galat = simpan.error ?? terbit.error ?? tolak.error ?? validasiAi.error;

  return (
    <div className="grid gap-6 lg:grid-cols-3">
      <div className="space-y-6 lg:col-span-2">
        <Kartu>
          <h2 className="mb-4 text-lg font-bold text-navy">Nilai terbaca sistem</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            <Medan label="Nama beasiswa">
              <Masukan value={i.nama} onChange={(e) => set("nama", e.target.value)} />
            </Medan>
            <Medan label="Penyelenggara">
              <Masukan value={i.penyelenggara} onChange={(e) => set("penyelenggara", e.target.value)} />
            </Medan>
            <Medan label="Negara">
              <Masukan value={i.negara} onChange={(e) => set("negara", e.target.value)} />
            </Medan>
            <Medan label="Tenggat">
              <Masukan type="date" value={i.tenggat} onChange={(e) => set("tenggat", e.target.value)} />
            </Medan>
            <div className="sm:col-span-2">
              <Medan label="Tautan resmi">
                <Masukan value={i.tautan_resmi} onChange={(e) => set("tautan_resmi", e.target.value)} />
              </Medan>
            </div>
          </div>
          <fieldset className="mt-4">
            <legend className="mb-1.5 text-[11px] font-semibold uppercase tracking-wide text-muted">Jenjang</legend>
            <div className="flex flex-wrap gap-4">
              {JENJANG.map((j) => (
                <label key={j} className="flex items-center gap-2 text-sm text-navy">
                  <input type="checkbox" className="h-4 w-4 accent-primary" checked={i.jenjang.includes(j)} onChange={(e) => set("jenjang", e.target.checked ? [...i.jenjang, j] : i.jenjang.filter((x) => x !== j))} />
                  {j}
                </label>
              ))}
            </div>
          </fieldset>
          <div className="mt-4">
            <Medan label="Manfaat">
              <textarea rows={4} value={i.manfaat} onChange={(e) => set("manfaat", e.target.value)} className="w-full rounded-lg border border-outline bg-white px-3.5 py-2.5 text-sm text-navy" />
            </Medan>
          </div>
        </Kartu>

        <Kartu>
          <h2 className="mb-1 text-lg font-bold text-navy">Persyaratan</h2>
          <p className="mb-4 text-xs text-muted">Nilai batas ditulis sebagai JSON, misalnya {`{"nilai": 3.0}`}. Kosongkan bila tidak ada.</p>
          <div className="space-y-3">
            {i.persyaratan.map((s, n) => (
              <div key={n} className="grid gap-2 sm:grid-cols-[1fr_1.4fr_auto_auto]">
                <Pilihan aria-label="Jenis syarat" value={s.jenis} onChange={(e) => set("persyaratan", i.persyaratan.map((x, k) => (k === n ? { ...x, jenis: e.target.value } : x)))}>
                  {Object.entries(LABEL_SYARAT).map(([k, v]) => (
                    <option key={k} value={k}>
                      {v}
                    </option>
                  ))}
                </Pilihan>
                <Masukan aria-label="Nilai batas" value={s.nilai} onChange={(e) => set("persyaratan", i.persyaratan.map((x, k) => (k === n ? { ...x, nilai: e.target.value } : x)))} />
                <label className="flex items-center gap-2 text-sm text-navy">
                  <input type="checkbox" className="h-4 w-4 accent-primary" checked={s.dapat_dikejar} onChange={(e) => set("persyaratan", i.persyaratan.map((x, k) => (k === n ? { ...x, dapat_dikejar: e.target.checked } : x)))} />
                  Dapat dikejar
                </label>
                <button type="button" aria-label="Hapus syarat" onClick={() => set("persyaratan", i.persyaratan.filter((_, k) => k !== n))} className="rounded-full p-2 text-muted hover:bg-danger-soft hover:text-danger">
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            ))}
          </div>
          <Tombol varian="hantu" className="mt-3" onClick={() => set("persyaratan", [...i.persyaratan, { jenis: "lainnya", nilai: "", dapat_dikejar: false }])}>
            <Plus className="h-4 w-4" aria-hidden /> Tambah syarat
          </Tombol>
        </Kartu>

        <Kartu>
          <h2 className="mb-3 text-lg font-bold text-navy">Berkas wajib</h2>
          <Medan label="Satu berkas per baris">
            <textarea rows={4} value={i.berkas} onChange={(e) => set("berkas", e.target.value)} className="w-full rounded-lg border border-outline bg-white px-3.5 py-2.5 text-sm text-navy" />
          </Medan>
        </Kartu>
      </div>

      <div className="space-y-6">
        <Kartu>
          <h2 className="mb-2 text-lg font-bold text-navy">Sumber asal</h2>
          <p className="text-sm text-ink">
            Status: <span className="font-semibold text-navy">{d.status}</span>
          </p>
          <p className="text-xs text-muted">Terakhir diperiksa sumber: {tanggalIndo(d.tanggal_diperiksa)}</p>
          {d.alasan_ditandai && <p className="mt-3 rounded-xl bg-danger-soft px-3 py-2 text-sm text-[#8c1212]">{d.alasan_ditandai}</p>}
          <a href={d.tautan_resmi} target="_blank" rel="noopener noreferrer" className="mt-3 inline-flex items-center gap-1.5 text-sm font-semibold text-primary underline">
            Bandingkan dengan laman asal <ExternalLink className="h-4 w-4" aria-hidden />
          </a>
        </Kartu>

        <Kartu>
          <h2 className="mb-3 text-lg font-bold text-navy">Keputusan</h2>
          <div className="space-y-2">
            <Tombol
              varian="sekunder"
              className="w-full"
              disabled={simpan.isPending}
              onClick={() => {
                const m = siapkan();
                if (m) simpan.mutate(m, { onSuccess: () => setInfo("Perubahan disimpan.") });
              }}
            >
              Simpan perubahan
            </Tombol>
            <Tombol
              varian="sekunder"
              className="w-full"
              disabled={validasiAi.isPending}
              onClick={() => validasiAi.mutate(undefined, { onSuccess: selesai })}
            >
              {validasiAi.isPending ? "AI sedang membaca laman resmi..." : "Validasi dengan AI (otomatis)"}
            </Tombol>
            <Tombol
              className="w-full"
              disabled={terbit.isPending || simpan.isPending}
              onClick={() => {
                const m = siapkan();
                if (!m) return;
                simpan.mutate(m, { onSuccess: () => terbit.mutate(undefined, { onSuccess: selesai }) });
              }}
            >
              Simpan dan terbitkan
            </Tombol>
          </div>
          <div className="mt-5 border-t border-c4/60 pt-4">
            <Medan label="Alasan penolakan">
              <textarea rows={3} value={alasan} onChange={(e) => setAlasan(e.target.value)} className="w-full rounded-lg border border-outline bg-white px-3.5 py-2.5 text-sm text-navy" />
            </Medan>
            <Tombol varian="bahaya" className="mt-2 w-full" disabled={!alasan.trim() || tolak.isPending} onClick={() => tolak.mutate(undefined, { onSuccess: selesai })}>
              Tolak
            </Tombol>
          </div>
          {info && (
            <p role="status" className="mt-3 text-sm text-ok">
              {info}
            </p>
          )}
          {(galatLokal || galat) && (
            <p role="alert" className="mt-3 text-sm text-danger">
              {galatLokal ?? pesanGalat(galat).pesan}
            </p>
          )}
        </Kartu>
      </div>
    </div>
  );
}

export default function DetailValidasi() {
  const { id } = useParams<{ id: string }>();
  const kueri = useDetailAdmin(id);
  return (
    <div>
      <h1 className="mb-6 text-[28px] font-bold text-navy">Detail Validasi</h1>
      <Tampil kueri={kueri}>{(d) => <Formulir key={d.id + d.status} d={d} />}</Tampil>
    </div>
  );
}

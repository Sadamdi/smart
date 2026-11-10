"use client";
import { zodResolver } from "@hookform/resolvers/zod";
import { useQueryClient } from "@tanstack/react-query";
import { Monitor, Moon, Sun } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { pesanGalat } from "@/components/state";
import { useTema } from "@/components/Tema";
import { JudulHalaman, Kartu, Masukan, MasukanSandi, Medan, Tombol, cx } from "@/components/ui";
import type { PilihanTema } from "@/lib/tema";
import { kirim } from "@/lib/api";
import { kunci, useAksi, useSaya } from "@/lib/hooks";
import { tokenStore } from "@/lib/token";
import type { TokenOut } from "@/lib/types";

const skemaSandi = z
  .object({
    lama: z.string().min(1, "Kata sandi lama wajib diisi"),
    baru: z.string().min(8, "Kata sandi baru minimal 8 karakter").max(128),
    ulang: z.string(),
  })
  .refine((v) => v.baru === v.ulang, { path: ["ulang"], message: "Kata sandi tidak sama" });
type IsianSandi = z.infer<typeof skemaSandi>;

const OPSI_TEMA: { nilai: PilihanTema; label: string; deskripsi: string; ikon: typeof Sun }[] = [
  { nilai: "sistem", label: "Sistem", deskripsi: "Mengikuti pengaturan perangkat", ikon: Monitor },
  { nilai: "terang", label: "Terang", deskripsi: "Latar terang", ikon: Sun },
  { nilai: "gelap", label: "Gelap", deskripsi: "Latar gelap, nyaman di malam hari", ikon: Moon },
];

function Tampilan() {
  const { pilihan, terpakai, atur } = useTema();
  return (
    <Kartu>
      <h2 className="mb-1 text-lg font-bold text-navy">Tampilan</h2>
      <p className="mb-4 text-sm text-ink">
        Pilih tema aplikasi. Saat ini yang dipakai: <strong className="text-navy">{terpakai === "gelap" ? "gelap" : "terang"}</strong>. Pilihan disimpan di peramban ini.
      </p>
      <div role="radiogroup" aria-label="Tema" className="grid gap-3 sm:grid-cols-3">
        {OPSI_TEMA.map((o) => {
          const aktif = pilihan === o.nilai;
          return (
            <label
              key={o.nilai}
              className={cx(
                "flex min-h-11 cursor-pointer items-start gap-3 rounded-kontrol border p-3.5 transition-colors duration-150 has-[:focus-visible]:outline has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-offset-2 has-[:focus-visible]:outline-primary",
                aktif ? "border-fill bg-c2" : "border-c4 bg-card hover:bg-c1",
              )}
            >
              <input type="radio" name="tema" value={o.nilai} checked={aktif} onChange={() => atur(o.nilai)} className="sr-only" />
              <o.ikon className={cx("mt-0.5 h-5 w-5 shrink-0", aktif ? "text-primary" : "text-muted")} aria-hidden />
              <span>
                <span className="block text-sm font-bold text-navy">{o.label}</span>
                <span className="block text-xs text-muted">{o.deskripsi}</span>
              </span>
            </label>
          );
        })}
      </div>
    </Kartu>
  );
}

function GantiSandi() {
  const f = useForm<IsianSandi>({ resolver: zodResolver(skemaSandi) });
  const [info, setInfo] = useState<string | null>(null);
  const [galat, setGalat] = useState<unknown>(null);
  const e = f.formState.errors;
  return (
    <Kartu>
      <h2 className="mb-4 text-lg font-bold text-navy">Ganti kata sandi</h2>
      <form
        className="max-w-md space-y-4"
        noValidate
        onSubmit={f.handleSubmit(async (v) => {
          setInfo(null);
          setGalat(null);
          try {
            const r = await kirim<TokenOut>("/auth/ganti-kata-sandi", "POST", { kata_sandi_lama: v.lama, kata_sandi_baru: v.baru });
            tokenStore.simpan(r.data);
            f.reset();
            setInfo("Kata sandi diganti. Sesi di perangkat lain berakhir.");
          } catch (x) {
            setGalat(x);
          }
        })}
      >
        <Medan label="Kata sandi lama" galat={e.lama?.message}>
          <MasukanSandi autoComplete="current-password" {...f.register("lama")} />
        </Medan>
        <Medan label="Kata sandi baru" galat={e.baru?.message}>
          <MasukanSandi autoComplete="new-password" {...f.register("baru")} />
        </Medan>
        <Medan label="Ulangi kata sandi baru" galat={e.ulang?.message}>
          <MasukanSandi autoComplete="new-password" {...f.register("ulang")} />
        </Medan>
        <Tombol type="submit" disabled={f.formState.isSubmitting}>
          Ganti kata sandi
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
      </form>
    </Kartu>
  );
}

export default function Pengaturan() {
  const router = useRouter();
  const qc = useQueryClient();
  const saya = useSaya().data;
  const pref = useAksi((v: { email: boolean; push: boolean }) => kirim("/me/preferensi-notifikasi", "PUT", v), kunci.saya);
  const [galatEkspor, setGalatEkspor] = useState<string | null>(null);
  const [konfirmasi, setKonfirmasi] = useState("");
  const hapus = useAksi(() => kirim("/me", "DELETE"));

  const email = saya?.preferensi_notifikasi.email ?? false;
  const push = saya?.preferensi_notifikasi.push ?? true;

  async function ekspor() {
    setGalatEkspor(null);
    try {
      const r = await kirim<unknown>("/me/ekspor", "GET");
      const url = URL.createObjectURL(new Blob([JSON.stringify(r.data, null, 2)], { type: "application/json" }));
      const a = document.createElement("a");
      a.href = url;
      a.download = "data-smart-saya.json";
      a.click();
      URL.revokeObjectURL(url);
    } catch (x) {
      setGalatEkspor(pesanGalat(x).pesan);
    }
  }

  return (
    <div className="halaman-masuk space-y-6">
      <JudulHalaman judul="Pengaturan" deskripsi="Tampilan, pengingat, keamanan akun, dan data pribadi Anda." />
      <Tampilan />
      <Kartu>
        <h2 className="mb-1 text-lg font-bold text-navy">Preferensi pengingat</h2>
        <p className="mb-4 text-sm text-ink">Pilih kanal untuk pengingat tenggat beasiswa tersimpan.</p>
        <div className="space-y-3">
          {(
            [
              ["push", "Notifikasi di aplikasi", push],
              ["email", "Email", email],
            ] as const
          ).map(([k, label, nilai]) => (
            <label key={k} className="flex min-h-11 items-center gap-3 text-sm text-navy">
              <input
                type="checkbox"
                className="h-5 w-5 accent-primary"
                checked={nilai}
                disabled={pref.isPending || !saya}
                onChange={(e) => pref.mutate({ email: k === "email" ? e.target.checked : email, push: k === "push" ? e.target.checked : push })}
              />
              {label}
            </label>
          ))}
        </div>
        {pref.isError && (
          <p role="alert" className="mt-2 text-sm text-danger">
            {pesanGalat(pref.error).pesan}
          </p>
        )}
      </Kartu>

      <GantiSandi />

      <Kartu>
        <h2 className="mb-1 text-lg font-bold text-navy">Ekspor data</h2>
        <p className="mb-4 text-sm text-ink">Unduh salinan data akun dan aktivitas Anda dalam format JSON.</p>
        <Tombol varian="sekunder" onClick={ekspor}>
          Unduh data saya
        </Tombol>
        {galatEkspor && (
          <p role="alert" className="mt-2 text-sm text-danger">
            {galatEkspor}
          </p>
        )}
      </Kartu>

      <Kartu className="border-danger-soft">
        <h2 className="mb-1 text-lg font-bold text-danger">Hapus akun</h2>
        <p className="mb-4 text-sm text-ink">Akun dan seluruh data pribadi dihapus dan tidak dapat dipulihkan. Ketik HAPUS untuk melanjutkan.</p>
        <div className="flex max-w-md flex-col gap-3 sm:flex-row">
          <Masukan aria-label="Ketik HAPUS" value={konfirmasi} onChange={(e) => setKonfirmasi(e.target.value)} />
          <Tombol
            varian="bahaya"
            disabled={konfirmasi !== "HAPUS" || hapus.isPending}
            onClick={() =>
              hapus.mutate(undefined, {
                onSuccess: () => {
                  tokenStore.hapus();
                  qc.clear();
                  router.replace("/masuk");
                },
              })
            }
          >
            Hapus akun
          </Tombol>
        </div>
        {hapus.isError && (
          <p role="alert" className="mt-2 text-sm text-danger">
            {pesanGalat(hapus.error).pesan}
          </p>
        )}
      </Kartu>
    </div>
  );
}

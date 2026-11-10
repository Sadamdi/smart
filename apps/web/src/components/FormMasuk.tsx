"use client";
import { zodResolver } from "@hookform/resolvers/zod";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { ApiError } from "@/lib/api";
import { masuk } from "@/lib/auth";
import { Medan, Masukan, MasukanSandi, Tombol } from "./ui";

export const skemaMasuk = z.object({
  email: z.string().min(1, "Email wajib diisi").email("Format email tidak valid"),
  kata_sandi: z.string().min(1, "Kata sandi wajib diisi"),
});
type Nilai = z.infer<typeof skemaMasuk>;

export function FormMasuk({ onSelesai }: { onSelesai?: () => void }) {
  const router = useRouter();
  const [galat, setGalat] = useState<string | null>(null);
  const f = useForm<Nilai>({ resolver: zodResolver(skemaMasuk) });

  async function kirimForm(v: Nilai) {
    setGalat(null);
    try {
      await masuk(v.email, v.kata_sandi);
      onSelesai?.();
      router.replace("/");
    } catch (e) {
      setGalat(e instanceof ApiError ? e.message : "Gagal masuk. Coba lagi.");
    }
  }

  return (
    <form onSubmit={f.handleSubmit(kirimForm)} className="space-y-5" noValidate>
      <Medan label="Email" galat={f.formState.errors.email?.message}>
        <Masukan type="email" autoComplete="email" placeholder="nama@kampus.ac.id" {...f.register("email")} />
      </Medan>
      <Medan label="Kata sandi" galat={f.formState.errors.kata_sandi?.message}>
        <MasukanSandi autoComplete="current-password" {...f.register("kata_sandi")} />
      </Medan>
      {galat && (
        <p role="alert" className="rounded-lg bg-danger-soft px-3 py-2 text-sm text-danger-ink">
          {galat}
        </p>
      )}
      <Tombol type="submit" className="w-full" disabled={f.formState.isSubmitting}>
        {f.formState.isSubmitting ? "Memproses" : "Masuk"}
      </Tombol>
      <p className="text-center text-sm text-ink">
        Belum punya akun?{" "}
        <Link href="/daftar" className="font-semibold text-primary underline">
          Daftar
        </Link>
      </p>
    </form>
  );
}

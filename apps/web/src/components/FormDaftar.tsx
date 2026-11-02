"use client";
import { zodResolver } from "@hookform/resolvers/zod";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { ApiError } from "@/lib/api";
import { daftar } from "@/lib/auth";
import { Medan, Masukan, Tombol } from "./ui";

export const skemaDaftar = z
  .object({
    nama: z.string().trim().min(1, "Nama wajib diisi").max(200),
    email: z.string().min(1, "Email wajib diisi").email("Format email tidak valid"),
    kata_sandi: z.string().min(8, "Kata sandi minimal 8 karakter").max(128),
    ulang: z.string(),
  })
  .refine((v) => v.kata_sandi === v.ulang, { path: ["ulang"], message: "Kata sandi tidak sama" });
type Nilai = z.infer<typeof skemaDaftar>;

export function FormDaftar() {
  const router = useRouter();
  const [galat, setGalat] = useState<string | null>(null);
  const f = useForm<Nilai>({ resolver: zodResolver(skemaDaftar) });
  const e = f.formState.errors;

  async function kirimForm(v: Nilai) {
    setGalat(null);
    try {
      await daftar(v.nama, v.email, v.kata_sandi);
      router.replace("/profil");
    } catch (x) {
      setGalat(x instanceof ApiError ? x.message : "Pendaftaran gagal. Coba lagi.");
    }
  }

  return (
    <form onSubmit={f.handleSubmit(kirimForm)} className="space-y-5" noValidate>
      <Medan label="Nama lengkap" galat={e.nama?.message}>
        <Masukan autoComplete="name" {...f.register("nama")} />
      </Medan>
      <Medan label="Email" galat={e.email?.message}>
        <Masukan type="email" autoComplete="email" placeholder="nama@kampus.ac.id" {...f.register("email")} />
      </Medan>
      <Medan label="Kata sandi" galat={e.kata_sandi?.message}>
        <Masukan type="password" autoComplete="new-password" {...f.register("kata_sandi")} />
      </Medan>
      <Medan label="Ulangi kata sandi" galat={e.ulang?.message}>
        <Masukan type="password" autoComplete="new-password" {...f.register("ulang")} />
      </Medan>
      {galat && (
        <p role="alert" className="rounded-lg bg-danger-soft px-3 py-2 text-sm text-[#8c1212]">
          {galat}
        </p>
      )}
      <Tombol type="submit" className="w-full" disabled={f.formState.isSubmitting}>
        {f.formState.isSubmitting ? "Memproses" : "Buat akun"}
      </Tombol>
      <p className="text-center text-sm text-ink">
        Sudah punya akun?{" "}
        <Link href="/masuk" className="font-semibold text-primary underline">
          Masuk
        </Link>
      </p>
    </form>
  );
}

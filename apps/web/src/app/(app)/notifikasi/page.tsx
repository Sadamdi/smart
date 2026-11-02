"use client";
import { Bell, Check } from "lucide-react";
import Link from "next/link";
import { KosongState, Tampil } from "@/components/state";
import { JudulHalaman, Tombol, cx } from "@/components/ui";
import { kirim } from "@/lib/api";
import { kunci, useAksi, useNotifikasi } from "@/lib/hooks";
import { tanggalIndo } from "@/lib/format";

const JENIS: Record<string, string> = { tenggat: "Pengingat tenggat" };

export default function Notifikasi() {
  const kueri = useNotifikasi();
  const baca = useAksi((id: string) => kirim(`/notifikasi/${id}/baca`, "PUT"), kunci.notif);
  const semua = useAksi(() => kirim("/notifikasi/baca-semua", "PUT"), kunci.notif);
  const belum = kueri.data?.filter((n) => !n.dibaca).length ?? 0;

  return (
    <div>
      <JudulHalaman
        judul="Notifikasi"
        deskripsi="Pengingat tenggat beasiswa yang Anda simpan."
        aksi={
          <Tombol varian="sekunder" onClick={() => semua.mutate()} disabled={belum === 0 || semua.isPending}>
            <Check className="h-4 w-4" aria-hidden /> Tandai semua dibaca
          </Tombol>
        }
      />
      <Tampil kueri={kueri} kosong={<KosongState judul="Belum ada notifikasi" pesan="Pengingat muncul di sini saat tenggat beasiswa tersimpan mendekat." />}>
        {(daftar) => (
          <ul className="space-y-3">
            {[...daftar]
              .sort((a, b) => b.tanggal_acuan.localeCompare(a.tanggal_acuan))
              .map((n) => (
                <li key={n.id} className={cx("flex items-start gap-4 rounded-2xl border p-5 shadow-kartu", n.dibaca ? "border-c4/60 bg-white" : "border-primary-soft bg-c1")}>
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-c2 text-primary">
                    <Bell className="h-5 w-5" aria-hidden />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="text-[11px] font-semibold uppercase tracking-wide text-muted">
                      {JENIS[n.jenis] ?? n.jenis} | {tanggalIndo(n.tanggal_acuan)}
                    </p>
                    <p className="font-semibold text-navy">{n.judul}</p>
                    <p className="text-sm text-ink">{n.pesan}</p>
                    <Link href={`/beasiswa/${n.beasiswa_id}`} className="mt-1 inline-block text-sm font-semibold text-primary underline">
                      Lihat beasiswa
                    </Link>
                  </div>
                  {!n.dibaca && (
                    <Tombol varian="hantu" onClick={() => baca.mutate(n.id)} disabled={baca.isPending}>
                      Tandai dibaca
                    </Tombol>
                  )}
                </li>
              ))}
          </ul>
        )}
      </Tampil>
    </div>
  );
}

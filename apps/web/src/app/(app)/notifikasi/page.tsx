"use client";
import { Bell, BellOff, Check } from "lucide-react";
import Link from "next/link";
import { KosongState, Tampil } from "@/components/state";
import { JudulHalaman, Lencana, TautanTombol, Tombol, cx } from "@/components/ui";
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
    <div className="halaman-masuk">
      <JudulHalaman
        judul="Notifikasi"
        deskripsi="Pengingat tenggat beasiswa yang Anda simpan."
        aksi={
          <Tombol varian="sekunder" onClick={() => semua.mutate()} disabled={belum === 0 || semua.isPending}>
            <Check className="h-4 w-4" aria-hidden /> Tandai semua dibaca
          </Tombol>
        }
      />
      <Tampil kueri={kueri} kosong={<KosongState ikon={BellOff} judul="Belum ada notifikasi" pesan="Pengingat muncul di sini saat tenggat beasiswa tersimpan mendekat. Simpan beasiswa agar kamu mendapat pengingatnya." aksi={<TautanTombol href="/jelajah">Jelajah beasiswa</TautanTombol>} />}>
        {(daftar) => (
          <ul className="space-y-3">
            {[...daftar]
              .sort((a, b) => b.tanggal_acuan.localeCompare(a.tanggal_acuan))
              .map((n) => (
                <li key={n.id} className={cx("flex flex-wrap items-start gap-x-4 gap-y-3 rounded-kartu border p-4 shadow-kartu sm:p-5", n.dibaca ? "border-c4/60 bg-card" : "border-primary-soft bg-c1")}>
                  <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[14px] bg-c2 text-primary">
                    <Bell className="h-5 w-5" aria-hidden />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="flex flex-wrap items-center gap-2 text-[11px] font-bold uppercase tracking-wide text-muted">
                      {JENIS[n.jenis] ?? n.jenis} <span aria-hidden>·</span> {tanggalIndo(n.tanggal_acuan)}
                      {!n.dibaca && <Lencana nada="info" className="normal-case tracking-normal">Baru</Lencana>}
                    </p>
                    <p className="font-bold text-navy">{n.judul}</p>
                    <p className="text-sm text-ink">{n.pesan}</p>
                    <Link href={`/beasiswa/${n.beasiswa_id}`} className="mt-1 inline-flex min-h-11 items-center text-sm font-semibold text-primary underline">
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

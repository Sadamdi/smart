"use client";
import { KartuBeasiswa } from "@/components/KartuBeasiswa";
import { Bookmark } from "lucide-react";
import { KosongState, MemuatKisi, Tampil } from "@/components/state";
import { JudulHalaman, TautanTombol } from "@/components/ui";
import { useTersimpan } from "@/lib/hooks";

const RENCANA: Record<string, string> = { akan_daftar: "Akan mendaftar", sudah_daftar: "Sudah mendaftar", tidak_jadi: "Tidak jadi" };

export default function Tersimpan() {
  const kueri = useTersimpan();
  return (
    <div className="halaman-masuk">
      <JudulHalaman judul="Beasiswa Tersimpan" deskripsi="Beasiswa yang Anda simpan untuk dipantau tenggat dan berkasnya." />
      <Tampil
        kueri={kueri}
        memuat={<MemuatKisi jumlah={3} />}
        kosong={
          <KosongState ikon={Bookmark} judul="Belum ada beasiswa tersimpan" pesan="Simpan beasiswa dari halaman detail agar tenggatnya masuk kalender." aksi={<TautanTombol href="/jelajah">Jelajah beasiswa</TautanTombol>} />
        }
      >
        {(daftar) => (
          <ul className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {daftar.map((t) => (
              <li key={t.beasiswa.id}>
                <KartuBeasiswa beasiswa={t.beasiswa}>
                  <p className="text-sm text-ink">{t.status_rencana ? RENCANA[t.status_rencana] : "Rencana mendaftar belum ditentukan"}</p>
                </KartuBeasiswa>
              </li>
            ))}
          </ul>
        )}
      </Tampil>
    </div>
  );
}

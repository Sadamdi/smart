"use client";
import { useQueryClient } from "@tanstack/react-query";
import { SendHorizonal, Trash2 } from "lucide-react";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { GelembungChat } from "@/components/GelembungChat";
import { GalatState, MemuatState, pesanGalat } from "@/components/state";
import { JudulHalaman, Kartu, Masukan, Tombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { useAksi, useRiwayatChat, useStatusChat } from "@/lib/hooks";
import type { Chat } from "@/lib/types";

const PESAN_MAKS = 2000;

export default function ChatbotAI() {
  const qc = useQueryClient();
  const status = useStatusChat();
  const riwayat = useRiwayatChat();
  const [pesan, setPesan] = useState("");
  const [menunggu, setMenunggu] = useState<string | null>(null);
  const [galat, setGalat] = useState<unknown>(null);
  const dasar = useRef<HTMLDivElement>(null);

  const hapus = useAksi(() => kirim("/chat/riwayat", "DELETE"), ["chat", "riwayat"]);
  const daftar = [...(riwayat.data ?? [])].sort((a, b) => a.waktu.localeCompare(b.waktu));

  useEffect(() => {
    dasar.current?.scrollIntoView?.({ block: "end" });
  }, [daftar.length, menunggu]);

  async function kirimPesan(e: React.FormEvent) {
    e.preventDefault();
    const isi = pesan.trim();
    if (!isi || menunggu) return;
    setGalat(null);
    setMenunggu(isi);
    setPesan("");
    try {
      const r = await kirim<Chat>("/chat", "POST", { pesan: isi });
      qc.setQueryData<Chat[]>(["chat", "riwayat"], (lama) => [...(lama ?? []), r.data]);
    } catch (x) {
      setGalat(x);
      setPesan(isi);
    } finally {
      setMenunggu(null);
    }
  }

  const tersedia = status.data?.tersedia;

  return (
    <div>
      <JudulHalaman
        judul="Chatbot AI"
        deskripsi="Tanyakan syarat, tenggat, atau berkas beasiswa. Jawaban memakai data beasiswa yang tercatat di SMART."
        aksi={
          daftar.length > 0 ? (
            <Tombol varian="hantu" onClick={() => hapus.mutate()} disabled={hapus.isPending}>
              <Trash2 className="h-4 w-4" aria-hidden /> Hapus riwayat
            </Tombol>
          ) : undefined
        }
      />
      <div role="status" className="mb-4 flex items-center gap-2 text-sm">
        <span className={`h-2.5 w-2.5 rounded-full ${status.isPending ? "bg-outline" : tersedia ? "bg-ok" : "bg-danger"}`} aria-hidden />
        <span className="text-ink">
          {status.isPending ? "Memeriksa layanan AI" : status.isError ? "Status layanan AI tidak diketahui" : tersedia ? "Layanan AI tersedia" : "Layanan AI sedang tidak tersedia"}
        </span>
      </div>
      {tersedia === false && (
        <p className="mb-4 rounded-xl bg-danger-soft px-4 py-3 text-sm text-[#8c1212]">
          Chatbot belum dapat menjawab saat ini. Anda tetap dapat menelusuri beasiswa, melihat rekomendasi, dan mengisi profil secara manual.
        </p>
      )}
      <Kartu className="flex min-h-[420px] flex-col !p-0">
        <div className="flex-1 space-y-4 overflow-y-auto p-6" style={{ maxHeight: "60vh" }} aria-live="polite">
          {riwayat.isPending ? (
            <MemuatState baris={2} />
          ) : riwayat.isError ? (
            <GalatState galat={riwayat.error} onCoba={() => riwayat.refetch()} />
          ) : daftar.length === 0 && !menunggu ? (
            <p className="py-10 text-center text-sm text-ink">Belum ada percakapan. Mulai dengan bertanya, misalnya &quot;beasiswa apa yang tenggatnya paling dekat?&quot;</p>
          ) : null}
          {daftar.map((c) => (
            <div key={c.id} className="space-y-2">
              <GelembungChat dari="pengguna">{c.pesan}</GelembungChat>
              {c.jawaban && (
                <GelembungChat dari="asisten">
                  {c.jawaban}
                  {c.rujukan.length > 0 && (
                    <span className="mt-2 block border-t border-c4 pt-2 text-xs">
                      Rujukan:{" "}
                      {c.rujukan.map((r, i) => (
                        <span key={r.id}>
                          {i > 0 && ", "}
                          <Link href={`/beasiswa/${r.id}`} className="font-semibold text-primary underline">
                            {r.nama}
                          </Link>
                        </span>
                      ))}
                    </span>
                  )}
                </GelembungChat>
              )}
            </div>
          ))}
          {menunggu && (
            <div className="space-y-2">
              <GelembungChat dari="pengguna">{menunggu}</GelembungChat>
              <GelembungChat dari="asisten">Sedang menyusun jawaban...</GelembungChat>
            </div>
          )}
          <div ref={dasar} />
        </div>
        {galat != null && (
          <p role="alert" className="mx-6 mb-3 rounded-lg bg-danger-soft px-3 py-2 text-sm text-[#8c1212]">
            {pesanGalat(galat).ai
              ? "Layanan AI sedang tidak tersedia, jadi pesan belum terjawab. Coba lagi nanti atau telusuri beasiswa secara manual."
              : pesanGalat(galat).pesan}
          </p>
        )}
        <form onSubmit={kirimPesan} className="flex gap-2 border-t border-c4/60 p-4">
          <Masukan aria-label="Pesan" placeholder="Tulis pertanyaan" maxLength={PESAN_MAKS} value={pesan} onChange={(e) => setPesan(e.target.value)} disabled={tersedia === false} />
          <Tombol type="submit" aria-label="Kirim" disabled={!pesan.trim() || Boolean(menunggu) || tersedia === false}>
            <SendHorizonal className="h-4 w-4" aria-hidden />
          </Tombol>
        </form>
      </Kartu>
      <p className="mt-3 text-xs text-muted">Nama dan tanggal lahir tidak dikirim ke layanan AI. Jawaban chatbot bukan jaminan diterima pada beasiswa mana pun.</p>
    </div>
  );
}

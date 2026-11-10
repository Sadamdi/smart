"use client";
import { useQueryClient } from "@tanstack/react-query";
import { MessageCircle, SendHorizonal, Trash2 } from "lucide-react";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { GelembungChat } from "@/components/GelembungChat";
import { GalatState, MemuatState, pesanGalat } from "@/components/state";
import { JudulHalaman, Kartu, Masukan, Tombol } from "@/components/ui";
import { kirim } from "@/lib/api";
import { useAksi, useRiwayatChat, useStatusChat } from "@/lib/hooks";
import type { Chat } from "@/lib/types";

const PESAN_MAKS = 2000;
const SARAN = ["Beasiswa apa yang tenggatnya paling dekat?", "Berkas apa yang harus saya siapkan?", "Beasiswa S2 apa yang sesuai dengan IPK saya?"];

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
    <div className="halaman-masuk">
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
      <div role="status" className="mb-4 inline-flex items-center gap-2 rounded-full bg-c2 px-3 py-1.5 text-sm">
        <span className={`h-2.5 w-2.5 rounded-full ${status.isPending ? "bg-line" : tersedia ? "bg-ok" : "bg-danger"}`} aria-hidden />
        <span className="text-ink">
          {status.isPending ? "Memeriksa layanan AI" : status.isError ? "Status layanan AI tidak diketahui" : tersedia ? "Layanan AI tersedia" : "Layanan AI sedang tidak tersedia"}
        </span>
      </div>
      {tersedia === false && (
        <p className="mb-4 rounded-[14px] bg-danger-soft px-4 py-3 text-sm text-danger-ink">
          Chatbot belum dapat menjawab saat ini. Anda tetap dapat menelusuri beasiswa, melihat rekomendasi, dan mengisi profil secara manual.
        </p>
      )}
      <Kartu className="flex min-h-[420px] flex-col overflow-hidden !p-0">
        <div className="flex-1 space-y-4 overflow-y-auto p-4 sm:p-6" style={{ maxHeight: "60vh" }} aria-live="polite">
          {riwayat.isPending ? (
            <MemuatState baris={2} />
          ) : riwayat.isError ? (
            <GalatState galat={riwayat.error} onCoba={() => riwayat.refetch()} />
          ) : daftar.length === 0 && !menunggu ? (
            <div className="flex flex-col items-center py-8 text-center">
              <span className="mb-3 flex h-14 w-14 items-center justify-center rounded-full bg-c2 text-primary">
                <MessageCircle className="h-7 w-7" aria-hidden />
              </span>
              <p className="text-base font-bold text-navy">Belum ada percakapan</p>
              <p className="mt-1 max-w-sm text-sm text-ink">Mulai dengan bertanya. Pilih salah satu saran di bawah atau tulis pertanyaan sendiri.</p>
              <div className="mt-4 flex flex-wrap justify-center gap-2">
                {SARAN.map((s) => (
                  <button
                    key={s}
                    type="button"
                    disabled={tersedia === false}
                    onClick={() => setPesan(s)}
                    className="min-h-11 rounded-full border border-c4 bg-card px-4 py-2 text-sm font-medium text-navy transition-colors hover:bg-c2 disabled:opacity-60"
                  >
                    {s}
                  </button>
                ))}
              </div>
            </div>
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
          <p role="alert" className="mx-4 mb-3 rounded-kontrol bg-danger-soft sm:mx-6 px-3 py-2 text-sm text-danger-ink">
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

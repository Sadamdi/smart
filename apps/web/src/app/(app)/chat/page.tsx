"use client";
import { useQueryClient } from "@tanstack/react-query";
import { BarChart3, Download, MessageCircle, Paperclip, RotateCcw, SendHorizonal, Square, Trash2, Upload, X } from "lucide-react";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { GelembungChat } from "@/components/GelembungChat";
import { TeksMarkdown } from "@/components/TeksMarkdown";
import { GalatState, MemuatState, pesanGalat } from "@/components/state";
import { JudulHalaman, Kartu, Masukan, Tombol } from "@/components/ui";
import { ApiError, alirSse, api, kirim } from "@/lib/api";
import { useAksi, useRiwayatChat, useStatistikChat, useStatusChat } from "@/lib/hooks";
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
  const [sementara, setSementara] = useState("");
  const batal = useRef<AbortController | null>(null);
  const dasar = useRef<HTMLDivElement>(null);

  const statistik = useStatistikChat();
  const [lihatStat, setLihatStat] = useState(false);
  const [lampiran, setLampiran] = useState<{ id: string; nama: string }[]>([]);
  const [mengunggah, setMengunggah] = useState(false);
  const [cadangan, setCadangan] = useState<unknown[] | null>(null);
  const [info, setInfo] = useState("");
  const berkasRef = useRef<HTMLInputElement>(null);
  const pulihRef = useRef<HTMLInputElement>(null);
  const segar = ["chat"];
  const hapus = useAksi(async () => {
    setCadangan((await api<unknown[]>("/chat/ekspor")).data);
    return kirim("/chat/riwayat", "DELETE");
  }, segar);
  const pulihkan = useAksi((butir: unknown[]) => kirim<{ dipulihkan: number }>("/chat/impor", "POST", { butir }), segar);
  const hapusSatu = useAksi((id: string) => kirim(`/chat/riwayat/${id}`, "DELETE"), segar);

  async function lampirkan(f: File | undefined) {
    if (!f || lampiran.length >= 3) return;
    setMengunggah(true);
    setGalat(null);
    try {
      const fd = new FormData();
      fd.set("jenis", "cv");
      fd.set("berkas", f);
      const d = (await api<{ id: string; nama_berkas: string }>("/me/dokumen", { method: "POST", body: fd })).data;
      setLampiran((l) => [...l, { id: d.id, nama: d.nama_berkas }]);
    } catch (x) {
      setGalat(x);
    } finally {
      setMengunggah(false);
    }
  }

  async function unduhCadangan() {
    const butir = (await api<unknown[]>("/chat/ekspor")).data;
    const a = document.createElement("a");
    a.href = URL.createObjectURL(new Blob([JSON.stringify(butir, null, 1)], { type: "application/json" }));
    a.download = "cadangan-chat-smart.json";
    a.click();
    URL.revokeObjectURL(a.href);
  }

  async function pulihDariBerkas(f: File | undefined) {
    if (!f) return;
    try {
      const butir = JSON.parse(await f.text());
      if (!Array.isArray(butir)) throw new Error("bukan daftar");
      const r = await pulihkan.mutateAsync(butir);
      setInfo(`${r.data.dipulihkan} percakapan dipulihkan`);
    } catch {
      setInfo("Berkas cadangan tidak valid");
    }
  }
  const daftar = [...(riwayat.data ?? [])].sort((a, b) => a.waktu.localeCompare(b.waktu));

  useEffect(() => {
    dasar.current?.scrollIntoView?.({ block: "end" });
  }, [daftar.length, menunggu]);

  /** Mengirim pesan dan menampilkan jawaban bertahap (per potongan); dapat dihentikan, jawaban yang dibatalkan tidak disimpan. */
  async function kirimPesan(e: React.FormEvent) {
    e.preventDefault();
    const isi = pesan.trim();
    if (!isi || menunggu) return;
    setGalat(null);
    setMenunggu(isi);
    setSementara("");
    setPesan("");
    const kontrol = new AbortController();
    batal.current = kontrol;
    let teks = "";
    let rangka = 0;
    try {
      for await (const k of alirSse("/chat/stream", { pesan: isi, dokumen_ids: lampiran.map((l) => l.id) }, kontrol.signal)) {
        const j = JSON.parse(k.data) as Record<string, unknown>;
        if (k.peristiwa === "token") {
          teks += String(j.t ?? "");
          if (!rangka) {
            rangka = requestAnimationFrame(() => {
              rangka = 0;
              setSementara(teks);
            });
          }
        } else if (k.peristiwa === "selesai") {
          setLampiran([]);
          void qc.invalidateQueries({ queryKey: ["chat", "statistik"] });
          void qc.invalidateQueries({ queryKey: ["memori"] });
          qc.setQueryData<Chat[]>(["chat", "riwayat"], (lama) => [...(lama ?? []), j as unknown as Chat]);
        } else if (k.peristiwa === "galat") {
          throw new ApiError("AI", String(j.pesan ?? "Layanan AI sedang tidak tersedia"), 503);
        }
      }
      if (kontrol.signal.aborted) setPesan(isi);
    } catch (x) {
      setGalat(x);
      setPesan(isi);
    } finally {
      if (rangka) cancelAnimationFrame(rangka);
      batal.current = null;
      setMenunggu(null);
      setSementara("");
    }
  }

  function hentikan() {
    batal.current?.abort();
  }

  const tersedia = status.data?.tersedia;

  return (
    <div className="halaman-masuk">
      <JudulHalaman
        judul="Chatbot AI"
        deskripsi="Tanyakan syarat, tenggat, atau berkas beasiswa. Jawaban memakai data beasiswa yang tercatat di SMART."
        aksi={
          <div className="flex flex-wrap gap-2">
            <Tombol varian="hantu" onClick={() => setLihatStat((v) => !v)} aria-expanded={lihatStat}>
              <BarChart3 className="h-4 w-4" aria-hidden /> Statistik
            </Tombol>
            <Tombol varian="hantu" onClick={unduhCadangan} disabled={daftar.length === 0}>
              <Download className="h-4 w-4" aria-hidden /> Cadangkan
            </Tombol>
            <Tombol varian="hantu" onClick={() => pulihRef.current?.click()}>
              <Upload className="h-4 w-4" aria-hidden /> Pulihkan
            </Tombol>
            {daftar.length > 0 && (
              <Tombol varian="hantu" onClick={() => hapus.mutate()} disabled={hapus.isPending}>
                <Trash2 className="h-4 w-4" aria-hidden /> Hapus riwayat
              </Tombol>
            )}
          </div>
        }
      />
      <input ref={pulihRef} type="file" accept="application/json,.json" hidden aria-label="Berkas cadangan" onChange={(e) => void pulihDariBerkas(e.target.files?.[0])} />
      {cadangan && cadangan.length > 0 && daftar.length === 0 && (
        <p className="mb-3 flex items-center gap-3 rounded-[14px] bg-c2 px-4 py-2 text-sm">
          Riwayat dihapus.
          <Tombol
            varian="hantu"
            onClick={() => {
              pulihkan.mutate(cadangan);
              setCadangan(null);
            }}
          >
            <RotateCcw className="h-4 w-4" aria-hidden /> Urungkan
          </Tombol>
        </p>
      )}
      {info && (
        <p role="status" className="mb-3 text-sm text-ink">
          {info}
        </p>
      )}
      {lihatStat && statistik.data && (
        <Kartu className="mb-4 text-sm">
          <p className="font-bold text-navy">Isi chatbot</p>
          <p className="mt-1">
            {statistik.data.jumlah} pertanyaan, {statistik.data.tujuh_hari} dalam 7 hari terakhir, rata-rata jawaban {statistik.data.rata_panjang_jawaban} karakter.
          </p>
          {statistik.data.beasiswa_teratas.length > 0 && (
            <p className="mt-1">Paling sering dirujuk: {statistik.data.beasiswa_teratas.map((b) => `${b.nama} (${b.jumlah})`).join(", ")}</p>
          )}
        </Kartu>
      )}
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
              <button type="button" aria-label="Hapus percakapan ini" onClick={() => hapusSatu.mutate(c.id)} className="ml-auto block text-xs text-muted underline">
                Hapus
              </button>
              {c.jawaban && (
                <GelembungChat dari="asisten">
                  <TeksMarkdown teks={c.jawaban} />
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
              <GelembungChat dari="asisten">{sementara ? <TeksMarkdown teks={sementara} /> : "Menyusun jawaban..."}</GelembungChat>
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
        {lampiran.length > 0 && (
          <ul className="flex flex-wrap gap-2 px-4 pt-3">
            {lampiran.map((l) => (
              <li key={l.id} className="inline-flex items-center gap-1 rounded-full bg-c2 px-3 py-1 text-xs">
                {l.nama}
                <button type="button" aria-label={`Lepas ${l.nama}`} onClick={() => setLampiran((x) => x.filter((y) => y.id !== l.id))}>
                  <X className="h-3 w-3" aria-hidden />
                </button>
              </li>
            ))}
          </ul>
        )}
        <form onSubmit={kirimPesan} className="flex gap-2 border-t border-c4/60 p-4">
          <input
            ref={berkasRef}
            type="file"
            hidden
            aria-label="Lampiran"
            accept=".pdf,.doc,.docx,.txt,.png,.jpg,.jpeg"
            onChange={(e) => {
              void lampirkan(e.target.files?.[0]);
              e.target.value = "";
            }}
          />
          <Tombol type="button" varian="hantu" aria-label="Lampirkan berkas" disabled={mengunggah || lampiran.length >= 3 || tersedia === false} onClick={() => berkasRef.current?.click()}>
            <Paperclip className="h-4 w-4" aria-hidden />
          </Tombol>
          <Masukan aria-label="Pesan" placeholder="Tulis pertanyaan" maxLength={PESAN_MAKS} value={pesan} onChange={(e) => setPesan(e.target.value)} disabled={tersedia === false} />
          {menunggu ? (
            <Tombol type="button" aria-label="Hentikan" onClick={hentikan}>
              <Square className="h-4 w-4" aria-hidden />
            </Tombol>
          ) : (
            <Tombol type="submit" aria-label="Kirim" disabled={!pesan.trim() || tersedia === false}>
              <SendHorizonal className="h-4 w-4" aria-hidden />
            </Tombol>
          )}
        </form>
      </Kartu>
      <p className="mt-3 text-xs text-muted">Nama, surel, telepon, dan nomor identitas disamarkan sebelum dikirim ke layanan AI. Lampiran masuk ke Memori AI (atur di menu Memori AI). Jawaban chatbot bukan jaminan diterima pada beasiswa mana pun.</p>
    </div>
  );
}

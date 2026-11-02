"use client";
import { Search } from "lucide-react";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { KartuBeasiswa } from "@/components/KartuBeasiswa";
import { GalatState, KosongState, MemuatState } from "@/components/state";
import { ChipFilter, JudulHalaman, Masukan, Tombol, TautanTombol } from "@/components/ui";
import { useJelajah } from "@/lib/hooks";

const JENJANG = ["D3", "D4", "S1", "S2", "S3"];

function Isi({ awal }: { awal: string }) {
  const [teks, setTeks] = useState(awal);
  const [q, setQ] = useState(awal);
  const [jenjang, setJenjang] = useState("");
  const [negara, setNegara] = useState("");
  const [negaraTerapan, setNegaraTerapan] = useState("");

  useEffect(() => {
    const t = setTimeout(() => setQ(teks.trim()), 350);
    return () => clearTimeout(t);
  }, [teks]);
  useEffect(() => {
    const t = setTimeout(() => setNegaraTerapan(negara.trim()), 350);
    return () => clearTimeout(t);
  }, [negara]);

  const kueri = useJelajah({ q, jenjang, negara: negaraTerapan });
  const item = kueri.data?.pages.flatMap((p) => p.item) ?? [];

  return (
    <div>
      <JudulHalaman judul="Jelajah Beasiswa" deskripsi="Telusuri beasiswa yang sedang dibuka dari sumber resmi." />
      <div className="mb-6 space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row">
          <div className="relative flex-1">
            <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" aria-hidden />
            <Masukan aria-label="Cari nama atau penyelenggara" placeholder="Cari nama atau penyelenggara" className="pl-10" value={teks} onChange={(e) => setTeks(e.target.value)} />
          </div>
          <Masukan aria-label="Negara tujuan" placeholder="Negara" className="sm:w-52" value={negara} onChange={(e) => setNegara(e.target.value)} />
        </div>
        <div className="flex flex-wrap gap-2" role="group" aria-label="Filter jenjang">
          <ChipFilter aktif={jenjang === ""} onClick={() => setJenjang("")}>
            Semua jenjang
          </ChipFilter>
          {JENJANG.map((j) => (
            <ChipFilter key={j} aktif={jenjang === j} onClick={() => setJenjang(j)}>
              {j}
            </ChipFilter>
          ))}
        </div>
      </div>

      {kueri.isPending ? (
        <MemuatState baris={4} />
      ) : kueri.isError ? (
        <GalatState galat={kueri.error} onCoba={() => kueri.refetch()} />
      ) : item.length === 0 ? (
        <KosongState
          judul="Tidak ada beasiswa untuk pencarian ini"
          pesan="Ubah kata kunci atau hapus filter untuk melihat lebih banyak."
          aksi={
            <Tombol
              varian="sekunder"
              onClick={() => {
                setTeks("");
                setNegara("");
                setJenjang("");
              }}
            >
              Hapus filter
            </Tombol>
          }
        />
      ) : (
        <>
          <ul className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {item.map((b) => (
              <li key={b.id}>
                <KartuBeasiswa beasiswa={b} />
              </li>
            ))}
          </ul>
          {kueri.hasNextPage && (
            <div className="mt-6 text-center">
              <Tombol varian="sekunder" onClick={() => kueri.fetchNextPage()} disabled={kueri.isFetchingNextPage}>
                {kueri.isFetchingNextPage ? "Memuat" : "Muat lebih banyak"}
              </Tombol>
            </div>
          )}
        </>
      )}
      <div className="mt-10 flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-c2 p-6">
        <p className="max-w-md text-sm text-navy">Bingung memilih? Tanyakan Chatbot AI tentang syarat dan tenggat beasiswa yang tercatat.</p>
        <TautanTombol href="/chat">Buka Chatbot AI</TautanTombol>
      </div>
    </div>
  );
}

function DariParam() {
  const q = useSearchParams().get("q") ?? "";
  return <Isi key={q} awal={q} />;
}

export default function Jelajah() {
  return (
    <Suspense fallback={<MemuatState baris={4} />}>
      <DariParam />
    </Suspense>
  );
}

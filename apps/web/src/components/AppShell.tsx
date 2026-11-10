"use client";
import {
  Bell,
  Bookmark,
  CalendarCheck,
  ChartNoAxesColumn,
  ClipboardList,
  FileText,
  GraduationCap,
  Home,
  Inbox,
  LogOut,
  Menu,
  MessageCircle,
  Monitor,
  Moon,
  Search,
  Settings,
  Sparkles,
  Sun,
  User,
  X,
  Database,
} from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useRef, useState, type ComponentType, type ReactNode } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { keluar } from "@/lib/auth";
import { inisial } from "@/lib/format";
import { useNotifikasi } from "@/lib/hooks";
import type { Pengguna } from "@/lib/types";
import { cx } from "./ui";
import { useTema } from "./Tema";

type Menu = { href: string; label: string; ikon: ComponentType<{ className?: string }> };

const MENU_MAHASISWA: Menu[] = [
  { href: "/", label: "Dashboard", ikon: Home },
  { href: "/rekomendasi", label: "Rekomendasi Beasiswa", ikon: Sparkles },
  { href: "/jelajah", label: "Jelajah Beasiswa", ikon: GraduationCap },
  { href: "/tersimpan", label: "Beasiswa Tersimpan", ikon: Bookmark },
  { href: "/kalender", label: "Kalender dan Checklist", ikon: CalendarCheck },
  { href: "/dokumen", label: "Dokumen Saya", ikon: FileText },
  { href: "/chat", label: "Chatbot AI", ikon: MessageCircle },
  { href: "/profil", label: "Profil Saya", ikon: User },
];

const MENU_ADMIN: Menu[] = [
  { href: "/admin", label: "Dashboard Admin", ikon: ChartNoAxesColumn },
  { href: "/admin/antrean", label: "Antrean Validasi", ikon: ClipboardList },
  { href: "/admin/sumber", label: "Kelola Sumber", ikon: Database },
  { href: "/admin/laporan", label: "Laporan Sistem", ikon: Inbox },
];

function aktifKah(path: string, href: string) {
  if (href === "/" || href === "/admin") return path === href;
  return path === href || path.startsWith(href + "/");
}

function Sidebar({ pengguna, admin, tutup }: { pengguna: Pengguna; admin: boolean; tutup?: () => void }) {
  const path = usePathname();
  const router = useRouter();
  const qc = useQueryClient();
  const menu = admin ? MENU_ADMIN : MENU_MAHASISWA;

  async function aksiKeluar() {
    await keluar();
    qc.clear();
    router.replace("/masuk");
  }

  return (
    <nav aria-label="Menu utama" className="flex h-full w-[min(280px,86vw)] flex-col bg-card px-4 py-6 lg:w-[250px]">
      <div className="mb-8 flex items-center justify-between px-2">
        <Link href={admin ? "/admin" : "/"} className="flex items-center gap-3" onClick={tutup}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo.svg" alt="" width={40} height={40} className="h-10 w-10" />
          <span>
            <span className="block text-lg font-extrabold leading-none text-navy">SMART</span>
            <span className="text-xs text-muted">{admin ? "Panel Admin" : "Scholarship Assistant"}</span>
          </span>
        </Link>
        {tutup && (
          <button type="button" aria-label="Tutup menu" onClick={tutup} className="flex h-11 w-11 items-center justify-center rounded-full text-navy hover:bg-c2">
            <X className="h-5 w-5" aria-hidden />
          </button>
        )}
      </div>

      <ul className="flex-1 space-y-1 overflow-y-auto">
        {menu.map((m) => {
          const aktif = aktifKah(path, m.href);
          return (
            <li key={m.href}>
              <Link
                href={m.href}
                onClick={tutup}
                aria-current={aktif ? "page" : undefined}
                className={cx(
                  "relative flex min-h-11 items-center gap-3 rounded-[14px] px-3 py-2.5 text-sm transition-colors duration-150",
                  aktif ? "bg-c3 font-bold text-primary" : "font-medium text-ink hover:bg-c1",
                )}
              >
                {aktif && <span aria-hidden className="absolute left-0 top-1/2 h-5 w-1 -translate-y-1/2 rounded-full bg-gold" />}
                <m.ikon className="h-5 w-5 shrink-0" />
                {m.label}
              </Link>
            </li>
          );
        })}
      </ul>

      <div className="mt-4 space-y-1 border-t border-c4/60 pt-4">
        {pengguna.peran === "admin" && (
          <Link
            href={admin ? "/" : "/admin"}
            onClick={tutup}
            className="flex min-h-11 items-center gap-3 rounded-[14px] px-3 py-2.5 text-sm font-medium text-primary hover:bg-c1"
          >
            <ChartNoAxesColumn className="h-5 w-5 shrink-0" aria-hidden />
            {admin ? "Beralih ke tampilan mahasiswa" : "Panel Admin"}
          </Link>
        )}
        <div className="flex items-center gap-3 rounded-[14px] bg-c1 px-3 py-2.5">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-fill text-xs font-bold text-white ring-2 ring-gold/70">
            {inisial(pengguna.nama)}
          </span>
          <span className="min-w-0">
            <span className="block truncate text-sm font-bold text-navy">{pengguna.nama}</span>
            <span className="block truncate text-xs text-muted">{pengguna.peran === "admin" ? "Admin" : (pengguna.kampus ?? "Mahasiswa")}</span>
          </span>
        </div>
        {!admin && (
          <Link
            href="/pengaturan"
            onClick={tutup}
            aria-current={path === "/pengaturan" ? "page" : undefined}
            className={cx(
              "flex min-h-11 items-center gap-3 rounded-[14px] px-3 py-2.5 text-sm",
              path === "/pengaturan" ? "bg-c3 font-bold text-primary" : "font-medium text-ink hover:bg-c1",
            )}
          >
            <Settings className="h-5 w-5 shrink-0" aria-hidden /> Pengaturan
          </Link>
        )}
        <button
          type="button"
          onClick={aksiKeluar}
          className="flex min-h-11 w-full items-center gap-3 rounded-[14px] px-3 py-2.5 text-sm font-medium text-danger hover:bg-danger-soft"
        >
          <LogOut className="h-5 w-5 shrink-0" aria-hidden /> Keluar
        </button>
      </div>
    </nav>
  );
}

const URUTAN_TEMA = ["sistem", "terang", "gelap"] as const;
const LABEL_TEMA = { sistem: "Sistem", terang: "Terang", gelap: "Gelap" } as const;

/** Pintasan ganti tema di kepala halaman (berlaku juga untuk admin); pilihan lengkap ada di Pengaturan. */
function TombolTema() {
  const { pilihan, atur } = useTema();
  const berikut = URUTAN_TEMA[(URUTAN_TEMA.indexOf(pilihan) + 1) % URUTAN_TEMA.length];
  const Ikon = pilihan === "gelap" ? Moon : pilihan === "terang" ? Sun : Monitor;
  return (
    <button
      type="button"
      onClick={() => atur(berikut)}
      aria-label={`Tema ${LABEL_TEMA[pilihan]}. Ganti ke ${LABEL_TEMA[berikut]}`}
      title={`Tema: ${LABEL_TEMA[pilihan]}`}
      className="flex h-11 w-11 items-center justify-center rounded-full text-navy transition-colors hover:bg-c2"
    >
      <Ikon className="h-5 w-5" aria-hidden />
    </button>
  );
}

function Header({ pengguna, admin, bukaMenu }: { pengguna: Pengguna; admin: boolean; bukaMenu: () => void }) {
  const router = useRouter();
  const kolom = useRef<HTMLInputElement>(null);
  const notif = useNotifikasi();
  const belumBaca = notif.data?.filter((n) => !n.dibaca).length ?? 0;

  useEffect(() => {
    const f = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        kolom.current?.focus();
      }
    };
    window.addEventListener("keydown", f);
    return () => window.removeEventListener("keydown", f);
  }, []);

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center gap-1.5 border-b border-c4/60 bg-card/95 px-3 backdrop-blur sm:gap-3 sm:px-4 md:px-8">
      <button type="button" aria-label="Buka menu" onClick={bukaMenu} className="flex h-11 w-11 items-center justify-center rounded-full text-navy hover:bg-c2 lg:hidden">
        <Menu className="h-5 w-5" aria-hidden />
      </button>
      <Link href={admin ? "/admin" : "/"} aria-label="SMART, ke beranda" className="flex h-11 items-center lg:hidden">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/logo.svg" alt="" width={32} height={32} className="h-8 w-8" />
      </Link>
      <p className="hidden text-sm text-muted md:block">
        Portal Akademik <span aria-hidden>/</span> <span className="font-bold text-navy">{admin ? "Admin" : "Mahasiswa"}</span>
      </p>
      <div className="flex-1" />
      {!admin && (pengguna.semester || pengguna.ipk) && (
        <div className="hidden items-center gap-2 xl:flex">
          {pengguna.semester ? <span className="rounded-full bg-c2 px-3 py-1 text-xs font-bold text-navy">Semester {pengguna.semester}</span> : null}
          {pengguna.ipk ? <span className="rounded-full bg-c2 px-3 py-1 text-xs font-bold text-navy">IPK {pengguna.ipk}</span> : null}
        </div>
      )}
      {!admin && (
        <form
          role="search"
          className="relative hidden w-64 sm:block"
          onSubmit={(e) => {
            e.preventDefault();
            const q = kolom.current?.value.trim();
            router.push(q ? `/jelajah?q=${encodeURIComponent(q)}` : "/jelajah");
          }}
        >
          <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" aria-hidden />
          <input
            ref={kolom}
            aria-label="Cari beasiswa"
            placeholder="Cari beasiswa"
            className="min-h-11 w-full rounded-full border border-c4 bg-c1 py-2 pl-10 pr-16 text-sm text-navy placeholder:text-muted focus:border-primary"
          />
          <kbd className="absolute right-3 top-1/2 hidden -translate-y-1/2 rounded bg-c3 px-1.5 text-[11px] text-muted md:block">Ctrl K</kbd>
        </form>
      )}
      {!admin && (
        <Link
          href="/notifikasi"
          aria-label={belumBaca ? `Notifikasi, ${belumBaca} belum dibaca` : "Notifikasi"}
          className="relative flex h-11 w-11 items-center justify-center rounded-full text-navy hover:bg-c2"
        >
          <Bell className="h-5 w-5" aria-hidden />
          {belumBaca > 0 && (
            <span className="absolute right-0.5 top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-danger-fill px-1 text-[10px] font-bold text-white">
              {belumBaca > 9 ? "9+" : belumBaca}
            </span>
          )}
        </Link>
      )}
      <TombolTema />
      <Link
        href={admin ? "/admin" : "/profil"}
        aria-label="Profil"
        className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-fill text-xs font-bold text-white ring-2 ring-gold/70"
      >
        {inisial(pengguna.nama)}
      </Link>
    </header>
  );
}

export function AppShell({ pengguna, admin, children }: { pengguna: Pengguna; admin: boolean; children: ReactNode }) {
  const path = usePathname();
  // Laci terbuka hanya untuk rute tempat ia dibuka, jadi otomatis menutup saat pindah halaman.
  const [bukaDi, setBukaDi] = useState<string | null>(null);
  const buka = bukaDi === path;
  const setBuka = (v: boolean) => setBukaDi(v ? path : null);

  useEffect(() => {
    if (!buka) return;
    const f = (e: KeyboardEvent) => e.key === "Escape" && setBukaDi(null);
    window.addEventListener("keydown", f);
    return () => window.removeEventListener("keydown", f);
  }, [buka]);

  return (
    <div className="min-h-screen lg:pl-[250px]">
      <a
        href="#konten"
        className="sr-only focus:not-sr-only focus:fixed focus:left-3 focus:top-3 focus:z-50 focus:rounded-kontrol focus:bg-fill focus:px-4 focus:py-2 focus:text-white"
      >
        Lompat ke konten
      </a>
      <div className="fixed inset-y-0 left-0 z-30 hidden border-r border-c4/60 lg:block">
        <Sidebar pengguna={pengguna} admin={admin} />
      </div>
      {buka && (
        <div role="dialog" aria-modal="true" aria-label="Menu" className="fixed inset-0 z-40 lg:hidden">
          <button type="button" aria-label="Tutup menu" className="absolute inset-0 bg-scrim" onClick={() => setBuka(false)} />
          <div className="relative h-full w-fit shadow-xl">
            <Sidebar pengguna={pengguna} admin={admin} tutup={() => setBuka(false)} />
          </div>
        </div>
      )}
      <Header pengguna={pengguna} admin={admin} bukaMenu={() => setBuka(true)} />
      <main id="konten" className="mx-auto w-full max-w-[1126px] px-4 py-6 sm:px-6 md:px-10 md:py-8">
        {children}
      </main>
    </div>
  );
}

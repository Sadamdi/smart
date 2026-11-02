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
  Search,
  Settings,
  Sparkles,
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
    <nav aria-label="Menu utama" className="flex h-full w-[250px] flex-col bg-white px-4 py-6">
      <div className="mb-8 flex items-center justify-between px-2">
        <Link href={admin ? "/admin" : "/"} className="flex items-center gap-3" onClick={tutup}>
          <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary text-sm font-bold text-white">S</span>
          <span>
            <span className="block text-lg font-bold leading-none text-navy">SMART</span>
            <span className="text-xs text-muted">{admin ? "Panel Admin" : "Scholarship Assistant"}</span>
          </span>
        </Link>
        {tutup && (
          <button type="button" aria-label="Tutup menu" onClick={tutup} className="rounded-full p-2 text-navy hover:bg-c2">
            <X className="h-5 w-5" />
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
                  "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors",
                  aktif ? "bg-c2 text-primary" : "text-ink hover:bg-c1",
                )}
              >
                <m.ikon className="h-[18px] w-[18px]" />
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
            className="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-primary hover:bg-c1"
          >
            <ChartNoAxesColumn className="h-[18px] w-[18px]" />
            {admin ? "Beralih ke tampilan mahasiswa" : "Panel Admin"}
          </Link>
        )}
        <div className="flex items-center gap-3 rounded-xl bg-c1 px-3 py-2.5">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary text-xs font-bold text-white">
            {inisial(pengguna.nama)}
          </span>
          <span className="min-w-0">
            <span className="block truncate text-sm font-semibold text-navy">{pengguna.nama}</span>
            <span className="block truncate text-xs text-muted">{pengguna.peran === "admin" ? "Admin" : (pengguna.kampus ?? "Mahasiswa")}</span>
          </span>
        </div>
        {!admin && (
          <Link
            href="/pengaturan"
            onClick={tutup}
            aria-current={path === "/pengaturan" ? "page" : undefined}
            className={cx(
              "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium",
              path === "/pengaturan" ? "bg-c2 text-primary" : "text-ink hover:bg-c1",
            )}
          >
            <Settings className="h-[18px] w-[18px]" /> Pengaturan
          </Link>
        )}
        <button
          type="button"
          onClick={aksiKeluar}
          className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-danger hover:bg-danger-soft/50"
        >
          <LogOut className="h-[18px] w-[18px]" /> Keluar
        </button>
      </div>
    </nav>
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
    <header className="sticky top-0 z-20 flex h-16 items-center gap-3 border-b border-c4/60 bg-white/95 px-4 backdrop-blur md:px-8">
      <button type="button" aria-label="Buka menu" onClick={bukaMenu} className="rounded-full p-2 text-navy hover:bg-c2 lg:hidden">
        <Menu className="h-5 w-5" />
      </button>
      <p className="hidden text-sm text-muted md:block">
        Portal Akademik <span aria-hidden>/</span> <span className="font-semibold text-navy">{admin ? "Admin" : "Mahasiswa"}</span>
      </p>
      <div className="flex-1" />
      {!admin && (pengguna.semester || pengguna.ipk) && (
        <div className="hidden items-center gap-2 xl:flex">
          {pengguna.semester ? <span className="rounded-full bg-c2 px-3 py-1 text-xs font-semibold text-navy">Semester {pengguna.semester}</span> : null}
          {pengguna.ipk ? <span className="rounded-full bg-c2 px-3 py-1 text-xs font-semibold text-navy">IPK {pengguna.ipk}</span> : null}
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
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" aria-hidden />
          <input
            ref={kolom}
            aria-label="Cari beasiswa"
            placeholder="Cari beasiswa"
            className="w-full rounded-full border border-outline bg-c1 py-2 pl-9 pr-12 text-sm text-navy placeholder:text-muted"
          />
          <kbd className="absolute right-3 top-1/2 -translate-y-1/2 rounded bg-c3 px-1.5 text-[11px] text-muted">Ctrl K</kbd>
        </form>
      )}
      {!admin && (
        <Link href="/notifikasi" aria-label={belumBaca ? `Notifikasi, ${belumBaca} belum dibaca` : "Notifikasi"} className="relative rounded-full p-2 text-navy hover:bg-c2">
          <Bell className="h-5 w-5" />
          {belumBaca > 0 && (
            <span className="absolute right-0.5 top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-danger px-1 text-[10px] font-bold text-white">
              {belumBaca > 9 ? "9+" : belumBaca}
            </span>
          )}
        </Link>
      )}
      <Link href={admin ? "/admin" : "/profil"} aria-label="Profil" className="flex h-9 w-9 items-center justify-center rounded-full bg-primary text-xs font-bold text-white">
        {inisial(pengguna.nama)}
      </Link>
    </header>
  );
}

export function AppShell({ pengguna, admin, children }: { pengguna: Pengguna; admin: boolean; children: ReactNode }) {
  const [buka, setBuka] = useState(false);
  return (
    <div className="min-h-screen lg:pl-[250px]">
      <div className="fixed inset-y-0 left-0 z-30 hidden border-r border-c4/60 lg:block">
        <Sidebar pengguna={pengguna} admin={admin} />
      </div>
      {buka && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <button type="button" aria-label="Tutup menu" className="absolute inset-0 bg-navy/40" onClick={() => setBuka(false)} />
          <div className="relative h-full w-[250px]">
            <Sidebar pengguna={pengguna} admin={admin} tutup={() => setBuka(false)} />
          </div>
        </div>
      )}
      <Header pengguna={pengguna} admin={admin} bukaMenu={() => setBuka(true)} />
      <main className="mx-auto w-full max-w-[1126px] px-4 py-8 md:px-12">{children}</main>
    </div>
  );
}

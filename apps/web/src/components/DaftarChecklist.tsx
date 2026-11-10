"use client";
import { cx } from "./ui";

export type ButirChecklist = { id: string; label: string; selesai: boolean };

export function DaftarChecklist({
  butir,
  onUbah,
  sibuk,
}: {
  butir: ButirChecklist[];
  onUbah?: (id: string, selesai: boolean) => void;
  sibuk?: boolean;
}) {
  return (
    <ul className="space-y-1">
      {butir.map((b) => (
        <li key={b.id}>
          <label className={cx("flex min-h-11 items-center gap-3 rounded-kontrol px-2 py-2 text-sm transition-colors", onUbah && "cursor-pointer hover:bg-c1")}>
            <input
              type="checkbox"
              checked={b.selesai}
              disabled={!onUbah || sibuk}
              onChange={(e) => onUbah?.(b.id, e.target.checked)}
              className="h-5 w-5 shrink-0 accent-primary"
            />
            <span className={cx(b.selesai ? "text-muted line-through" : "text-navy")}>{b.label}</span>
          </label>
        </li>
      ))}
    </ul>
  );
}

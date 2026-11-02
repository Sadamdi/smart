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
          <label className={cx("flex items-start gap-3 rounded-lg px-2 py-2 text-sm", onUbah && "cursor-pointer hover:bg-c1")}>
            <input
              type="checkbox"
              checked={b.selesai}
              disabled={!onUbah || sibuk}
              onChange={(e) => onUbah?.(b.id, e.target.checked)}
              className="mt-0.5 h-4 w-4 accent-primary"
            />
            <span className={cx(b.selesai ? "text-muted line-through" : "text-navy")}>{b.label}</span>
          </label>
        </li>
      ))}
    </ul>
  );
}

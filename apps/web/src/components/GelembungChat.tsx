import type { ReactNode } from "react";
import { cx } from "./ui";

export function GelembungChat({ dari, children }: { dari: "pengguna" | "asisten"; children: ReactNode }) {
  const pengguna = dari === "pengguna";
  return (
    <div className={cx("flex", pengguna ? "justify-end" : "justify-start")}>
      <div
        className={cx(
          "max-w-[85%] whitespace-pre-wrap rounded-kartu px-4 py-3 text-sm leading-relaxed",
          pengguna ? "rounded-br-md bg-fill text-white" : "rounded-bl-md bg-c2 text-navy",
        )}
      >
        {children}
      </div>
    </div>
  );
}

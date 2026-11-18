import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { TeksMarkdown } from "./TeksMarkdown";

describe("TeksMarkdown", () => {
  it("menampilkan tebal, daftar, dan tautan aman", () => {
    const { container } = render(<TeksMarkdown teks={"**Penting**\n\n- satu\n- dua\n\n[resmi](https://contoh.id) [bahaya](javascript:alert(1))"} />);
    expect(container.querySelector("strong")?.textContent).toBe("Penting");
    expect(container.querySelectorAll("li")).toHaveLength(2);
    const tautan = screen.getByText("resmi") as HTMLAnchorElement;
    expect(tautan.getAttribute("href")).toBe("https://contoh.id");
    expect(tautan.getAttribute("rel")).toContain("noopener");
    expect(container.querySelector('a[href^="javascript"]')).toBeNull();
  });

  it("tidak merender HTML mentah", () => {
    const { container } = render(<TeksMarkdown teks={"<script>alert(1)</script> halo"} />);
    expect(container.querySelector("script")).toBeNull();
  });
});

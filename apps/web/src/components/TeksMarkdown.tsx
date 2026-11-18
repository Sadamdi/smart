"use client";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

/** Jawaban AI ditampilkan sebagai teks beraturan (judul, tebal, miring, daftar, tabel, kutipan, kode, tautan), bukan teks mentah.
 *  HTML mentah tidak dirender (aman); tautan hanya http dan https dan dibuka di tab baru. */
export function TeksMarkdown({ teks }: { teks: string }) {
  return (
    <div className="space-y-2 text-sm leading-relaxed [&_a]:font-semibold [&_a]:text-primary [&_a]:underline [&_blockquote]:border-l-4 [&_blockquote]:border-primary [&_blockquote]:pl-3 [&_blockquote]:text-muted [&_code]:rounded [&_code]:bg-c1 [&_code]:px-1 [&_code]:text-[13px] [&_h1]:text-lg [&_h1]:font-extrabold [&_h2]:text-base [&_h2]:font-extrabold [&_h3]:font-bold [&_ol]:list-decimal [&_ol]:pl-5 [&_pre]:overflow-x-auto [&_pre]:rounded-lg [&_pre]:bg-c1 [&_pre]:p-3 [&_strong]:font-extrabold [&_table]:w-full [&_table]:border-collapse [&_td]:border [&_td]:border-c4 [&_td]:px-2 [&_td]:py-1 [&_th]:border [&_th]:border-c4 [&_th]:px-2 [&_th]:py-1 [&_th]:text-left [&_ul]:list-disc [&_ul]:pl-5">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{
          a: ({ href, children }) => {
            const aman = typeof href === "string" && /^https?:\/\//i.test(href);
            return aman ? (
              <a href={href} target="_blank" rel="noopener noreferrer">
                {children}
              </a>
            ) : (
              <span>{children}</span>
            );
          },
        }}
      >
        {teks}
      </ReactMarkdown>
    </div>
  );
}

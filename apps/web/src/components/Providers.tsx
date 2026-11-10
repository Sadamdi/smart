"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { ApiError, aturSaatKedaluwarsa } from "@/lib/api";
import { TemaProvider } from "./Tema";

export function Providers({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [client] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30_000,
            refetchOnWindowFocus: false,
            retry: (n, e) => !(e instanceof ApiError && e.status >= 400 && e.status < 500) && n < 2,
          },
        },
      }),
  );

  useEffect(() => {
    aturSaatKedaluwarsa(() => {
      client.clear();
      router.replace("/masuk");
    });
    return () => aturSaatKedaluwarsa(null);
  }, [client, router]);

  return (
    <TemaProvider>
      <QueryClientProvider client={client}>{children}</QueryClientProvider>
    </TemaProvider>
  );
}

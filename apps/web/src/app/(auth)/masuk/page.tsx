import { FormMasuk } from "@/components/FormMasuk";
import { PanelAuth } from "@/components/PanelAuth";

export const metadata = { title: "Masuk | SMART" };

export default function Masuk() {
  return (
    <PanelAuth judul="Masuk" deskripsi="Lanjutkan ke dashboard beasiswa Anda.">
      <FormMasuk />
    </PanelAuth>
  );
}

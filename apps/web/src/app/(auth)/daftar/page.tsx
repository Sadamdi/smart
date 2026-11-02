import { FormDaftar } from "@/components/FormDaftar";
import { PanelAuth } from "@/components/PanelAuth";

export const metadata = { title: "Daftar | SMART" };

export default function Daftar() {
  return (
    <PanelAuth judul="Buat akun" deskripsi="Daftar lalu lengkapi profil agar rekomendasi sesuai.">
      <FormDaftar />
    </PanelAuth>
  );
}

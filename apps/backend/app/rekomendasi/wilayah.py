"""Data referensi wilayah (negara dan provinsi Indonesia) dan pencocokan syarat domisili.

Syarat domisili beasiswa dapat berupa negara ("Indonesia", "Canada"), provinsi ("Jawa Timur"), atau kota
("Kota Malang"). Modul ini menormalkan nama (huruf kecil, tanpa awalan Kota/Kabupaten/Provinsi, sinonim umum) lalu
mencocokkan pada tingkat yang sesuai. Murni dan tanpa basis data.
"""

import re
from dataclasses import dataclass

NEGARA_ASAL = "Indonesia"

# 38 provinsi (termasuk empat provinsi baru Papua sejak 2022).
PROVINSI_INDONESIA: tuple[str, ...] = (
    "Aceh",
    "Sumatera Utara",
    "Sumatera Barat",
    "Riau",
    "Kepulauan Riau",
    "Jambi",
    "Sumatera Selatan",
    "Kepulauan Bangka Belitung",
    "Bengkulu",
    "Lampung",
    "DKI Jakarta",
    "Jawa Barat",
    "Banten",
    "Jawa Tengah",
    "DI Yogyakarta",
    "Jawa Timur",
    "Bali",
    "Nusa Tenggara Barat",
    "Nusa Tenggara Timur",
    "Kalimantan Barat",
    "Kalimantan Tengah",
    "Kalimantan Selatan",
    "Kalimantan Timur",
    "Kalimantan Utara",
    "Sulawesi Utara",
    "Gorontalo",
    "Sulawesi Tengah",
    "Sulawesi Barat",
    "Sulawesi Selatan",
    "Sulawesi Tenggara",
    "Maluku",
    "Maluku Utara",
    "Papua",
    "Papua Barat",
    "Papua Barat Daya",
    "Papua Selatan",
    "Papua Tengah",
    "Papua Pegunungan",
)

# Nama tampilan berbahasa Indonesia; sinonim (Inggris dan lainnya) ada di _SINONIM_NEGARA.
NEGARA_UMUM: tuple[str, ...] = (
    "Indonesia",
    "Malaysia",
    "Singapura",
    "Brunei Darussalam",
    "Thailand",
    "Filipina",
    "Vietnam",
    "Kamboja",
    "Laos",
    "Myanmar",
    "Timor Leste",
    "India",
    "Pakistan",
    "Bangladesh",
    "Sri Lanka",
    "Nepal",
    "Tiongkok",
    "Hong Kong",
    "Taiwan",
    "Jepang",
    "Korea Selatan",
    "Mongolia",
    "Arab Saudi",
    "Uni Emirat Arab",
    "Qatar",
    "Kuwait",
    "Oman",
    "Yordania",
    "Turki",
    "Mesir",
    "Maroko",
    "Aljazair",
    "Tunisia",
    "Afrika Selatan",
    "Nigeria",
    "Kenya",
    "Australia",
    "Selandia Baru",
    "Papua Nugini",
    "Amerika Serikat",
    "Kanada",
    "Meksiko",
    "Brasil",
    "Argentina",
    "Chili",
    "Inggris",
    "Irlandia",
    "Prancis",
    "Jerman",
    "Belanda",
    "Belgia",
    "Swiss",
    "Austria",
    "Italia",
    "Spanyol",
    "Portugal",
    "Swedia",
    "Norwegia",
    "Denmark",
    "Finlandia",
    "Polandia",
    "Ceko",
    "Hungaria",
    "Rusia",
    "Ukraina",
    "Kazakhstan",
    "Uzbekistan",
)

_SINONIM_NEGARA: dict[str, str] = {
    "singapore": "Singapura",
    "brunei": "Brunei Darussalam",
    "philippines": "Filipina",
    "cambodia": "Kamboja",
    "east timor": "Timor Leste",
    "timor-leste": "Timor Leste",
    "china": "Tiongkok",
    "republic of korea": "Korea Selatan",
    "south korea": "Korea Selatan",
    "korea": "Korea Selatan",
    "japan": "Jepang",
    "saudi arabia": "Arab Saudi",
    "united arab emirates": "Uni Emirat Arab",
    "uae": "Uni Emirat Arab",
    "turkey": "Turki",
    "turkiye": "Turki",
    "egypt": "Mesir",
    "morocco": "Maroko",
    "south africa": "Afrika Selatan",
    "new zealand": "Selandia Baru",
    "papua new guinea": "Papua Nugini",
    "united states": "Amerika Serikat",
    "united states of america": "Amerika Serikat",
    "usa": "Amerika Serikat",
    "amerika": "Amerika Serikat",
    "canada": "Kanada",
    "mexico": "Meksiko",
    "brazil": "Brasil",
    "chile": "Chili",
    "united kingdom": "Inggris",
    "uk": "Inggris",
    "britania raya": "Inggris",
    "great britain": "Inggris",
    "ireland": "Irlandia",
    "france": "Prancis",
    "germany": "Jerman",
    "netherlands": "Belanda",
    "the netherlands": "Belanda",
    "holland": "Belanda",
    "belgium": "Belgia",
    "switzerland": "Swiss",
    "italy": "Italia",
    "spain": "Spanyol",
    "sweden": "Swedia",
    "norway": "Norwegia",
    "finland": "Finlandia",
    "poland": "Polandia",
    "czech republic": "Ceko",
    "czechia": "Ceko",
    "hungary": "Hungaria",
    "russia": "Rusia",
    "jordan": "Yordania",
    "algeria": "Aljazair",
    "wni": "Indonesia",
}

_SINONIM_PROVINSI: dict[str, str] = {
    "jatim": "Jawa Timur",
    "jabar": "Jawa Barat",
    "jateng": "Jawa Tengah",
    "jakarta": "DKI Jakarta",
    "dki": "DKI Jakarta",
    "diy": "DI Yogyakarta",
    "yogyakarta": "DI Yogyakarta",
    "jogja": "DI Yogyakarta",
    "daerah istimewa yogyakarta": "DI Yogyakarta",
    "ntt": "Nusa Tenggara Timur",
    "ntb": "Nusa Tenggara Barat",
    "babel": "Kepulauan Bangka Belitung",
    "bangka belitung": "Kepulauan Bangka Belitung",
    "kepri": "Kepulauan Riau",
    "sumut": "Sumatera Utara",
    "sumbar": "Sumatera Barat",
    "sumsel": "Sumatera Selatan",
    "kalbar": "Kalimantan Barat",
    "kalteng": "Kalimantan Tengah",
    "kalsel": "Kalimantan Selatan",
    "kaltim": "Kalimantan Timur",
    "kaltara": "Kalimantan Utara",
    "sulut": "Sulawesi Utara",
    "sulteng": "Sulawesi Tengah",
    "sulbar": "Sulawesi Barat",
    "sulsel": "Sulawesi Selatan",
    "sultra": "Sulawesi Tenggara",
    "malut": "Maluku Utara",
    "nanggroe aceh darussalam": "Aceh",
    "nad": "Aceh",
}

_AWALAN = re.compile(r"^(kota administrasi|kota adm\.?|kota|kabupaten|kab\.?|provinsi|prov\.?|city of|negara)\s+")


def kunci(teks: str | None) -> str:
    """Bentuk pembanding: huruf kecil, spasi tunggal, tanpa tanda baca di tepi dan tanpa awalan Kota/Kabupaten/Provinsi."""
    t = re.sub(r"\s+", " ", (teks or "").lower().strip(" \t.,;:()"))
    return _AWALAN.sub("", t).strip()


_KUNCI_PROVINSI: dict[str, str] = {kunci(p): p for p in PROVINSI_INDONESIA}
_KUNCI_PROVINSI.update({kunci(k): v for k, v in _SINONIM_PROVINSI.items()})
_KUNCI_NEGARA: dict[str, str] = {kunci(n): n for n in NEGARA_UMUM}
_KUNCI_NEGARA.update({kunci(k): v for k, v in _SINONIM_NEGARA.items()})


# Kota besar dan ibu kota provinsi, dipakai menebak provinsi bagi profil lama yang hanya mengisi kota.
_KOTA_PROVINSI: dict[str, str] = {
    "banda aceh": "Aceh",
    "lhokseumawe": "Aceh",
    "medan": "Sumatera Utara",
    "binjai": "Sumatera Utara",
    "pematangsiantar": "Sumatera Utara",
    "padang": "Sumatera Barat",
    "bukittinggi": "Sumatera Barat",
    "pekanbaru": "Riau",
    "dumai": "Riau",
    "batam": "Kepulauan Riau",
    "tanjungpinang": "Kepulauan Riau",
    "jambi": "Jambi",
    "palembang": "Sumatera Selatan",
    "pangkalpinang": "Kepulauan Bangka Belitung",
    "bengkulu": "Bengkulu",
    "bandar lampung": "Lampung",
    "metro": "Lampung",
    "jakarta": "DKI Jakarta",
    "jakarta pusat": "DKI Jakarta",
    "jakarta selatan": "DKI Jakarta",
    "jakarta barat": "DKI Jakarta",
    "jakarta timur": "DKI Jakarta",
    "jakarta utara": "DKI Jakarta",
    "bandung": "Jawa Barat",
    "bogor": "Jawa Barat",
    "depok": "Jawa Barat",
    "bekasi": "Jawa Barat",
    "cirebon": "Jawa Barat",
    "sukabumi": "Jawa Barat",
    "tasikmalaya": "Jawa Barat",
    "cimahi": "Jawa Barat",
    "serang": "Banten",
    "tangerang": "Banten",
    "tangerang selatan": "Banten",
    "cilegon": "Banten",
    "semarang": "Jawa Tengah",
    "surakarta": "Jawa Tengah",
    "solo": "Jawa Tengah",
    "salatiga": "Jawa Tengah",
    "pekalongan": "Jawa Tengah",
    "tegal": "Jawa Tengah",
    "magelang": "Jawa Tengah",
    "purwokerto": "Jawa Tengah",
    "kudus": "Jawa Tengah",
    "sleman": "DI Yogyakarta",
    "bantul": "DI Yogyakarta",
    "surabaya": "Jawa Timur",
    "malang": "Jawa Timur",
    "batu": "Jawa Timur",
    "blitar": "Jawa Timur",
    "kediri": "Jawa Timur",
    "madiun": "Jawa Timur",
    "mojokerto": "Jawa Timur",
    "pasuruan": "Jawa Timur",
    "probolinggo": "Jawa Timur",
    "jember": "Jawa Timur",
    "banyuwangi": "Jawa Timur",
    "sidoarjo": "Jawa Timur",
    "gresik": "Jawa Timur",
    "lamongan": "Jawa Timur",
    "tulungagung": "Jawa Timur",
    "jombang": "Jawa Timur",
    "denpasar": "Bali",
    "mataram": "Nusa Tenggara Barat",
    "bima": "Nusa Tenggara Barat",
    "kupang": "Nusa Tenggara Timur",
    "maumere": "Nusa Tenggara Timur",
    "pontianak": "Kalimantan Barat",
    "palangkaraya": "Kalimantan Tengah",
    "banjarmasin": "Kalimantan Selatan",
    "banjarbaru": "Kalimantan Selatan",
    "samarinda": "Kalimantan Timur",
    "balikpapan": "Kalimantan Timur",
    "bontang": "Kalimantan Timur",
    "tarakan": "Kalimantan Utara",
    "manado": "Sulawesi Utara",
    "bitung": "Sulawesi Utara",
    "gorontalo": "Gorontalo",
    "palu": "Sulawesi Tengah",
    "mamuju": "Sulawesi Barat",
    "makassar": "Sulawesi Selatan",
    "parepare": "Sulawesi Selatan",
    "kendari": "Sulawesi Tenggara",
    "baubau": "Sulawesi Tenggara",
    "ambon": "Maluku",
    "ternate": "Maluku Utara",
    "jayapura": "Papua",
    "manokwari": "Papua Barat",
    "sorong": "Papua Barat Daya",
    "merauke": "Papua Selatan",
    "timika": "Papua Tengah",
    "wamena": "Papua Pegunungan",
    "nabire": "Papua Tengah",
}


def provinsi_dari_kota(kota: str | None) -> str | None:
    """Provinsi untuk kota Indonesia yang umum (profil lama tanpa provinsi); None bila tidak dikenal."""
    return _KOTA_PROVINSI.get(kunci(kota))


def negara_kanonik(teks: str | None) -> str | None:
    """Nama negara baku bila dikenal (mis. "Singapore" menjadi "Singapura"), selain itu None."""
    return _KUNCI_NEGARA.get(kunci(teks))


def provinsi_kanonik(teks: str | None) -> str | None:
    """Nama provinsi Indonesia baku bila dikenal (mis. "Jatim" menjadi "Jawa Timur"), selain itu None."""
    return _KUNCI_PROVINSI.get(kunci(teks))


def referensi() -> dict:
    return {"negara": list(NEGARA_UMUM), "provinsi": list(PROVINSI_INDONESIA), "negara_asal": NEGARA_ASAL}


@dataclass(frozen=True)
class Wilayah:
    negara: str | None = None
    provinsi: str | None = None
    kota: str | None = None
    # wilayah tambahan (mis. daerah asal) yang juga boleh memenuhi syarat provinsi atau kota
    tambahan: tuple[str, ...] = ()

    def kosong(self) -> bool:
        return not (self.negara or self.provinsi or self.kota or self.tambahan)


COCOK = "cocok"
BEDA = "beda"
TAK_TAHU = "tidak_diketahui"


def _bagian(syarat: str) -> list[str]:
    potongan = re.split(r"\s*(?:,|;|/|\bdan\b|\batau\b|\band\b|\bor\b)\s*", syarat.strip(), flags=re.IGNORECASE)
    return [p for p in potongan if p.strip()]


def _cocok_satu(bagian: str, w: Wilayah) -> str:
    k = kunci(bagian)
    if not k:
        return TAK_TAHU
    negara_w = negara_kanonik(w.negara)
    provinsi_w = provinsi_kanonik(w.provinsi)
    if provinsi_w is None and (negara_w is None or negara_w == NEGARA_ASAL):
        provinsi_w = provinsi_dari_kota(w.kota)
    if negara_w is None and provinsi_w:
        negara_w = NEGARA_ASAL  # provinsi Indonesia dikenal berarti negaranya Indonesia
    tambahan = [kunci(t) for t in w.tambahan if t]

    n = negara_kanonik(bagian)
    p = provinsi_kanonik(bagian)
    # Provinsi diutamakan ("Papua"); "Papua Nugini" tetap negara karena kuncinya berbeda.
    if p:
        if provinsi_w == p or any(provinsi_kanonik(t) == p for t in w.tambahan):
            return COCOK
        if provinsi_w:
            return BEDA
        if negara_w and negara_w != NEGARA_ASAL:
            return BEDA  # berdomisili di luar Indonesia, tidak mungkin di provinsi Indonesia
        return TAK_TAHU
    if n:
        if negara_w:
            return COCOK if negara_w == n else BEDA
        return TAK_TAHU
    # selain itu dianggap nama kota atau kabupaten
    if k in tambahan:
        return COCOK
    if w.kota and kunci(w.kota):
        return COCOK if kunci(w.kota) == k else BEDA
    return TAK_TAHU


def cocok_wilayah(syarat: str, w: Wilayah) -> str:
    """COCOK, BEDA, atau TAK_TAHU untuk satu butir syarat domisili terhadap wilayah pengguna.

    Butir majemuk ("Jawa Timur dan Jawa Tengah") dipecah; cocok pada salah satu sudah cukup. Nama wilayah di dalam
    kalimat pendek ("Warga Kota Malang") dicari lewat kata utuh.
    """
    bagian = _bagian(syarat)
    hasil = [_cocok_satu(b, w) for b in bagian]
    if COCOK in hasil:
        return COCOK
    # Pencarian kata utuh hanya untuk kalimat bebas; nama negara atau provinsi yang dikenal sudah dinilai di atas
    # (menjaga "Papua New Guinea" tidak cocok dengan provinsi Papua).
    if not any(negara_kanonik(b) or provinsi_kanonik(b) for b in bagian):
        k = kunci(syarat)
        for nilai in (w.kota, w.provinsi, w.negara, *w.tambahan):
            kn = kunci(nilai)
            if len(kn) >= 4 and re.search(rf"\b{re.escape(kn)}\b", k):
                return COCOK
    if BEDA in hasil:
        return BEDA
    return TAK_TAHU

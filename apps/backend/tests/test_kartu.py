from app.services.kartu import luar_negeri, metrik, sesuai_wilayah


def test_luar_negeri_hanya_bila_negara_tercatat_dan_bukan_indonesia():
    assert luar_negeri("Jepang") is True
    assert luar_negeri("Indonesia") is False
    assert luar_negeri("Indonesia dan Malaysia") is False
    assert luar_negeri(None) is False
    assert luar_negeri("  ") is False


def test_sesuai_wilayah():
    assert sesuai_wilayah("Jepang", "luar") and not sesuai_wilayah("Jepang", "dalam")
    assert sesuai_wilayah(None, "dalam") and not sesuai_wilayah(None, "luar")
    assert sesuai_wilayah("Jepang", None)


def test_metrik_menghitung_persen_dan_syarat():
    m = metrik(0.82, ["IPK 3,55 memenuhi", "Jenjang sesuai"], ["Perlu skor TOEFL 550"])
    assert m == {"skor_kelayakan": 82, "syarat_terpenuhi": 2, "syarat_total": 3}


def test_metrik_tanpa_syarat_terukur_tidak_diberi_angka():
    kosong = {"skor_kelayakan": None, "syarat_terpenuhi": 0, "syarat_total": 0}
    assert metrik(0.4, [], ["Syarat belum tercatat, periksa laman resmi"]) == kosong
    assert metrik(0.5, ["Jenjang S1 sesuai"], ["Hanya jenjang yang tercatat, periksa syarat lain di laman resmi"]) == kosong
    assert metrik(None, ["x"], []) == kosong


def test_metrik_dibatasi_0_sampai_100():
    assert metrik(1.2, ["a"], [])["skor_kelayakan"] == 100
    assert metrik(0.0, [], ["gagal"])["skor_kelayakan"] == 0


def test_metrik_tidak_menghitung_kalimat_minat_dan_penjelasan_urutan_sebagai_syarat():
    from app.services.kartu import metrik

    m = metrik(
        1.0,
        ["Jenjang S1 sesuai", "Minat dan program studi mirip dengan fokus beasiswa", "Urutan dipengaruhi oleh skor"],
        [],
    )
    assert (m["syarat_terpenuhi"], m["syarat_total"]) == (1, 1)

"""Menyimpan hasil ekstraksi. Upsert berdasarkan (sumber_id, sidik_isi); tidak menghapus apa pun."""

import os
from datetime import UTC, date, datetime
from urllib.parse import urljoin

from sqlalchemy import create_engine, text

from smart_crawler.uinmalang import URL_SUMBER, BarisBeasiswa, sidik
from smart_crawler.validasi import tentukan_status


def tautan_mutlak(b: BarisBeasiswa) -> str:
    return urljoin(URL_SUMBER + "/", b.tautan) if b.tautan else URL_SUMBER


def simpan(url_db: str, baris: list[BarisBeasiswa], hari_ini: date | None = None) -> dict[str, int]:
    hari_ini = hari_ini or date.today()
    mesin = create_engine(url_db, pool_pre_ping=True)
    ringkas = {"baru": 0, "diperbarui": 0}
    with mesin.begin() as k:
        sumber_id = k.execute(text("select id from sumber where url = :u"), {"u": URL_SUMBER}).scalar()
        if sumber_id is None:
            raise RuntimeError("Sumber belum ada. Jalankan scripts.seed_sumber lebih dulu.")
        for b in baris:
            status, alasan = tentukan_status(None, hari_ini, tautan_mutlak(b))
            alasan = (
                f"{alasan}. Pelaksanaan perkiraan: {b.pelaksanaan or 'tidak tertulis'}" if alasan else alasan
            )
            hasil = k.execute(
                text(
                    """insert into beasiswa (sumber_id, nama, penyelenggara, negara, jenjang, tautan_resmi,
                    tanggal_diperiksa, status, alasan_ditandai, sidik_isi)
                    values (:s, :n, 'Kemahasiswaan UIN Malang', 'Indonesia', :j, :t, :w, :st, :a, :h)
                    on conflict (sumber_id, sidik_isi) do update
                      set tanggal_diperiksa = excluded.tanggal_diperiksa,
                      tautan_resmi = excluded.tautan_resmi
                    returning id, (xmax = 0) as baru"""
                ),
                {
                    "s": sumber_id,
                    "n": b.nama,
                    "j": b.jenjang or None,
                    "t": tautan_mutlak(b),
                    "w": datetime.now(UTC),
                    "st": status,
                    "a": alasan,
                    "h": sidik(b),
                },
            ).one()
            ringkas["baru" if hasil.baru else "diperbarui"] += 1
            if hasil.baru and b.kriteria:
                k.execute(
                    text(
                        "insert into persyaratan (beasiswa_id, jenis, nilai_batas, dapat_dikejar) "
                        "values (:i, 'lainnya', cast(:v as jsonb), false)"
                    ),
                    {"i": hasil.id, "v": '{"teks": ' + _json(b.kriteria) + "}"},
                )
        k.execute(text("update sumber set status_terakhir = 'berhasil' where id = :i"), {"i": sumber_id})
    mesin.dispose()
    return ringkas


def _json(s: str) -> str:
    import json

    return json.dumps(s, ensure_ascii=False)


def url_db_dari_env() -> str:
    url = os.environ.get("DATABASE_URL", "")
    if not url:
        raise RuntimeError("DATABASE_URL belum diatur")
    return url

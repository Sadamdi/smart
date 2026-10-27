"""Model 13 tabel SMART. Sumber: Dokument/01-Arsitektur/02-SKEMA-DATABASE.md dan Dokumen Perancangan DP-SM-001.

Enumerasi disimpan sebagai text dengan CheckConstraint (bukan tipe enum) agar nilai baru mudah ditambahkan lewat migrasi.
"""

import uuid
from datetime import date, datetime
from decimal import Decimal

from pgvector.sqlalchemy import Vector
from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    SmallInteger,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import DIMENSI_VEKTOR, Base, IdMixin, WaktuMixin


def _fk(tabel: str, **kw):
    return mapped_column(
        UUID(as_uuid=True), ForeignKey(f"{tabel}.id", ondelete="CASCADE"), nullable=False, **kw
    )


class Pengguna(IdMixin, WaktuMixin, Base):
    __tablename__ = "pengguna"
    __table_args__ = (
        CheckConstraint("peran in ('mahasiswa','admin')", name="peran"),
        CheckConstraint("jenis_kampus is null or jenis_kampus in ('negeri','swasta')", name="jenis_kampus"),
        CheckConstraint("jenjang is null or jenjang in ('D3','D4','S1','S2','S3')", name="jenjang"),
        CheckConstraint("semester is null or semester between 1 and 14", name="semester"),
        CheckConstraint("ipk is null or ipk between 0 and 4", name="ipk"),
        CheckConstraint("ips_terakhir is null or ips_terakhir between 0 and 4", name="ips_terakhir"),
    )

    email: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    kata_sandi: Mapped[str] = mapped_column(Text, nullable=False)
    peran: Mapped[str] = mapped_column(Text, nullable=False, server_default="mahasiswa")
    nama: Mapped[str] = mapped_column(Text, nullable=False)
    tanggal_lahir: Mapped[date | None] = mapped_column(Date)
    kota_domisili: Mapped[str | None] = mapped_column(Text)
    kampus: Mapped[str | None] = mapped_column(Text)
    jenis_kampus: Mapped[str | None] = mapped_column(Text)
    program_studi: Mapped[str | None] = mapped_column(Text)
    jenjang: Mapped[str | None] = mapped_column(Text)
    semester: Mapped[int | None] = mapped_column(SmallInteger)
    ipk: Mapped[Decimal | None] = mapped_column(Numeric(3, 2))
    ips_terakhir: Mapped[Decimal | None] = mapped_column(Numeric(3, 2))
    minat: Mapped[list[str] | None] = mapped_column(ARRAY(Text))
    # kolom opsional untuk aturan kelayakan (keputusan 26 Oktober 2026)
    penghasilan_orang_tua: Mapped[int | None] = mapped_column()
    skor_bahasa: Mapped[dict | None] = mapped_column(JSONB)
    kewarganegaraan: Mapped[str | None] = mapped_column(Text)
    vektor_profil = mapped_column(Vector(DIMENSI_VEKTOR))
    preferensi_notifikasi: Mapped[dict] = mapped_column(
        JSONB, nullable=False, server_default=text('\'{"email": true, "push": true}\'::jsonb')
    )


class DokumenPengguna(IdMixin, WaktuMixin, Base):
    __tablename__ = "dokumen_pengguna"
    __table_args__ = (
        CheckConstraint("jenis in ('cv','sertifikat','pengalaman_organisasi')", name="jenis"),
        CheckConstraint("status_baca in ('menunggu','selesai','gagal')", name="status_baca"),
        Index("ix_dokumen_pengguna_pengguna_id", "pengguna_id"),
    )

    pengguna_id: Mapped[uuid.UUID] = _fk("pengguna")
    jenis: Mapped[str] = mapped_column(Text, nullable=False)
    nama_berkas: Mapped[str] = mapped_column(Text, nullable=False)
    lokasi_penyimpanan: Mapped[str] = mapped_column(Text, nullable=False)
    hasil_baca: Mapped[dict | None] = mapped_column(JSONB)
    status_baca: Mapped[str] = mapped_column(Text, nullable=False, server_default="menunggu")
    tanggal_unggah: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()"), nullable=False
    )


class Sumber(IdMixin, WaktuMixin, Base):
    __tablename__ = "sumber"
    __table_args__ = (
        CheckConstraint(
            "jenis in ('pantau_otomatis','tautan_keluar','input_manual','rujukan')", name="jenis"
        ),
        CheckConstraint("status_terakhir in ('berhasil','gagal','belum_pernah')", name="status_terakhir"),
    )

    nama: Mapped[str] = mapped_column(Text, nullable=False)
    url: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    jenis: Mapped[str] = mapped_column(Text, nullable=False)
    negara: Mapped[str | None] = mapped_column(Text)
    jadwal: Mapped[str | None] = mapped_column(Text)  # ekspresi cron, kosong bila tidak dipantau
    status_terakhir: Mapped[str] = mapped_column(Text, nullable=False, server_default="belum_pernah")
    aktif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))


class Beasiswa(IdMixin, WaktuMixin, Base):
    __tablename__ = "beasiswa"
    __table_args__ = (
        CheckConstraint("status in ('menunggu_validasi','terbit','kedaluwarsa','ditolak')", name="status"),
        UniqueConstraint("sumber_id", "sidik_isi", name="uq_beasiswa_sumber_id_sidik_isi"),
        Index("ix_beasiswa_status_tenggat", "status", "tenggat"),
        Index("ix_beasiswa_sumber_id", "sumber_id"),
        Index(
            "ix_beasiswa_vektor",
            "vektor",
            postgresql_using="hnsw",
            postgresql_with={"m": 16, "ef_construction": 64},
            postgresql_ops={"vektor": "vector_cosine_ops"},
        ),
    )

    sumber_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("sumber.id"), nullable=False)
    nama: Mapped[str] = mapped_column(Text, nullable=False)
    penyelenggara: Mapped[str | None] = mapped_column(Text)
    negara: Mapped[str | None] = mapped_column(Text)
    jenjang: Mapped[list[str] | None] = mapped_column(ARRAY(Text))
    manfaat: Mapped[str | None] = mapped_column(Text)
    tenggat: Mapped[date | None] = mapped_column(Date)
    tautan_resmi: Mapped[str] = mapped_column(Text, nullable=False)
    tanggal_diperiksa: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default="menunggu_validasi")
    alasan_ditandai: Mapped[str | None] = mapped_column(Text)
    sidik_isi: Mapped[str | None] = mapped_column(Text)
    vektor = mapped_column(Vector(DIMENSI_VEKTOR))


class Persyaratan(IdMixin, WaktuMixin, Base):
    __tablename__ = "persyaratan"
    __table_args__ = (
        CheckConstraint(
            "jenis in ('ipk_minimum','semester_minimum','semester_maksimum','jenjang','jenis_kampus','domisili',"
            "'usia_maksimum','sertifikat_bahasa','penghasilan_maksimum','kewarganegaraan','berkas_pendukung','lainnya')",
            name="jenis",
        ),
        Index("ix_persyaratan_beasiswa_id", "beasiswa_id"),
    )

    beasiswa_id: Mapped[uuid.UUID] = _fk("beasiswa")
    jenis: Mapped[str] = mapped_column(Text, nullable=False)
    nilai_batas: Mapped[dict | None] = mapped_column(JSONB)
    dapat_dikejar: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))


class BerkasWajib(IdMixin, WaktuMixin, Base):
    __tablename__ = "berkas_wajib"
    __table_args__ = (Index("ix_berkas_wajib_beasiswa_id", "beasiswa_id"),)

    beasiswa_id: Mapped[uuid.UUID] = _fk("beasiswa")
    nama_berkas: Mapped[str] = mapped_column(Text, nullable=False)


class ChecklistPengguna(IdMixin, WaktuMixin, Base):
    __tablename__ = "checklist_pengguna"
    __table_args__ = (
        UniqueConstraint("pengguna_id", "berkas_wajib_id", name="uq_checklist_pengguna_pengguna_berkas"),
    )

    pengguna_id: Mapped[uuid.UUID] = _fk("pengguna")
    berkas_wajib_id: Mapped[uuid.UUID] = _fk("berkas_wajib")
    selesai: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))


class Rekomendasi(IdMixin, WaktuMixin, Base):
    __tablename__ = "rekomendasi"
    __table_args__ = (
        CheckConstraint("kategori in ('memenuhi','hampir_memenuhi','belum_memenuhi')", name="kategori"),
        CheckConstraint("skor between 0 and 1", name="skor"),
        UniqueConstraint("pengguna_id", "beasiswa_id", name="uq_rekomendasi_pengguna_beasiswa"),
        Index("ix_rekomendasi_pengguna_kategori", "pengguna_id", "kategori"),
    )

    pengguna_id: Mapped[uuid.UUID] = _fk("pengguna")
    beasiswa_id: Mapped[uuid.UUID] = _fk("beasiswa")
    skor: Mapped[Decimal] = mapped_column(Numeric(5, 4), nullable=False)
    skor_kelayakan: Mapped[Decimal | None] = mapped_column(Numeric(5, 4))
    skor_kemiripan: Mapped[Decimal | None] = mapped_column(Numeric(5, 4))
    kategori: Mapped[str] = mapped_column(Text, nullable=False)
    alasan: Mapped[list | None] = mapped_column(JSONB)
    catatan_kekurangan: Mapped[list | None] = mapped_column(JSONB)
    versi_model: Mapped[str | None] = mapped_column(Text)


class Interaksi(IdMixin, WaktuMixin, Base):
    __tablename__ = "interaksi"
    __table_args__ = (
        CheckConstraint("aksi in ('klik','simpan','rencana_daftar')", name="aksi"),
        CheckConstraint(
            "status_rencana is null or status_rencana in ('akan_daftar','sudah_daftar','tidak_jadi')",
            name="status_rencana",
        ),
        Index("ix_interaksi_pengguna_beasiswa", "pengguna_id", "beasiswa_id"),
    )

    pengguna_id: Mapped[uuid.UUID] = _fk("pengguna")
    beasiswa_id: Mapped[uuid.UUID] = _fk("beasiswa")
    aksi: Mapped[str] = mapped_column(Text, nullable=False)
    status_rencana: Mapped[str | None] = mapped_column(Text)
    waktu: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()"), nullable=False
    )


class Notifikasi(IdMixin, WaktuMixin, Base):
    __tablename__ = "notifikasi"
    __table_args__ = (
        CheckConstraint("jenis in ('tenggat','beasiswa_baru')", name="jenis"),
        CheckConstraint("kanal in ('email','push')", name="kanal"),
        # satu pengingat per pengguna, beasiswa, jenis, kanal, dan tanggal acuan agar tidak terkirim ganda
        UniqueConstraint(
            "pengguna_id", "beasiswa_id", "jenis", "kanal", "tanggal_acuan", name="uq_notifikasi_pengingat"
        ),
        Index("ix_notifikasi_pengguna_dibaca", "pengguna_id", "dibaca"),
    )

    pengguna_id: Mapped[uuid.UUID] = _fk("pengguna")
    beasiswa_id: Mapped[uuid.UUID] = _fk("beasiswa")
    jenis: Mapped[str] = mapped_column(Text, nullable=False)
    kanal: Mapped[str] = mapped_column(Text, nullable=False)
    tanggal_acuan: Mapped[date] = mapped_column(Date, nullable=False)
    waktu_kirim: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    dibaca: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))


class Percakapan(IdMixin, WaktuMixin, Base):
    __tablename__ = "percakapan"
    __table_args__ = (
        CheckConstraint("char_length(pesan) <= 2000", name="pesan_maks"),
        Index("ix_percakapan_pengguna_id", "pengguna_id"),
    )

    pengguna_id: Mapped[uuid.UUID] = _fk("pengguna")
    pesan: Mapped[str] = mapped_column(Text, nullable=False)
    jawaban: Mapped[str | None] = mapped_column(Text)
    rujukan_beasiswa_id: Mapped[list[uuid.UUID] | None] = mapped_column(ARRAY(UUID(as_uuid=True)))
    waktu: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()"), nullable=False
    )


class TugasPribadi(IdMixin, WaktuMixin, Base):
    __tablename__ = "tugas_pribadi"
    __table_args__ = (Index("ix_tugas_pribadi_pengguna_tanggal", "pengguna_id", "tanggal"),)

    pengguna_id: Mapped[uuid.UUID] = _fk("pengguna")
    judul: Mapped[str] = mapped_column(Text, nullable=False)
    tanggal: Mapped[date] = mapped_column(Date, nullable=False)
    selesai: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))


class PerangkatPush(IdMixin, WaktuMixin, Base):
    __tablename__ = "perangkat_push"
    __table_args__ = (
        CheckConstraint("platform in ('android','ios','web')", name="platform"),
        UniqueConstraint("token", name="uq_perangkat_push_token"),
        Index("ix_perangkat_push_pengguna_id", "pengguna_id"),
    )

    pengguna_id: Mapped[uuid.UUID] = _fk("pengguna")
    token: Mapped[str] = mapped_column(Text, nullable=False)
    platform: Mapped[str] = mapped_column(Text, nullable=False)
    aktif: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))


TABEL_SMART = [
    "pengguna",
    "dokumen_pengguna",
    "sumber",
    "beasiswa",
    "persyaratan",
    "berkas_wajib",
    "checklist_pengguna",
    "rekomendasi",
    "interaksi",
    "notifikasi",
    "percakapan",
    "tugas_pribadi",
    "perangkat_push",
]

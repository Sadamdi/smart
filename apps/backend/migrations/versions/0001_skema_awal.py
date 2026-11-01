"""skema awal 13 tabel SMART

Revision ID: 0001
Revises:
Create Date: 2026-10-27

DDL ditulis eksplisit (dibangkitkan dari model saat pembuatan) agar migrasi ini tetap sama walau model berubah.
Perubahan skema berikutnya ditulis sebagai migrasi baru, jangan mengubah berkas ini setelah dijalankan.
"""

from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")
    op.execute("""
CREATE TABLE pengguna (
	email TEXT NOT NULL, 
	kata_sandi TEXT NOT NULL, 
	peran TEXT DEFAULT 'mahasiswa' NOT NULL, 
	nama TEXT NOT NULL, 
	tanggal_lahir DATE, 
	kota_domisili TEXT, 
	kampus TEXT, 
	jenis_kampus TEXT, 
	program_studi TEXT, 
	jenjang TEXT, 
	semester SMALLINT, 
	ipk NUMERIC(3, 2), 
	ips_terakhir NUMERIC(3, 2), 
	minat TEXT[], 
	penghasilan_orang_tua INTEGER, 
	skor_bahasa JSONB, 
	kewarganegaraan TEXT, 
	vektor_profil VECTOR(384), 
	preferensi_notifikasi JSONB DEFAULT '{"email": true, "push": true}'::jsonb NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_pengguna PRIMARY KEY (id), 
	CONSTRAINT ck_pengguna_peran CHECK (peran in ('mahasiswa','admin')), 
	CONSTRAINT ck_pengguna_jenis_kampus CHECK (jenis_kampus is null or jenis_kampus in ('negeri','swasta')), 
	CONSTRAINT ck_pengguna_jenjang CHECK (jenjang is null or jenjang in ('D3','D4','S1','S2','S3')), 
	CONSTRAINT ck_pengguna_semester CHECK (semester is null or semester between 1 and 14), 
	CONSTRAINT ck_pengguna_ipk CHECK (ipk is null or ipk between 0 and 4), 
	CONSTRAINT ck_pengguna_ips_terakhir CHECK (ips_terakhir is null or ips_terakhir between 0 and 4), 
	CONSTRAINT uq_pengguna_email UNIQUE (email)
)
""")
    op.execute("""
CREATE TABLE sumber (
	nama TEXT NOT NULL, 
	url TEXT NOT NULL, 
	jenis TEXT NOT NULL, 
	negara TEXT, 
	jadwal TEXT, 
	status_terakhir TEXT DEFAULT 'belum_pernah' NOT NULL, 
	aktif BOOLEAN DEFAULT true NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_sumber PRIMARY KEY (id), 
	CONSTRAINT ck_sumber_jenis CHECK (jenis in ('pantau_otomatis','tautan_keluar','input_manual','rujukan')), 
	CONSTRAINT ck_sumber_status_terakhir CHECK (status_terakhir in ('berhasil','gagal','belum_pernah')), 
	CONSTRAINT uq_sumber_url UNIQUE (url)
)
""")
    op.execute("""
CREATE TABLE beasiswa (
	sumber_id UUID NOT NULL, 
	nama TEXT NOT NULL, 
	penyelenggara TEXT, 
	negara TEXT, 
	jenjang TEXT[], 
	manfaat TEXT, 
	tenggat DATE, 
	tautan_resmi TEXT NOT NULL, 
	tanggal_diperiksa TIMESTAMP WITH TIME ZONE, 
	status TEXT DEFAULT 'menunggu_validasi' NOT NULL, 
	alasan_ditandai TEXT, 
	sidik_isi TEXT, 
	vektor VECTOR(384), 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_beasiswa PRIMARY KEY (id), 
	CONSTRAINT ck_beasiswa_status CHECK (status in ('menunggu_validasi','terbit','kedaluwarsa','ditolak')), 
	CONSTRAINT uq_beasiswa_sumber_id_sidik_isi UNIQUE (sumber_id, sidik_isi), 
	CONSTRAINT fk_beasiswa_sumber_id_sumber FOREIGN KEY(sumber_id) REFERENCES sumber (id)
)
""")
    op.execute("""
CREATE INDEX ix_beasiswa_status_tenggat ON beasiswa (status, tenggat)
""")
    op.execute("""
CREATE INDEX ix_beasiswa_sumber_id ON beasiswa (sumber_id)
""")
    op.execute("""
CREATE INDEX ix_beasiswa_vektor ON beasiswa USING hnsw (vektor vector_cosine_ops) WITH (m = 16, ef_construction = 64)
""")
    op.execute("""
CREATE TABLE dokumen_pengguna (
	pengguna_id UUID NOT NULL, 
	jenis TEXT NOT NULL, 
	nama_berkas TEXT NOT NULL, 
	lokasi_penyimpanan TEXT NOT NULL, 
	hasil_baca JSONB, 
	status_baca TEXT DEFAULT 'menunggu' NOT NULL, 
	tanggal_unggah TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_dokumen_pengguna PRIMARY KEY (id), 
	CONSTRAINT ck_dokumen_pengguna_jenis CHECK (jenis in ('cv','sertifikat','pengalaman_organisasi')), 
	CONSTRAINT ck_dokumen_pengguna_status_baca CHECK (status_baca in ('menunggu','selesai','gagal')), 
	CONSTRAINT fk_dokumen_pengguna_pengguna_id_pengguna FOREIGN KEY(pengguna_id) REFERENCES pengguna (id) ON DELETE CASCADE
)
""")
    op.execute("""
CREATE INDEX ix_dokumen_pengguna_pengguna_id ON dokumen_pengguna (pengguna_id)
""")
    op.execute("""
CREATE TABLE perangkat_push (
	pengguna_id UUID NOT NULL, 
	token TEXT NOT NULL, 
	platform TEXT NOT NULL, 
	aktif BOOLEAN DEFAULT true NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_perangkat_push PRIMARY KEY (id), 
	CONSTRAINT ck_perangkat_push_platform CHECK (platform in ('android','ios','web')), 
	CONSTRAINT uq_perangkat_push_token UNIQUE (token), 
	CONSTRAINT fk_perangkat_push_pengguna_id_pengguna FOREIGN KEY(pengguna_id) REFERENCES pengguna (id) ON DELETE CASCADE
)
""")
    op.execute("""
CREATE INDEX ix_perangkat_push_pengguna_id ON perangkat_push (pengguna_id)
""")
    op.execute("""
CREATE TABLE percakapan (
	pengguna_id UUID NOT NULL, 
	pesan TEXT NOT NULL, 
	jawaban TEXT, 
	rujukan_beasiswa_id UUID[], 
	waktu TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_percakapan PRIMARY KEY (id), 
	CONSTRAINT ck_percakapan_pesan_maks CHECK (char_length(pesan) <= 2000), 
	CONSTRAINT fk_percakapan_pengguna_id_pengguna FOREIGN KEY(pengguna_id) REFERENCES pengguna (id) ON DELETE CASCADE
)
""")
    op.execute("""
CREATE INDEX ix_percakapan_pengguna_id ON percakapan (pengguna_id)
""")
    op.execute("""
CREATE TABLE tugas_pribadi (
	pengguna_id UUID NOT NULL, 
	judul TEXT NOT NULL, 
	tanggal DATE NOT NULL, 
	selesai BOOLEAN DEFAULT false NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_tugas_pribadi PRIMARY KEY (id), 
	CONSTRAINT fk_tugas_pribadi_pengguna_id_pengguna FOREIGN KEY(pengguna_id) REFERENCES pengguna (id) ON DELETE CASCADE
)
""")
    op.execute("""
CREATE INDEX ix_tugas_pribadi_pengguna_tanggal ON tugas_pribadi (pengguna_id, tanggal)
""")
    op.execute("""
CREATE TABLE berkas_wajib (
	beasiswa_id UUID NOT NULL, 
	nama_berkas TEXT NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_berkas_wajib PRIMARY KEY (id), 
	CONSTRAINT fk_berkas_wajib_beasiswa_id_beasiswa FOREIGN KEY(beasiswa_id) REFERENCES beasiswa (id) ON DELETE CASCADE
)
""")
    op.execute("""
CREATE INDEX ix_berkas_wajib_beasiswa_id ON berkas_wajib (beasiswa_id)
""")
    op.execute("""
CREATE TABLE interaksi (
	pengguna_id UUID NOT NULL, 
	beasiswa_id UUID NOT NULL, 
	aksi TEXT NOT NULL, 
	status_rencana TEXT, 
	waktu TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_interaksi PRIMARY KEY (id), 
	CONSTRAINT ck_interaksi_aksi CHECK (aksi in ('klik','simpan','rencana_daftar')), 
	CONSTRAINT ck_interaksi_status_rencana CHECK (status_rencana is null or status_rencana in ('akan_daftar','sudah_daftar','tidak_jadi')), 
	CONSTRAINT fk_interaksi_pengguna_id_pengguna FOREIGN KEY(pengguna_id) REFERENCES pengguna (id) ON DELETE CASCADE, 
	CONSTRAINT fk_interaksi_beasiswa_id_beasiswa FOREIGN KEY(beasiswa_id) REFERENCES beasiswa (id) ON DELETE CASCADE
)
""")
    op.execute("""
CREATE INDEX ix_interaksi_pengguna_beasiswa ON interaksi (pengguna_id, beasiswa_id)
""")
    op.execute("""
CREATE TABLE notifikasi (
	pengguna_id UUID NOT NULL, 
	beasiswa_id UUID NOT NULL, 
	jenis TEXT NOT NULL, 
	kanal TEXT NOT NULL, 
	tanggal_acuan DATE NOT NULL, 
	waktu_kirim TIMESTAMP WITH TIME ZONE, 
	dibaca BOOLEAN DEFAULT false NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_notifikasi PRIMARY KEY (id), 
	CONSTRAINT ck_notifikasi_jenis CHECK (jenis in ('tenggat','beasiswa_baru')), 
	CONSTRAINT ck_notifikasi_kanal CHECK (kanal in ('email','push')), 
	CONSTRAINT uq_notifikasi_pengingat UNIQUE (pengguna_id, beasiswa_id, jenis, kanal, tanggal_acuan), 
	CONSTRAINT fk_notifikasi_pengguna_id_pengguna FOREIGN KEY(pengguna_id) REFERENCES pengguna (id) ON DELETE CASCADE, 
	CONSTRAINT fk_notifikasi_beasiswa_id_beasiswa FOREIGN KEY(beasiswa_id) REFERENCES beasiswa (id) ON DELETE CASCADE
)
""")
    op.execute("""
CREATE INDEX ix_notifikasi_pengguna_dibaca ON notifikasi (pengguna_id, dibaca)
""")
    op.execute("""
CREATE TABLE persyaratan (
	beasiswa_id UUID NOT NULL, 
	jenis TEXT NOT NULL, 
	nilai_batas JSONB, 
	dapat_dikejar BOOLEAN DEFAULT false NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_persyaratan PRIMARY KEY (id), 
	CONSTRAINT ck_persyaratan_jenis CHECK (jenis in ('ipk_minimum','semester_minimum','semester_maksimum','jenjang','jenis_kampus','domisili','usia_maksimum','sertifikat_bahasa','penghasilan_maksimum','kewarganegaraan','berkas_pendukung','lainnya')), 
	CONSTRAINT fk_persyaratan_beasiswa_id_beasiswa FOREIGN KEY(beasiswa_id) REFERENCES beasiswa (id) ON DELETE CASCADE
)
""")
    op.execute("""
CREATE INDEX ix_persyaratan_beasiswa_id ON persyaratan (beasiswa_id)
""")
    op.execute("""
CREATE TABLE rekomendasi (
	pengguna_id UUID NOT NULL, 
	beasiswa_id UUID NOT NULL, 
	skor NUMERIC(5, 4) NOT NULL, 
	skor_kelayakan NUMERIC(5, 4), 
	skor_kemiripan NUMERIC(5, 4), 
	kategori TEXT NOT NULL, 
	alasan JSONB, 
	catatan_kekurangan JSONB, 
	versi_model TEXT, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_rekomendasi PRIMARY KEY (id), 
	CONSTRAINT ck_rekomendasi_kategori CHECK (kategori in ('memenuhi','hampir_memenuhi','belum_memenuhi')), 
	CONSTRAINT ck_rekomendasi_skor CHECK (skor between 0 and 1), 
	CONSTRAINT uq_rekomendasi_pengguna_beasiswa UNIQUE (pengguna_id, beasiswa_id), 
	CONSTRAINT fk_rekomendasi_pengguna_id_pengguna FOREIGN KEY(pengguna_id) REFERENCES pengguna (id) ON DELETE CASCADE, 
	CONSTRAINT fk_rekomendasi_beasiswa_id_beasiswa FOREIGN KEY(beasiswa_id) REFERENCES beasiswa (id) ON DELETE CASCADE
)
""")
    op.execute("""
CREATE INDEX ix_rekomendasi_pengguna_kategori ON rekomendasi (pengguna_id, kategori)
""")
    op.execute("""
CREATE TABLE checklist_pengguna (
	pengguna_id UUID NOT NULL, 
	berkas_wajib_id UUID NOT NULL, 
	selesai BOOLEAN DEFAULT false NOT NULL, 
	id UUID DEFAULT gen_random_uuid() NOT NULL, 
	dibuat_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	diubah_pada TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	CONSTRAINT pk_checklist_pengguna PRIMARY KEY (id), 
	CONSTRAINT uq_checklist_pengguna_pengguna_berkas UNIQUE (pengguna_id, berkas_wajib_id), 
	CONSTRAINT fk_checklist_pengguna_pengguna_id_pengguna FOREIGN KEY(pengguna_id) REFERENCES pengguna (id) ON DELETE CASCADE, 
	CONSTRAINT fk_checklist_pengguna_berkas_wajib_id_berkas_wajib FOREIGN KEY(berkas_wajib_id) REFERENCES berkas_wajib (id) ON DELETE CASCADE
)
""")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS checklist_pengguna CASCADE")
    op.execute("DROP TABLE IF EXISTS rekomendasi CASCADE")
    op.execute("DROP TABLE IF EXISTS persyaratan CASCADE")
    op.execute("DROP TABLE IF EXISTS notifikasi CASCADE")
    op.execute("DROP TABLE IF EXISTS interaksi CASCADE")
    op.execute("DROP TABLE IF EXISTS berkas_wajib CASCADE")
    op.execute("DROP TABLE IF EXISTS tugas_pribadi CASCADE")
    op.execute("DROP TABLE IF EXISTS percakapan CASCADE")
    op.execute("DROP TABLE IF EXISTS perangkat_push CASCADE")
    op.execute("DROP TABLE IF EXISTS dokumen_pengguna CASCADE")
    op.execute("DROP TABLE IF EXISTS beasiswa CASCADE")
    op.execute("DROP TABLE IF EXISTS sumber CASCADE")
    op.execute("DROP TABLE IF EXISTS pengguna CASCADE")

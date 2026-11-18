"""tabel memori_pengguna: fakta tentang pengguna dari dokumen dan percakapan untuk chatbot dan rekomendasi

Revision ID: 0007
Revises: 0006
Create Date: 2026-11-18
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0007"
down_revision = "0006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "memori_pengguna",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("dibuat_pada", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("diubah_pada", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column(
            "pengguna_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("pengguna.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("jenis", sa.Text(), nullable=False),
        sa.Column("isi", sa.Text(), nullable=False),
        sa.Column("sumber", sa.Text()),
        sa.CheckConstraint(
            "jenis in ('keahlian','prestasi','organisasi','sertifikat','pengalaman','minat','kepribadian','lainnya')",
            name="ck_memori_pengguna_jenis",
        ),
        sa.CheckConstraint("char_length(isi) <= 500", name="ck_memori_pengguna_isi_maks"),
    )
    op.create_index("ix_memori_pengguna_pengguna_id", "memori_pengguna", ["pengguna_id"])


def downgrade() -> None:
    op.drop_index("ix_memori_pengguna_pengguna_id", table_name="memori_pengguna")
    op.drop_table("memori_pengguna")

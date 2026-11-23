"""sesi chat: tabel sesi_chat dan kolom sesi_id pada percakapan (riwayat lama dikelompokkan ke satu sesi)

Revision ID: 0009
Revises: 0008
Create Date: 2026-11-22
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0009"
down_revision = "0008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "sesi_chat",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("dibuat_pada", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("diubah_pada", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column(
            "pengguna_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("pengguna.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("judul", sa.Text(), nullable=False, server_default=sa.text("'Percakapan baru'")),
        sa.Column("judul_otomatis", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("klien_id", sa.Text()),
    )
    op.create_index("ix_sesi_chat_pengguna_id", "sesi_chat", ["pengguna_id"])
    op.create_index(
        "uq_sesi_chat_klien",
        "sesi_chat",
        ["pengguna_id", "klien_id"],
        unique=True,
        postgresql_where=sa.text("klien_id is not null"),
    )
    op.add_column(
        "percakapan",
        sa.Column("sesi_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("sesi_chat.id", ondelete="CASCADE")),
    )
    op.create_index("ix_percakapan_sesi_id", "percakapan", ["sesi_id"])
    # Riwayat lama: satu sesi per pengguna yang sudah punya percakapan.
    op.execute(
        "insert into sesi_chat (pengguna_id, judul, judul_otomatis) "
        "select distinct pengguna_id, 'Percakapan sebelumnya', false from percakapan"
    )
    op.execute("update percakapan p set sesi_id = s.id from sesi_chat s where s.pengguna_id = p.pengguna_id")


def downgrade() -> None:
    op.drop_index("ix_percakapan_sesi_id", table_name="percakapan")
    op.drop_column("percakapan", "sesi_id")
    op.drop_index("uq_sesi_chat_klien", table_name="sesi_chat")
    op.drop_index("ix_sesi_chat_pengguna_id", table_name="sesi_chat")
    op.drop_table("sesi_chat")

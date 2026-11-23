"""pembersihan otomatis: asal dan terakhir dipakai pada dokumen, terakhir dipakai pada memori

Revision ID: 0010
Revises: 0009
Create Date: 2026-11-23
"""

import sqlalchemy as sa
from alembic import op

revision = "0010"
down_revision = "0009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # asal: 'profil' (halaman Dokumen: CV, transkrip, sertifikat; tidak dihapus otomatis) atau 'chat' (lampiran chat).
    op.add_column("dokumen_pengguna", sa.Column("asal", sa.Text(), nullable=False, server_default="profil"))
    op.create_check_constraint("ck_dokumen_pengguna_asal", "dokumen_pengguna", "asal in ('profil','chat')")
    op.add_column("dokumen_pengguna", sa.Column("terakhir_dipakai", sa.DateTime(timezone=True), nullable=True))
    op.add_column("memori_pengguna", sa.Column("terakhir_dipakai", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("memori_pengguna", "terakhir_dipakai")
    op.drop_column("dokumen_pengguna", "terakhir_dipakai")
    op.drop_constraint("ck_dokumen_pengguna_asal", "dokumen_pengguna", type_="check")
    op.drop_column("dokumen_pengguna", "asal")

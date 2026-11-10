"""kolom negara_domisili dan provinsi_domisili pada pengguna (domisili terstruktur: negara, provinsi, kota)

Revision ID: 0006
Revises: 0005
Create Date: 2026-11-10
"""

import sqlalchemy as sa
from alembic import op

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Nullable dan tanpa menghapus data. Baris lama otomatis berisi Indonesia (aplikasi baru berbasis WNI).
    op.add_column("pengguna", sa.Column("negara_domisili", sa.Text(), nullable=True, server_default="Indonesia"))
    op.add_column("pengguna", sa.Column("provinsi_domisili", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("pengguna", "provinsi_domisili")
    op.drop_column("pengguna", "negara_domisili")

"""saklar memori: kolom aktif pada memori_pengguna dan memori_aktif pada pengguna

Revision ID: 0008
Revises: 0007
Create Date: 2026-11-18
"""

import sqlalchemy as sa
from alembic import op

revision = "0008"
down_revision = "0007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("memori_pengguna", sa.Column("aktif", sa.Boolean(), nullable=False, server_default=sa.text("true")))
    op.add_column("pengguna", sa.Column("memori_aktif", sa.Boolean(), nullable=False, server_default=sa.text("true")))


def downgrade() -> None:
    op.drop_column("pengguna", "memori_aktif")
    op.drop_column("memori_pengguna", "aktif")

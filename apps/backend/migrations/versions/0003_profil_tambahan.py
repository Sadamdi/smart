"""kolom profil tambahan: kondisi khusus dan catatan (disabilitas, ekonomi kurang mampu, dan sebagainya)

Revision ID: 0003
Revises: 0002
Create Date: 2026-11-03
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("pengguna", sa.Column("kondisi_khusus", postgresql.ARRAY(sa.Text()), nullable=True))
    op.add_column("pengguna", sa.Column("catatan_tambahan", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("pengguna", "catatan_tambahan")
    op.drop_column("pengguna", "kondisi_khusus")

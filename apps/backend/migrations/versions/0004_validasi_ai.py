"""validasi AI: penanda sekali proses pada beasiswa dan tabel pengaturan sistem

Revision ID: 0004
Revises: 0003
Create Date: 2026-11-04
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("beasiswa", sa.Column("divalidasi_ai_pada", sa.DateTime(timezone=True), nullable=True))
    op.create_table(
        "pengaturan",
        sa.Column("kunci", sa.Text(), primary_key=True),
        sa.Column("nilai", postgresql.JSONB(), nullable=False),
        sa.Column("diubah_pada", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("pengaturan")
    op.drop_column("beasiswa", "divalidasi_ai_pada")

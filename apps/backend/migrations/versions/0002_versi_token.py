"""kolom versi_token pada pengguna (pencabutan token saat logout dan ganti kata sandi)

Revision ID: 0002
Revises: 0001
Create Date: 2026-11-02
"""

import sqlalchemy as sa
from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("pengguna", sa.Column("versi_token", sa.Integer(), server_default=sa.text("0"), nullable=False))


def downgrade() -> None:
    op.drop_column("pengguna", "versi_token")

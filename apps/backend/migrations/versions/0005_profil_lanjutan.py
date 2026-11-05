"""kolom profil_lanjutan (asal daerah, sekolah, organisasi, prestasi, sertifikat, keahlian, target studi)

Revision ID: 0005
Revises: 0004
Create Date: 2026-11-05
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("pengguna", sa.Column("profil_lanjutan", postgresql.JSONB(), nullable=True))


def downgrade() -> None:
    op.drop_column("pengguna", "profil_lanjutan")

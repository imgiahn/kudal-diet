"""add kakao_id to users

Revision ID: 001_kakao_auth
Revises:
Create Date: 2026-06-29

"""
import sqlalchemy as sa
from alembic import op

revision = "001_kakao_auth"
down_revision = "8ef417847182"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("kakao_id", sa.String(50), nullable=True),
    )
    op.create_unique_constraint("uq_users_kakao_id", "users", ["kakao_id"])
    op.create_index("ix_users_kakao_id", "users", ["kakao_id"])


def downgrade() -> None:
    op.drop_index("ix_users_kakao_id", table_name="users")
    op.drop_constraint("uq_users_kakao_id", "users", type_="unique")
    op.drop_column("users", "kakao_id")

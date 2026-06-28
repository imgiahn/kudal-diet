"""
Alembic 환경 설정 — async SQLAlchemy (asyncpg) 지원
"""
import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from alembic import context

# ── app 임포트 ─────────────────────────────────────────────
from app.core.config import settings
from app.core.database import Base

# 모든 모델을 임포트해야 autogenerate가 메타데이터를 인식한다
import app.models  # noqa: F401 — side-effect import

# ── 기본 설정 ──────────────────────────────────────────────
config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Base.metadata 에 모든 테이블 정보가 담긴다
target_metadata = Base.metadata


# ── 헬퍼 ───────────────────────────────────────────────────
def get_url() -> str:
    """환경 변수의 DB URL 반환 (alembic.ini 값보다 우선)"""
    return settings.database_url


# ── 오프라인 모드 (DB 연결 없이 SQL 파일 생성) ───────────────
def run_migrations_offline() -> None:
    context.configure(
        url=get_url(),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=True,
    )
    with context.begin_transaction():
        context.run_migrations()


# ── 온라인 모드 (실제 DB 연결) ──────────────────────────────
def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
        compare_server_default=True,
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    cfg = config.get_section(config.config_ini_section, {})
    cfg["sqlalchemy.url"] = get_url()

    connectable = async_engine_from_config(
        cfg,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,   # 마이그레이션은 커넥션 풀 불필요
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())


# ── 진입점 ─────────────────────────────────────────────────
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

# ── 엔진 ────────────────────────────────────────────────────
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    pool_pre_ping=True,      # 연결 끊김 자동 감지
    pool_size=10,
    max_overflow=20,
)

# ── 세션 팩토리 ──────────────────────────────────────────────
async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)

# ── ORM Base ─────────────────────────────────────────────────
# 모든 SQLAlchemy 모델이 이 Base를 상속한다
class Base(DeclarativeBase):
    pass


# ── FastAPI Dependency ───────────────────────────────────────
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from sqlalchemy import text

from app.core.database import async_session_maker

router = APIRouter(tags=["health"])


class HealthResponse(BaseModel):
    status: str
    service: str


class DbHealthResponse(BaseModel):
    status: str
    database: str


@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    return HealthResponse(status="ok", service="kudal-api")


@router.get("/health/db", response_model=DbHealthResponse)
async def health_db() -> DbHealthResponse:
    """PostgreSQL 연결 상태 확인"""
    try:
        async with async_session_maker() as session:
            await session.execute(text("SELECT 1"))
        return DbHealthResponse(status="ok", database="connected")
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail={"status": "error", "database": "disconnected", "reason": str(exc)},
        ) from exc

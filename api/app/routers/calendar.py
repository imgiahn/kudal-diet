from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.repositories.summary_repository import SummaryRepository
from app.schemas.calendar import CalendarDaySchema, CalendarResponse

router = APIRouter(prefix="/api/v1/calendar", tags=["calendar"])


@router.get("", response_model=CalendarResponse)
async def get_calendar(
    year: int = Query(..., ge=2020, le=2100),
    month: int = Query(..., ge=1, le=12),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> CalendarResponse:
    summaries = await SummaryRepository(session).get_month_summaries(
        current_user.id, year, month
    )
    days = [
        CalendarDaySchema(
            date=s.summary_date,
            total_kcal=s.total_kcal,
            total_carb_g=float(s.total_carb_g),
            total_protein_g=float(s.total_protein_g),
            total_fat_g=float(s.total_fat_g),
            status=s.status.value,
            kudal_mood=s.kudal_mood,
        )
        for s in summaries
    ]
    return CalendarResponse(year=year, month=month, days=days)

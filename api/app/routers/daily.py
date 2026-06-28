import uuid
from datetime import date as date_type

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_user_or_404
from app.models.exercise import Exercise
from app.models.weight import Weight
from app.repositories.kudal_repository import KudalRepository
from app.repositories.meal_repository import MealRepository
from app.repositories.summary_repository import SummaryRepository
from app.schemas.daily import DailyDetailResponse, DailySummarySchema
from app.schemas.exercise import ExerciseResponse
from app.schemas.kudal import KudalResponse
from app.schemas.meal import MealResponse
from app.schemas.weight import WeightResponse

router = APIRouter(prefix="/api/v1/daily", tags=["daily"])


@router.get("", response_model=DailyDetailResponse)
async def get_daily(
    user_id: uuid.UUID = Query(...),
    date: date_type = Query(...),
    session: AsyncSession = Depends(get_db),
) -> DailyDetailResponse:
    await get_user_or_404(session, user_id)

    summary = await SummaryRepository(session).get_by_date(user_id, date)
    meals = await MealRepository(session).get_by_date(user_id, date)

    weights = list(
        (
            await session.execute(
                select(Weight)
                .where(Weight.user_id == user_id, Weight.record_date == date)
                .order_by(Weight.created_at)
            )
        ).scalars()
    )
    exercises = list(
        (
            await session.execute(
                select(Exercise)
                .where(Exercise.user_id == user_id, Exercise.record_date == date)
                .order_by(Exercise.created_at)
            )
        ).scalars()
    )
    kudal = await KudalRepository(session).get_by_user(user_id)

    return DailyDetailResponse(
        date=date,
        summary=(
            DailySummarySchema(
                total_kcal=summary.total_kcal,
                total_carb_g=float(summary.total_carb_g),
                total_protein_g=float(summary.total_protein_g),
                total_fat_g=float(summary.total_fat_g),
                exercise_kcal=summary.exercise_kcal,
                status=summary.status.value,
                kudal_mood=summary.kudal_mood,
            )
            if summary
            else None
        ),
        meals=[MealResponse.model_validate(m) for m in meals],
        weights=[WeightResponse.model_validate(w) for w in weights],
        exercises=[ExerciseResponse.model_validate(e) for e in exercises],
        kudal=KudalResponse.model_validate(kudal) if kudal else None,
    )

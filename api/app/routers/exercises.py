from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_user_or_404
from app.models.exercise import Exercise
from app.schemas.exercise import ExerciseCreate, ExerciseResponse
from app.services.summary_service import recalculate_and_save

router = APIRouter(prefix="/api/v1/exercises", tags=["exercises"])


@router.post("", response_model=ExerciseResponse, status_code=201)
async def create_exercise(
    body: ExerciseCreate,
    session: AsyncSession = Depends(get_db),
) -> ExerciseResponse:
    await get_user_or_404(session, body.user_id)

    exercise = Exercise(
        user_id=body.user_id,
        exercise_name=body.exercise_name,
        burn_kcal=body.burn_kcal,
        minutes=body.minutes,
        record_date=body.record_date,
    )
    session.add(exercise)
    await session.flush()

    # daily_summary.exercise_kcal 재계산
    await recalculate_and_save(session, body.user_id, body.record_date)

    return ExerciseResponse.model_validate(exercise)

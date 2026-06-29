from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.exercise import Exercise
from app.models.user import User
from app.schemas.exercise import ExerciseCreate, ExerciseResponse
from app.services.summary_service import recalculate_and_save

router = APIRouter(prefix="/api/v1/exercises", tags=["exercises"])


@router.post("", response_model=ExerciseResponse, status_code=201)
async def create_exercise(
    body: ExerciseCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> ExerciseResponse:
    exercise = Exercise(
        user_id=current_user.id,
        exercise_name=body.exercise_name,
        burn_kcal=body.burn_kcal,
        minutes=body.minutes,
        record_date=body.record_date,
    )
    session.add(exercise)
    await session.flush()

    await recalculate_and_save(session, current_user.id, body.record_date)

    return ExerciseResponse.model_validate(exercise)

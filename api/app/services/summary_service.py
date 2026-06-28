import uuid
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.daily_summary import DailySummary, DayStatus
from app.models.exercise import Exercise
from app.models.meal import Meal
from app.models.user import User
from app.repositories.summary_repository import SummaryRepository

_MOOD_BY_STATUS: dict[DayStatus, str] = {
    DayStatus.success: "happy",
    DayStatus.warning: "normal",
    DayStatus.over: "sad",
    DayStatus.empty: "sleepy",
}


async def recalculate_and_save(
    session: AsyncSession,
    user_id: uuid.UUID,
    target_date: date,
) -> DailySummary:
    """식사/운동 기록 변경 후 daily_summary 재계산·upsert."""
    repo = SummaryRepository(session)

    # 사용자 칼로리 목표
    user = await session.get(User, user_id)
    daily_goal: int = (user.daily_kcal_goal or 2000) if user else 2000

    # 식사 합계
    meal_row = (
        await session.execute(
            select(
                func.coalesce(func.sum(Meal.total_kcal), 0).label("kcal"),
                func.coalesce(func.sum(Meal.total_carb_g), 0).label("carb"),
                func.coalesce(func.sum(Meal.total_protein_g), 0).label("protein"),
                func.coalesce(func.sum(Meal.total_fat_g), 0).label("fat"),
            ).where(Meal.user_id == user_id, Meal.meal_date == target_date)
        )
    ).one()

    total_kcal = int(meal_row.kcal or 0)
    total_carb = float(meal_row.carb or 0)
    total_protein = float(meal_row.protein or 0)
    total_fat = float(meal_row.fat or 0)

    # 운동 합계
    exercise_kcal = int(
        (
            await session.execute(
                select(func.coalesce(func.sum(Exercise.burn_kcal), 0)).where(
                    Exercise.user_id == user_id, Exercise.record_date == target_date
                )
            )
        ).scalar()
        or 0
    )

    # 상태 계산
    if total_kcal == 0:
        status = DayStatus.empty
    elif total_kcal <= daily_goal:
        status = DayStatus.success
    elif total_kcal <= daily_goal * 1.15:
        status = DayStatus.warning
    else:
        status = DayStatus.over

    return await repo.upsert(
        user_id=user_id,
        summary_date=target_date,
        data={
            "total_kcal": total_kcal,
            "total_carb_g": total_carb,
            "total_protein_g": total_protein,
            "total_fat_g": total_fat,
            "exercise_kcal": exercise_kcal,
            "status": status,
            "kudal_mood": _MOOD_BY_STATUS[status],
        },
    )

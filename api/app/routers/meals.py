import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_user_or_404
from app.models.daily_summary import DayStatus
from app.repositories.meal_repository import MealRepository
from app.repositories.summary_repository import SummaryRepository
from app.schemas.meal import MealCreate, MealCreateResponse
from app.services.kudal_service import update_after_meal
from app.services.summary_service import recalculate_and_save

router = APIRouter(prefix="/api/v1/meals", tags=["meals"])


@router.post("", response_model=MealCreateResponse, status_code=201)
async def create_meal(
    body: MealCreate,
    session: AsyncSession = Depends(get_db),
) -> MealCreateResponse:
    await get_user_or_404(session, body.user_id)

    # 오늘 첫 식사인지 체크 (summary upsert 전)
    existing = await SummaryRepository(session).get_by_date(
        body.user_id, body.meal_date
    )
    is_first_today = existing is None or existing.status == DayStatus.empty

    # 식사 + 아이템 생성
    meal = await MealRepository(session).create(
        meal_data={
            "user_id": body.user_id,
            "meal_type": body.meal_type,
            "meal_date": body.meal_date,
            "image_url": body.image_url,
        },
        items_data=[item.model_dump() for item in body.items],
    )

    # daily_summary 재계산
    summary = await recalculate_and_save(session, body.user_id, body.meal_date)

    # 쿠달이 상태 갱신
    await update_after_meal(
        session,
        body.user_id,
        body.meal_date,
        summary.status,
        is_first_today,
    )

    return MealCreateResponse(meal_id=meal.id)


@router.delete("/{meal_id}", status_code=204)
async def delete_meal(
    meal_id: uuid.UUID,
    user_id: uuid.UUID = Query(...),
    session: AsyncSession = Depends(get_db),
) -> None:
    await get_user_or_404(session, user_id)

    meal = await MealRepository(session).get_by_id(meal_id, user_id)
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    meal_date = meal.meal_date
    await MealRepository(session).delete(meal)

    # daily_summary 재계산 (삭제 후 합계 갱신)
    await recalculate_and_save(session, user_id, meal_date)

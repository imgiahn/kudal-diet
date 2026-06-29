import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.daily_summary import DayStatus
from app.models.user import User
from app.repositories.meal_repository import MealRepository
from app.repositories.summary_repository import SummaryRepository
from app.schemas.meal import MealCreate, MealCreateResponse, MealItemResponse, MealItemUpdate
from app.services.kudal_service import update_after_meal
from app.services.summary_service import recalculate_and_save

router = APIRouter(prefix="/api/v1/meals", tags=["meals"])


@router.post("", response_model=MealCreateResponse, status_code=201)
async def create_meal(
    body: MealCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> MealCreateResponse:
    meal_date = body.meal_date

    existing = await SummaryRepository(session).get_by_date(current_user.id, meal_date)
    is_first_today = existing is None or existing.status == DayStatus.empty

    meal = await MealRepository(session).create(
        meal_data={
            "user_id": current_user.id,
            "meal_type": body.meal_type,
            "meal_date": meal_date,
            "image_url": body.image_url,
        },
        items_data=[item.model_dump() for item in body.items],
    )

    summary = await recalculate_and_save(session, current_user.id, meal_date)

    await update_after_meal(
        session,
        current_user.id,
        meal_date,
        summary.status,
        is_first_today,
    )

    return MealCreateResponse(meal_id=meal.id)


@router.delete("/{meal_id}", status_code=204)
async def delete_meal(
    meal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> None:
    meal = await MealRepository(session).get_by_id(meal_id, current_user.id)
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")

    meal_date = meal.meal_date
    await MealRepository(session).delete(meal)
    await recalculate_and_save(session, current_user.id, meal_date)


# ── meal-items (단건 음식 수정/삭제) ───────────────────────────

item_router = APIRouter(prefix="/api/v1/meal-items", tags=["meal-items"])


@item_router.delete("/{item_id}", status_code=204)
async def delete_meal_item(
    item_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> None:
    repo = MealRepository(session)
    item = await repo.get_item_by_id(item_id)
    if not item or item.meal.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Item not found")

    meal = item.meal
    meal_date = meal.meal_date
    await repo.delete_item(item)
    await repo.recalculate_meal_totals(meal)
    await recalculate_and_save(session, current_user.id, meal_date)


@item_router.patch("/{item_id}", response_model=MealItemResponse)
async def update_meal_item(
    item_id: uuid.UUID,
    body: MealItemUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> MealItemResponse:
    repo = MealRepository(session)
    item = await repo.get_item_by_id(item_id)
    if not item or item.meal.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Item not found")

    meal = item.meal
    meal_date = meal.meal_date
    updated = await repo.update_item(item, body.model_dump(exclude_none=True))
    await repo.recalculate_meal_totals(meal)
    await recalculate_and_save(session, current_user.id, meal_date)

    return MealItemResponse.model_validate(updated)

import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.meal import Meal, MealItem


class MealRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def get_by_id(self, meal_id: uuid.UUID, user_id: uuid.UUID) -> Meal | None:
        stmt = (
            select(Meal)
            .where(Meal.id == meal_id, Meal.user_id == user_id)
            .options(selectinload(Meal.items))
        )
        result = await self._s.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_date(self, user_id: uuid.UUID, meal_date: date) -> list[Meal]:
        stmt = (
            select(Meal)
            .where(Meal.user_id == user_id, Meal.meal_date == meal_date)
            .options(selectinload(Meal.items))
            .order_by(Meal.created_at)
        )
        result = await self._s.execute(stmt)
        return list(result.scalars().all())

    async def create(self, meal_data: dict, items_data: list[dict]) -> Meal:
        total_kcal = sum(int(item.get("kcal") or 0) for item in items_data)
        total_carb = sum(float(item.get("carb_g") or 0) for item in items_data)
        total_protein = sum(float(item.get("protein_g") or 0) for item in items_data)
        total_fat = sum(float(item.get("fat_g") or 0) for item in items_data)

        meal = Meal(
            **meal_data,
            total_kcal=total_kcal,
            total_carb_g=total_carb,
            total_protein_g=total_protein,
            total_fat_g=total_fat,
        )
        self._s.add(meal)
        await self._s.flush()

        for item_data in items_data:
            self._s.add(MealItem(meal_id=meal.id, **item_data))

        await self._s.flush()
        return meal

    async def delete(self, meal: Meal) -> None:
        await self._s.delete(meal)
        await self._s.flush()

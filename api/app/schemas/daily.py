from datetime import date

from pydantic import BaseModel

from app.schemas.exercise import ExerciseResponse
from app.schemas.kudal import KudalResponse
from app.schemas.meal import MealResponse
from app.schemas.weight import WeightResponse


class DailySummarySchema(BaseModel):
    total_kcal: int
    total_carb_g: float
    total_protein_g: float
    total_fat_g: float
    exercise_kcal: int
    status: str
    kudal_mood: str | None


class DailyDetailResponse(BaseModel):
    date: date
    summary: DailySummarySchema | None
    meals: list[MealResponse]
    weights: list[WeightResponse]
    exercises: list[ExerciseResponse]
    kudal: KudalResponse | None

# 모든 모델을 여기서 import → Alembic autogenerate가 인식함
from app.models.user import User
from app.models.meal import Meal, MealItem, MealType
from app.models.weight import Weight
from app.models.exercise import Exercise
from app.models.daily_summary import DailySummary, DayStatus
from app.models.kudal_state import KudalState

__all__ = [
    "User",
    "Meal",
    "MealItem",
    "MealType",
    "Weight",
    "Exercise",
    "DailySummary",
    "DayStatus",
    "KudalState",
]

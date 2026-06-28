from datetime import date

from pydantic import BaseModel


class CalendarDaySchema(BaseModel):
    date: date
    total_kcal: int
    total_carb_g: float
    total_protein_g: float
    total_fat_g: float
    status: str
    kudal_mood: str | None = None


class CalendarResponse(BaseModel):
    year: int
    month: int
    days: list[CalendarDaySchema]

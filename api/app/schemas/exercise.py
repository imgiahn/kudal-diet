import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, Field


class ExerciseCreate(BaseModel):
    user_id: uuid.UUID
    exercise_name: str = Field(min_length=1, max_length=200)
    burn_kcal: int = Field(ge=0)
    minutes: int = Field(ge=0)
    record_date: date


class ExerciseResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    exercise_name: str
    burn_kcal: int
    minutes: int
    record_date: date

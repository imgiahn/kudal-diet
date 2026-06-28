import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, Field


class WeightCreate(BaseModel):
    user_id: uuid.UUID
    weight_kg: float = Field(gt=0, le=500)
    record_date: date


class WeightResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    weight_kg: float
    record_date: date

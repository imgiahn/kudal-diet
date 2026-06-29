import uuid
from datetime import date

from pydantic import BaseModel, ConfigDict, Field

from app.models.meal import MealType


class MealItemCreate(BaseModel):
    food_name: str
    weight_g: float | None = None
    kcal: int = Field(ge=0)
    carb_g: float = 0.0
    protein_g: float = 0.0
    fat_g: float = 0.0
    confidence: float | None = Field(default=None, ge=0.0, le=1.0)


class MealCreate(BaseModel):
    meal_type: MealType
    meal_date: date
    image_url: str | None = None
    items: list[MealItemCreate] = Field(min_length=1)


class MealItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    food_name: str
    weight_g: float | None
    kcal: int
    carb_g: float
    protein_g: float
    fat_g: float
    confidence: float | None


class MealResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    meal_type: str
    meal_date: date
    image_url: str | None
    total_kcal: int
    total_carb_g: float
    total_protein_g: float
    total_fat_g: float
    items: list[MealItemResponse]


class MealItemUpdate(BaseModel):
    food_name: str | None = None
    weight_g: float | None = None
    kcal: int | None = Field(default=None, ge=0)
    carb_g: float | None = None
    protein_g: float | None = None
    fat_g: float | None = None


class MealCreateResponse(BaseModel):
    meal_id: uuid.UUID
    message: str = "meal saved"

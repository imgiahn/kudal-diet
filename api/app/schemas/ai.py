import uuid

from pydantic import BaseModel, Field, field_validator


class FoodItemSchema(BaseModel):
    food_name: str
    weight_g: float = Field(ge=0)
    kcal: int = Field(ge=0)
    carb_g: float = Field(ge=0)
    protein_g: float = Field(ge=0)
    fat_g: float = Field(ge=0)
    confidence: float = Field(ge=0.0, le=1.0)


class TotalMacroSchema(BaseModel):
    kcal: int = Field(ge=0)
    carb_g: float = Field(ge=0)
    protein_g: float = Field(ge=0)
    fat_g: float = Field(ge=0)


class AnalysisResult(BaseModel):
    """OpenAI Vision 분석 결과 — DB 저장 없이 Flutter에 바로 반환."""

    foods: list[FoodItemSchema]
    total: TotalMacroSchema
    kudal_comment: str


class AnalyzeMealRequest(BaseModel):
    user_id: uuid.UUID
    image_url: str = Field(min_length=10, description="R2에 업로드된 이미지 공개 URL")

    @field_validator("image_url")
    @classmethod
    def must_be_http(cls, v: str) -> str:
        if not v.startswith(("http://", "https://")):
            raise ValueError("image_url must be an HTTP or HTTPS URL")
        return v


class AnalyzeMealUploadResponse(BaseModel):
    """업로드 + AI 분석 통합 응답 — Flutter 팝업에서 바로 사용."""

    image_url: str
    object_key: str
    foods: list[FoodItemSchema]
    total: TotalMacroSchema
    kudal_comment: str

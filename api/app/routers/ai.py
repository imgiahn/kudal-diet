from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.ai import (
    AnalysisResult,
    AnalyzeMealRequest,
    AnalyzeMealUploadResponse,
)
from app.services import food_vision_service, r2_service

router = APIRouter(prefix="/api/v1/ai", tags=["ai"])


@router.post(
    "/analyze-meal-image",
    response_model=AnalysisResult,
    summary="음식 사진 AI 분석 (URL 입력)",
)
async def analyze_meal_image(
    body: AnalyzeMealRequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> AnalysisResult:
    return await food_vision_service.analyze_meal_image(body.image_url)


@router.post(
    "/analyze-meal-upload",
    response_model=AnalyzeMealUploadResponse,
    summary="사진 업로드 + AI 분석 통합",
)
async def analyze_meal_upload(
    file: UploadFile = File(..., description="음식 사진 (jpg/jpeg/png/webp, 최대 5MB)"),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> AnalyzeMealUploadResponse:
    image_url, object_key = await r2_service.upload_file_to_r2(
        file=file, user_id=current_user.id, prefix="meal"
    )

    try:
        analysis = await food_vision_service.analyze_meal_image(image_url)
    except HTTPException as exc:
        raise HTTPException(
            status_code=exc.status_code,
            detail={
                "message": exc.detail,
                "image_url": image_url,
                "object_key": object_key,
            },
        ) from exc

    return AnalyzeMealUploadResponse(
        image_url=image_url,
        object_key=object_key,
        foods=analysis.foods,
        total=analysis.total,
        kudal_comment=analysis.kudal_comment,
    )

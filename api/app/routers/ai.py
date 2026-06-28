import uuid

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_user_or_404
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
    description=(
        "이미 업로드된 image_url을 받아 OpenAI Vision으로 음식을 분석한다. "
        "DB 저장 없이 분석 결과만 반환하며, Flutter 팝업에서 수정 후 POST /api/v1/meals로 저장한다."
    ),
)
async def analyze_meal_image(
    body: AnalyzeMealRequest,
    session: AsyncSession = Depends(get_db),
) -> AnalysisResult:
    await get_user_or_404(session, body.user_id)
    return await food_vision_service.analyze_meal_image(body.image_url)


@router.post(
    "/analyze-meal-upload",
    response_model=AnalyzeMealUploadResponse,
    summary="사진 업로드 + AI 분석 통합",
    description=(
        "multipart/form-data로 이미지를 받아 R2 업로드 → OpenAI Vision 분석을 순서대로 처리한다. "
        "Flutter에서 한 번의 요청으로 image_url과 음식 분석 결과를 동시에 받을 수 있다. "
        "업로드 성공 후 분석 실패 시 detail에 image_url과 object_key를 포함해 반환한다."
    ),
)
async def analyze_meal_upload(
    user_id: uuid.UUID = Form(..., description="유저 UUID"),
    file: UploadFile = File(..., description="음식 사진 (jpg/jpeg/png/webp, 최대 5MB)"),
    session: AsyncSession = Depends(get_db),
) -> AnalyzeMealUploadResponse:
    await get_user_or_404(session, user_id)

    # ── Step 1: R2 업로드 ────────────────────────────────────
    image_url, object_key = await r2_service.upload_file_to_r2(
        file=file, user_id=user_id, prefix="meal"
    )

    # ── Step 2: OpenAI Vision 분석 ───────────────────────────
    # 업로드는 성공했지만 분석이 실패한 경우 image_url/object_key를 detail에 포함
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

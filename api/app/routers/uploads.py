import uuid

from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_user_or_404
from app.schemas.upload import UploadResponse
from app.services import r2_service

router = APIRouter(prefix="/api/v1/uploads", tags=["uploads"])


@router.post(
    "/meal-image",
    response_model=UploadResponse,
    status_code=201,
    summary="식단 사진 업로드",
    description=(
        "multipart/form-data로 사진을 업로드하면 Cloudflare R2에 저장하고 URL을 반환한다. "
        "허용 형식: jpg / jpeg / png / webp (최대 5 MB)"
    ),
)
async def upload_meal_image(
    user_id: uuid.UUID = Form(..., description="업로더 유저 UUID"),
    file: UploadFile = File(..., description="업로드할 이미지 파일"),
    session: AsyncSession = Depends(get_db),
) -> UploadResponse:
    await get_user_or_404(session, user_id)

    image_url, object_key = await r2_service.upload_file_to_r2(
        file=file,
        user_id=user_id,
        prefix="meal",
    )

    return UploadResponse(image_url=image_url, object_key=object_key)

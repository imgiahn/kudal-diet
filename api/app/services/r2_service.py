"""
Cloudflare R2 파일 업로드 서비스 (S3 호환 API).

boto3는 동기 라이브러리이므로 asyncio.to_thread()로 감싸 이벤트 루프를 블록하지 않는다.
"""
import asyncio
import io
import uuid
from datetime import datetime
from functools import lru_cache
from uuid import uuid4

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException, UploadFile

from app.core.config import settings

_ALLOWED_CONTENT_TYPES: dict[str, str] = {
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}
_MAX_BYTES = 5 * 1024 * 1024  # 5 MB


@lru_cache(maxsize=1)
def _r2_client():
    """boto3 S3 클라이언트 싱글턴 — 설정은 앱 시작 시 고정."""
    return boto3.client(
        "s3",
        endpoint_url=settings.r2_endpoint,
        aws_access_key_id=settings.r2_access_key,
        aws_secret_access_key=settings.r2_secret_key,
        region_name="auto",
    )


def _assert_r2_configured() -> None:
    if not (settings.r2_endpoint and settings.r2_access_key and settings.r2_secret_key):
        raise HTTPException(
            status_code=503,
            detail="R2 storage is not configured. Set R2_ENDPOINT, R2_ACCESS_KEY, R2_SECRET_KEY in .env",
        )


def _sync_upload(content: bytes, object_key: str, content_type: str) -> None:
    """동기 업로드 — asyncio.to_thread()를 통해 호출된다."""
    _r2_client().upload_fileobj(
        io.BytesIO(content),
        settings.r2_bucket_name,
        object_key,
        ExtraArgs={"ContentType": content_type},
    )


async def upload_file_to_r2(
    file: UploadFile,
    user_id: uuid.UUID,
    prefix: str = "meal",
) -> tuple[str, str]:
    """
    파일을 R2에 업로드하고 (image_url, object_key)를 반환한다.

    검증:
    - content_type: jpeg/png/webp만 허용
    - 파일 크기: 5MB 이하
    """
    _assert_r2_configured()

    # ── content-type 검증 ────────────────────────────────────
    content_type = (file.content_type or "").lower()
    if content_type not in _ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=415,
            detail=(
                f"Unsupported file type '{content_type}'. "
                "Allowed: image/jpeg, image/png, image/webp"
            ),
        )

    # ── 파일 읽기 + 크기 검증 ────────────────────────────────
    content = await file.read()
    if len(content) > _MAX_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File too large ({len(content) // 1024} KB). Maximum is 5 MB",
        )

    # ── 오브젝트 키 생성 ─────────────────────────────────────
    ext = _ALLOWED_CONTENT_TYPES[content_type]
    now = datetime.now()
    object_key = f"{prefix}/{user_id}/{now.year:04d}/{now.month:02d}/{uuid4()}{ext}"

    # ── R2 업로드 (동기 함수 → 스레드풀) ─────────────────────
    try:
        await asyncio.to_thread(_sync_upload, content, object_key, content_type)
    except ClientError as exc:
        code = exc.response.get("Error", {}).get("Code", "Unknown")
        msg = exc.response.get("Error", {}).get("Message", str(exc))
        raise HTTPException(status_code=502, detail=f"R2 upload failed [{code}]: {msg}") from exc
    except BotoCoreError as exc:
        raise HTTPException(status_code=502, detail=f"R2 connection error: {exc}") from exc

    # ── 공개 URL 조합 ─────────────────────────────────────────
    base = (settings.r2_public_base_url or "").rstrip("/")
    image_url = f"{base}/{object_key}"

    return image_url, object_key

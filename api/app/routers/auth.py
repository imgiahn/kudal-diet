from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.repositories.user_repository import UserRepository
from app.schemas.auth import KakaoAuthRequest, TokenResponse
from app.services.auth_service import (
    create_access_token,
    parse_kakao_user,
    verify_kakao_token,
)

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/kakao", response_model=TokenResponse)
async def kakao_login(
    body: KakaoAuthRequest,
    session: AsyncSession = Depends(get_db),
) -> TokenResponse:
    data = await verify_kakao_token(body.kakao_token)
    kakao_id, nickname, email = parse_kakao_user(data)

    repo = UserRepository(session)
    user = await repo.get_by_kakao_id(kakao_id)
    if not user:
        user = await repo.create(
            kakao_id=kakao_id,
            nickname=nickname,
            email=email,
        )

    token = create_access_token(user.id)
    return TokenResponse(
        access_token=token,
        user_id=str(user.id),
        nickname=user.nickname,
    )

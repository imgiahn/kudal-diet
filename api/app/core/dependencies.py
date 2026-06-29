import uuid

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.user import User
from app.services.auth_service import decode_access_token

_bearer = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    session: AsyncSession = Depends(get_db),
) -> User:
    user_id_str = decode_access_token(credentials.credentials)
    try:
        uid = uuid.UUID(user_id_str)
    except ValueError:
        raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다.")
    user = await session.get(User, uid)
    if not user:
        raise HTTPException(status_code=401, detail="사용자를 찾을 수 없어요.")
    return user


# 하위 호환 — 기존 시드 개발용 (추후 제거)
async def get_user_or_404(session: AsyncSession, user_id: uuid.UUID) -> User:
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail=f"User {user_id} not found")
    return user

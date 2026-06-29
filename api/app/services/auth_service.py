"""JWT 발급/검증 + 소셜 로그인 토큰 검증"""
import uuid
from datetime import datetime, timedelta, timezone

import httpx
import jwt
from fastapi import HTTPException

from app.core.config import settings


def create_access_token(user_id: uuid.UUID) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    payload = {
        "sub": str(user_id),
        "exp": expire,
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> str:
    try:
        payload = jwt.decode(
            token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
        user_id: str | None = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다.")
        return user_id
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="토큰이 만료됐어요. 다시 로그인해주세요.")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다.")


async def verify_kakao_token(access_token: str) -> dict:
    """카카오 액세스 토큰으로 사용자 정보 조회"""
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            "https://kapi.kakao.com/v2/user/me",
            headers={"Authorization": f"Bearer {access_token}"},
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=401, detail="유효하지 않은 카카오 토큰입니다.")
    return resp.json()


def parse_kakao_user(data: dict) -> tuple[str, str, str]:
    """(kakao_id, nickname, email) 반환"""
    kakao_id = str(data["id"])
    kakao_account = data.get("kakao_account", {})
    nickname = (
        kakao_account.get("profile", {}).get("nickname")
        or kakao_account.get("name")
        or "쿠달이유저"
    )
    email = (
        kakao_account.get("email")
        or f"kakao_{kakao_id}@kudal.app"
    )
    return kakao_id, nickname, email

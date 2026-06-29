import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        return await self._s.get(User, user_id)

    async def get_by_kakao_id(self, kakao_id: str) -> User | None:
        stmt = select(User).where(User.kakao_id == kakao_id)
        result = await self._s.execute(stmt)
        return result.scalar_one_or_none()

    async def create(
        self,
        *,
        kakao_id: str,
        nickname: str,
        email: str,
        daily_kcal_goal: int = 1800,
    ) -> User:
        user = User(
            kakao_id=kakao_id,
            nickname=nickname,
            email=email,
            daily_kcal_goal=daily_kcal_goal,
        )
        self._s.add(user)
        await self._s.flush()
        return user

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.kudal_state import KudalState


class KudalRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def get_by_user(self, user_id: uuid.UUID) -> KudalState | None:
        stmt = select(KudalState).where(KudalState.user_id == user_id)
        result = await self._s.execute(stmt)
        return result.scalar_one_or_none()

import uuid
from datetime import date

from sqlalchemy import extract, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.daily_summary import DailySummary


class SummaryRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def get_by_date(
        self, user_id: uuid.UUID, summary_date: date
    ) -> DailySummary | None:
        stmt = select(DailySummary).where(
            DailySummary.user_id == user_id,
            DailySummary.summary_date == summary_date,
        )
        result = await self._s.execute(stmt)
        return result.scalar_one_or_none()

    async def get_month_summaries(
        self, user_id: uuid.UUID, year: int, month: int
    ) -> list[DailySummary]:
        stmt = (
            select(DailySummary)
            .where(
                DailySummary.user_id == user_id,
                extract("year", DailySummary.summary_date) == year,
                extract("month", DailySummary.summary_date) == month,
            )
            .order_by(DailySummary.summary_date)
        )
        result = await self._s.execute(stmt)
        return list(result.scalars().all())

    async def upsert(
        self,
        user_id: uuid.UUID,
        summary_date: date,
        data: dict,
    ) -> DailySummary:
        summary = await self.get_by_date(user_id, summary_date)
        if summary is None:
            summary = DailySummary(user_id=user_id, summary_date=summary_date, **data)
            self._s.add(summary)
        else:
            for key, value in data.items():
                setattr(summary, key, value)
        await self._s.flush()
        return summary

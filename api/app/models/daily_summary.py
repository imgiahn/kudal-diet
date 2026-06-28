import enum
import uuid
from datetime import date
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Date, Enum as SAEnum, ForeignKey, Index, Integer, Numeric, String
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.user import User


class DayStatus(str, enum.Enum):
    success = "success"   # 칼로리 목표 달성
    warning = "warning"   # 목표 10~20% 초과
    over = "over"         # 목표 20% 이상 초과
    empty = "empty"       # 기록 없음


class DailySummary(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """
    매일 자정 또는 마지막 식사 기록 저장 시 갱신되는 일일 요약.
    meal/exercise 기록 변경 시 재계산한다.
    """
    __tablename__ = "daily_summaries"
    __table_args__ = (
        Index("ix_daily_summaries_user_id", "user_id"),
        Index("ix_daily_summaries_summary_date", "summary_date"),
        Index("ix_daily_summaries_user_date", "user_id", "summary_date", unique=True),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    summary_date: Mapped[date] = mapped_column(Date, nullable=False)
    total_kcal: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    total_carb_g: Mapped[Decimal] = mapped_column(
        Numeric(7, 2), nullable=False, default=0
    )
    total_protein_g: Mapped[Decimal] = mapped_column(
        Numeric(7, 2), nullable=False, default=0
    )
    total_fat_g: Mapped[Decimal] = mapped_column(
        Numeric(7, 2), nullable=False, default=0
    )
    exercise_kcal: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    status: Mapped[DayStatus] = mapped_column(
        SAEnum(DayStatus, name="day_status_enum", create_type=True),
        nullable=False,
        default=DayStatus.empty,
    )
    kudal_mood: Mapped[str | None] = mapped_column(String(50), nullable=True)

    user: Mapped["User"] = relationship(back_populates="daily_summaries", lazy="raise")

    def __repr__(self) -> str:
        return f"<DailySummary id={self.id} date={self.summary_date} status={self.status}>"

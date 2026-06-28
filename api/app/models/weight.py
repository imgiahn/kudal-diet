import uuid
from datetime import date
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Date, ForeignKey, Index, Numeric
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import CreatedAtMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.user import User


class Weight(UUIDPrimaryKeyMixin, CreatedAtMixin, Base):
    """체중 기록 — 수정이 필요한 경우 새 레코드를 추가한다 (불변 이력)"""
    __tablename__ = "weights"
    __table_args__ = (
        Index("ix_weights_user_id", "user_id"),
        Index("ix_weights_record_date", "record_date"),
        Index("ix_weights_user_date", "user_id", "record_date"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    weight_kg: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False)
    record_date: Mapped[date] = mapped_column(Date, nullable=False)

    user: Mapped["User"] = relationship(back_populates="weights", lazy="raise")

    def __repr__(self) -> str:
        return f"<Weight id={self.id} kg={self.weight_kg} date={self.record_date}>"

import uuid
from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import Date, ForeignKey, Index, Integer, String
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import CreatedAtMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.user import User


class Exercise(UUIDPrimaryKeyMixin, CreatedAtMixin, Base):
    __tablename__ = "exercises"
    __table_args__ = (
        Index("ix_exercises_user_id", "user_id"),
        Index("ix_exercises_record_date", "record_date"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    exercise_name: Mapped[str] = mapped_column(String(200), nullable=False)
    burn_kcal: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    record_date: Mapped[date] = mapped_column(Date, nullable=False)

    user: Mapped["User"] = relationship(back_populates="exercises", lazy="raise")

    def __repr__(self) -> str:
        return (
            f"<Exercise id={self.id} name={self.exercise_name} kcal={self.burn_kcal}>"
        )

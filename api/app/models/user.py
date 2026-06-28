import uuid
from datetime import date
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Date, Integer, Numeric, String
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.meal import Meal
    from app.models.weight import Weight
    from app.models.exercise import Exercise
    from app.models.daily_summary import DailySummary
    from app.models.kudal_state import KudalState


class User(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    nickname: Mapped[str] = mapped_column(String(100), nullable=False)
    height_cm: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    gender: Mapped[str | None] = mapped_column(String(10), nullable=True)
    current_weight_kg: Mapped[Decimal | None] = mapped_column(
        Numeric(5, 2), nullable=True
    )
    target_weight_kg: Mapped[Decimal | None] = mapped_column(
        Numeric(5, 2), nullable=True
    )
    daily_kcal_goal: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # ── 관계 (user 삭제 시 cascade 삭제) ────────────────────
    meals: Mapped[list["Meal"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="raise"
    )
    weights: Mapped[list["Weight"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="raise"
    )
    exercises: Mapped[list["Exercise"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="raise"
    )
    daily_summaries: Mapped[list["DailySummary"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="raise"
    )
    kudal_state: Mapped["KudalState | None"] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
        uselist=False,
        lazy="raise",
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email}>"

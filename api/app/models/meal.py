import enum
import uuid
from decimal import Decimal
from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import Date, Enum as SAEnum, ForeignKey, Integer, Numeric, String, Index
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.user import User


class MealType(str, enum.Enum):
    breakfast = "breakfast"
    lunch = "lunch"
    dinner = "dinner"
    snack = "snack"


class Meal(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "meals"
    __table_args__ = (
        Index("ix_meals_user_id", "user_id"),
        Index("ix_meals_meal_date", "meal_date"),
        Index("ix_meals_user_date", "user_id", "meal_date"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    meal_type: Mapped[MealType] = mapped_column(
        SAEnum(MealType, name="meal_type_enum", create_type=True),
        nullable=False,
    )
    meal_date: Mapped[date] = mapped_column(Date, nullable=False)
    image_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
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

    # ── 관계 ────────────────────────────────────────────────
    user: Mapped["User"] = relationship(back_populates="meals", lazy="raise")
    items: Mapped[list["MealItem"]] = relationship(
        back_populates="meal",
        cascade="all, delete-orphan",
        lazy="raise",
    )

    def __repr__(self) -> str:
        return f"<Meal id={self.id} type={self.meal_type} date={self.meal_date}>"


class MealItem(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "meal_items"
    __table_args__ = (Index("ix_meal_items_meal_id", "meal_id"),)

    meal_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("meals.id", ondelete="CASCADE"),
        nullable=False,
    )
    food_name: Mapped[str] = mapped_column(String(200), nullable=False)
    weight_g: Mapped[Decimal | None] = mapped_column(Numeric(7, 2), nullable=True)
    kcal: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    carb_g: Mapped[Decimal] = mapped_column(Numeric(7, 2), nullable=False, default=0)
    protein_g: Mapped[Decimal] = mapped_column(
        Numeric(7, 2), nullable=False, default=0
    )
    fat_g: Mapped[Decimal] = mapped_column(Numeric(7, 2), nullable=False, default=0)
    # OpenAI Vision 분석 신뢰도 (0.0 ~ 1.0)
    confidence: Mapped[Decimal | None] = mapped_column(
        Numeric(4, 3), nullable=True
    )

    meal: Mapped["Meal"] = relationship(back_populates="items", lazy="raise")

    def __repr__(self) -> str:
        return f"<MealItem id={self.id} food={self.food_name} kcal={self.kcal}>"

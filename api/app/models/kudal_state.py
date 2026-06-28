import uuid
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.user import User


class KudalState(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """사용자 1명당 1개 row. 쿠달이 성장 상태를 관리한다."""
    __tablename__ = "kudal_states"

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,     # 1:1 관계 보장
        index=True,
    )
    level: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    exp: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    streak_days: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    mood: Mapped[str] = mapped_column(String(50), nullable=False, default="응원")
    last_message: Mapped[str | None] = mapped_column(Text, nullable=True)

    user: Mapped["User"] = relationship(
        back_populates="kudal_state", lazy="raise"
    )

    def __repr__(self) -> str:
        return f"<KudalState id={self.id} level={self.level} exp={self.exp}>"

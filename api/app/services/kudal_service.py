import uuid
from datetime import date, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.daily_summary import DayStatus
from app.models.kudal_state import KudalState
from app.repositories.kudal_repository import KudalRepository
from app.repositories.summary_repository import SummaryRepository

_KUDAL_MAP: dict[DayStatus, tuple[str, str]] = {
    DayStatus.success: ("happy", "오늘 아주 잘했어!"),
    DayStatus.warning: ("normal", "조금 넘었지만 괜찮아. 내일 다시 맞춰보자!"),
    DayStatus.over: ("sad", "괜찮아, 다이어트는 하루가 아니라 흐름이야."),
    DayStatus.empty: ("sleepy", "오늘 기록을 기다리고 있어."),
}


async def update_after_meal(
    session: AsyncSession,
    user_id: uuid.UUID,
    target_date: date,
    status: DayStatus,
    is_first_meal_today: bool,
) -> KudalState:
    """식사 저장 후 쿠달이 EXP / 레벨 / 기분 갱신."""
    repo = KudalRepository(session)
    kudal = await repo.get_by_user(user_id)

    if kudal is None:
        kudal = KudalState(user_id=user_id, level=1, exp=0, streak_days=0)
        session.add(kudal)
        await session.flush()

    # EXP · 레벨
    kudal.exp += 10
    kudal.level = kudal.exp // 100 + 1

    # 연속 기록일 (하루 첫 식사 저장 시만 갱신)
    if is_first_meal_today:
        yesterday = target_date - timedelta(days=1)
        yesterday_summary = await SummaryRepository(session).get_by_date(
            user_id, yesterday
        )
        if yesterday_summary and yesterday_summary.status != DayStatus.empty:
            kudal.streak_days += 1
        else:
            kudal.streak_days = 1

    # 기분 · 메시지
    kudal.mood, kudal.last_message = _KUDAL_MAP.get(
        status, ("sleepy", "오늘 기록을 기다리고 있어.")
    )

    await session.flush()
    return kudal

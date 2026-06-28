"""
개발 테스트용 Seed 스크립트

실행 방법:
  cd api
  python scripts/seed.py
  # 또는 Docker 컨테이너 안에서:
  docker compose exec api python scripts/seed.py
"""
import asyncio
import sys
from datetime import date
from decimal import Decimal
from pathlib import Path

# api/ 디렉토리를 Python path에 추가
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select

from app.core.database import async_session_maker
from app.models.daily_summary import DailySummary, DayStatus
from app.models.kudal_state import KudalState
from app.models.user import User


async def seed() -> None:
    print("🌱 Seed 시작...")

    async with async_session_maker() as session:
        # ── 중복 체크 ─────────────────────────────────────
        result = await session.execute(
            select(User).where(User.email == "test@kudal.app")
        )
        existing = result.scalar_one_or_none()

        if existing:
            print(f"  ✓ 이미 존재하는 유저: {existing.id}  (seed 스킵)")
            return

        # ── 유저 생성 ─────────────────────────────────────
        user = User(
            email="test@kudal.app",
            nickname="기안",
            height_cm=Decimal("180.0"),
            current_weight_kg=Decimal("87.0"),
            target_weight_kg=Decimal("77.0"),
            daily_kcal_goal=1800,
        )
        session.add(user)
        await session.flush()          # id 확정

        print(f"  ✓ 유저 생성: {user.id}  ({user.nickname} / {user.email})")

        # ── 오늘 Daily Summary ────────────────────────────
        today = date.today()
        summary = DailySummary(
            user_id=user.id,
            summary_date=today,
            total_kcal=0,
            total_carb_g=Decimal("0"),
            total_protein_g=Decimal("0"),
            total_fat_g=Decimal("0"),
            exercise_kcal=0,
            status=DayStatus.empty,
            kudal_mood="응원",
        )
        session.add(summary)

        print(f"  ✓ DailySummary 생성: {today} / status={summary.status}")

        # ── 쿠달이 초기 상태 ──────────────────────────────
        kudal = KudalState(
            user_id=user.id,
            level=1,
            exp=0,
            streak_days=0,
            mood="응원",
            last_message="안녕! 나는 쿠달이야. 오늘부터 같이 건강해지자! 🐾",
        )
        session.add(kudal)

        print(f"  ✓ KudalState 생성: Lv.{kudal.level} / 기분={kudal.mood}")

        await session.commit()

    print("\n🎉 Seed 완료!")


if __name__ == "__main__":
    asyncio.run(seed())

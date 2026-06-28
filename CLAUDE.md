# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

쿠달이 — 캐릭터 기반 AI 식단 분석 앱. FastAPI 백엔드 + Flutter iOS 앱 모노레포.
인증 없음 — 모든 API는 `user_id` (UUID)를 쿼리파라미터 또는 바디에 포함.
시드 유저 UUID: `a3cc4044-4a6b-4613-bccc-fd3881de2484`

---

## 백엔드 (api/)

### 로컬 실행

```bash
# Docker (권장)
docker compose up --build -d

# 첫 실행 시 마이그레이션 + 시드
docker compose exec api alembic upgrade head
docker compose exec api python scripts/seed.py

# Docker 없이
cd api && pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### Alembic

```bash
docker compose exec api alembic revision --autogenerate -m "설명"
docker compose exec api alembic upgrade head
docker compose exec api alembic downgrade -1
```

### 핵심 아키텍처

- `routers/` → `repositories/` → DB (서비스 레이어는 비즈니스 로직만)
- 모든 라우터 함수는 `get_user_or_404(session, user_id)` 로 유저 검증 후 진행
- 식사/운동 저장 후 반드시 `summary_service.recalculate_and_save()` 호출 → `daily_summaries` upsert
- `kudal_service`도 식사 저장 시 EXP/레벨/연속일 갱신
- AI 분석 엔드포인트(`/api/v1/ai/`)는 DB 저장 없이 결과만 반환. 저장은 Flutter에서 `/api/v1/meals`로 별도 호출

### daily_summary 상태 계산

| 조건 | status |
|------|--------|
| `total_kcal == 0` | `empty` |
| `≤ daily_kcal_goal` | `success` |
| `≤ daily_kcal_goal × 1.15` | `warning` |
| 그 외 | `over` |

### 환경 변수 (`api/.env` — 커밋 금지)

필수: `DATABASE_URL`, `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_API_KEY`, `R2_ENDPOINT`, `R2_ACCESS_KEY`, `R2_SECRET_KEY`, `R2_PUBLIC_BASE_URL`
템플릿: `api/.env.example`

---

## 프론트엔드 (app/)

### 실행

```bash
cd app && flutter pub get

# 환경 전환: app/lib/core/config/app_config.dart 한 줄
# static const current = AppConfig.mock;        # 서버 불필요
# static const current = AppConfig.simulator;   # localhost:8000
# static const current = AppConfig.development; # EC2 실기기

flutter run -d <device>
```

### 핵심 아키텍처

**Repository Pattern + Mock/API 이중 구조**
- `repository_providers.dart`: `AppConfig.current.isMock` 에 따라 Mock/Api 구현체 자동 전환
- Mock: `repositories/mock/` — 네트워크 없이 동작
- Api: `repositories/api/` — Dio로 FastAPI 호출

**Riverpod 상태관리**
- `mealsProvider`, `todayMacroProvider`, `calendarDataProvider`, `kudalProvider` 등 FutureProvider
- 식단 저장 후 `ref.invalidate()` 5개 프로바이더 일괄 갱신: `mealsProvider`, `todayMacroProvider`, `calendarDataProvider`, `weeklyStatsProvider`, `kudalProvider`

**AI 분석 플로우**
- `analysisProvider` (StateNotifierProvider) — `AnalysisState` 관리
- `AnalysisPhase`: `idle → analyzing → saving`
- `AnalysisNotifier.analyze(File)` → multipart POST → `MealAnalysisResult`
- `AnalysisNotifier.saveToMeal(DateTime)` → POST /api/v1/meals → invalidate providers
- 중복 저장 방지: `isSaving` 시 early return

**모델 변환**
- `Meal.fromMealItem()`: API 저장 목록 응답 파싱
- `Meal.fromApiFood()`: AI 분석 결과 파싱
- `Meal.toApiItem()`: POST /api/v1/meals 의 items 배열 형식으로 변환

---

## 배포 (EC2)

```bash
# 접속 (Amazon Linux, ubuntu 아님)
ssh -i giahn.pem ec2-user@13.61.144.167

# 코드 업데이트 + 재시작
cd /home/ec2-user/kudal
git pull origin main
docker compose up -d --build
```

서버: `13.61.144.167:8000` / Swagger: `http://13.61.144.167:8000/docs`

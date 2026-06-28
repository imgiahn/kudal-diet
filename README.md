# 쿠달이 (Kudal)

캐릭터 기반 다이어트 기록 앱 — 모노레포

```
kudal/
├── app/   # Flutter iOS 앱
├── api/   # FastAPI 백엔드
└── docs/  # API 명세
```

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 모바일 앱 | Flutter 3.x (iOS) |
| 백엔드 | FastAPI 0.111 (Python 3.12) |
| 데이터베이스 | PostgreSQL 16 |
| ORM | SQLAlchemy 2.x (async) |
| 마이그레이션 | Alembic |
| 이미지 스토리지 | Cloudflare R2 (boto3 S3 호환) |
| AI 분석 | OpenAI Vision API (예정) |
| 인프라 | Docker + docker-compose |

---

## 빠른 시작

### 1. 환경 변수 설정

```bash
cp api/.env.example api/.env
# 필요 시 api/.env 수정
```

### 2. Docker로 전체 서비스 실행

```bash
docker compose up --build -d
```

### 3. DB 마이그레이션 + 시드

```bash
docker compose exec api alembic upgrade head
docker compose exec api python scripts/seed.py
```

시드 실행 후 출력된 **User UUID**를 복사해 두세요. 모든 API 호출에 필요합니다.

---

## API 엔드포인트

| Method | Path | 설명 |
|--------|------|------|
| GET | `/health` | 서비스 헬스체크 |
| GET | `/health/db` | DB 연결 확인 |
| GET | `/api/v1/calendar` | 월별 일일 요약 캘린더 |
| GET | `/api/v1/daily` | 특정 날짜 전체 상세 |
| POST | `/api/v1/meals` | 식사 저장 |
| DELETE | `/api/v1/meals/{meal_id}` | 식사 삭제 |
| POST | `/api/v1/weights` | 체중 기록 |
| POST | `/api/v1/exercises` | 운동 기록 |
| GET | `/api/v1/kudal` | 쿠달이 상태 조회 |
| POST | `/api/v1/uploads/meal-image` | 식단 사진 → R2 업로드 |
| POST | `/api/v1/ai/analyze-meal-image` | 음식 사진 AI 분석 (URL 입력) |
| POST | `/api/v1/ai/analyze-meal-upload` | 사진 업로드 + AI 분석 통합 |

전체 명세: http://localhost:8000/docs (Swagger UI)

---

## API 테스트 예시

> `USER_ID`는 seed 실행 후 출력된 UUID로 교체하세요.

### 헬스체크

```bash
curl http://localhost:8000/health
# {"status":"ok","service":"kudal-api"}

curl http://localhost:8000/health/db
# {"status":"ok","database":"connected"}
```

### 식사 저장 (POST /api/v1/meals)

```bash
curl -X POST http://localhost:8000/api/v1/meals \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "USER_ID",
    "meal_type": "lunch",
    "meal_date": "2026-06-28",
    "items": [
      {"food_name": "닭가슴살 도시락", "kcal": 480, "carb_g": 42, "protein_g": 38, "fat_g": 8},
      {"food_name": "현미밥", "kcal": 270, "carb_g": 58, "protein_g": 5, "fat_g": 0.5}
    ]
  }'
# {"meal_id":"<uuid>","message":"meal saved"}
```

### 식사 삭제 (DELETE /api/v1/meals/{meal_id})

```bash
curl -X DELETE "http://localhost:8000/api/v1/meals/MEAL_ID?user_id=USER_ID"
# 204 No Content
```

### 오늘 상세 조회 (GET /api/v1/daily)

```bash
curl "http://localhost:8000/api/v1/daily?user_id=USER_ID&date=2026-06-28"
```

```json
{
  "date": "2026-06-28",
  "summary": {
    "total_kcal": 750,
    "total_carb_g": 100.0,
    "total_protein_g": 43.0,
    "total_fat_g": 8.5,
    "exercise_kcal": 0,
    "status": "success",
    "kudal_mood": "happy"
  },
  "meals": [...],
  "weights": [],
  "exercises": [],
  "kudal": {
    "level": 1,
    "exp": 10,
    "streak_days": 1,
    "mood": "happy",
    "last_message": "오늘 아주 잘했어!"
  }
}
```

### 월별 캘린더 (GET /api/v1/calendar)

```bash
curl "http://localhost:8000/api/v1/calendar?user_id=USER_ID&year=2026&month=6"
```

```json
{
  "year": 2026,
  "month": 6,
  "days": [
    {
      "date": "2026-06-28",
      "total_kcal": 750,
      "total_carb_g": 100.0,
      "total_protein_g": 43.0,
      "total_fat_g": 8.5,
      "status": "success",
      "kudal_mood": "happy"
    }
  ]
}
```

### 체중 기록 (POST /api/v1/weights)

```bash
curl -X POST http://localhost:8000/api/v1/weights \
  -H "Content-Type: application/json" \
  -d '{"user_id":"USER_ID","weight_kg":86.3,"record_date":"2026-06-28"}'
```

### 운동 기록 (POST /api/v1/exercises)

```bash
curl -X POST http://localhost:8000/api/v1/exercises \
  -H "Content-Type: application/json" \
  -d '{"user_id":"USER_ID","exercise_name":"걷기","burn_kcal":250,"minutes":40,"record_date":"2026-06-28"}'
```

### 쿠달이 상태 (GET /api/v1/kudal)

```bash
curl "http://localhost:8000/api/v1/kudal?user_id=USER_ID"
```

```json
{
  "level": 1,
  "exp": 10,
  "streak_days": 1,
  "mood": "happy",
  "last_message": "오늘 아주 잘했어!"
}
```

### 식단 사진 업로드 (POST /api/v1/uploads/meal-image)

R2가 설정된 상태에서 테스트합니다.

```bash
curl -X POST http://localhost:8000/api/v1/uploads/meal-image \
  -F "user_id=USER_ID" \
  -F "file=@/path/to/food.jpg"
```

```json
{
  "image_url": "https://pub-<hash>.r2.dev/meal/USER_ID/2026/06/uuid.jpg",
  "object_key": "meal/USER_ID/2026/06/uuid.jpg"
}
```

오류 케이스:
```bash
# 잘못된 파일 형식 → 415
# 5MB 초과 → 413
# R2 미설정 → 503
```

---

## OpenAI Vision 설정

### .env에 키 입력

```bash
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4.1-mini
```

### 음식 사진 AI 분석 (POST /api/v1/ai/analyze-meal-image)

```bash
curl -X POST http://localhost:8000/api/v1/ai/analyze-meal-image \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "USER_ID",
    "image_url": "https://pub-<hash>.r2.dev/meal/USER_ID/2026/06/uuid.jpg"
  }'
```

```json
{
  "foods": [
    {
      "food_name": "닭가슴살 구이",
      "weight_g": 120,
      "kcal": 165,
      "carb_g": 0.0,
      "protein_g": 31.0,
      "fat_g": 3.6,
      "confidence": 0.88
    },
    {
      "food_name": "현미밥",
      "weight_g": 200,
      "kcal": 348,
      "carb_g": 72.0,
      "protein_g": 7.0,
      "fat_g": 2.0,
      "confidence": 0.79
    }
  ],
  "total": {
    "kcal": 513,
    "carb_g": 72.0,
    "protein_g": 38.0,
    "fat_g": 5.6
  },
  "kudal_comment": "단백질이 아주 좋아요! 균형 잡힌 식단이에요."
}
```

오류 케이스:
```bash
# API 키 미설정 → 503
# 음식 미인식 → 422
# 연속 검증 실패 → 502
# Rate Limit → 429
```

### 사진 업로드 + AI 분석 통합 (POST /api/v1/ai/analyze-meal-upload)

R2 업로드와 Vision 분석을 한 번의 요청으로 처리합니다. Flutter에서 권장하는 방식입니다.

```bash
curl -X POST http://localhost:8000/api/v1/ai/analyze-meal-upload \
  -F "user_id=USER_ID" \
  -F "file=@/path/to/food.jpg"
```

```json
{
  "image_url": "https://pub-<hash>.r2.dev/meal/USER_ID/2026/06/uuid.jpg",
  "object_key": "meal/USER_ID/2026/06/uuid.jpg",
  "foods": [
    {
      "food_name": "닭가슴살 구이",
      "weight_g": 120,
      "kcal": 165,
      "carb_g": 0.0,
      "protein_g": 31.0,
      "fat_g": 3.6,
      "confidence": 0.88
    }
  ],
  "total": {
    "kcal": 165,
    "carb_g": 0.0,
    "protein_g": 31.0,
    "fat_g": 3.6
  },
  "kudal_comment": "단백질이 아주 좋아요! 균형 잡힌 식단이에요."
}
```

업로드 후 분석 실패 시 (502):
```json
{
  "detail": {
    "message": "AI 응답이 예상 형식과 일치하지 않습니다.",
    "image_url": "https://pub-<hash>.r2.dev/meal/...",
    "object_key": "meal/USER_ID/2026/06/uuid.jpg"
  }
}
```

### Flutter 연동 흐름

**통합 방식 (권장)**
```
1. POST /api/v1/ai/analyze-meal-upload (파일 직접) → image_url + foods
2. Flutter 팝업에서 foods 수정
3. POST /api/v1/meals (image_url + items 포함) → 저장
```

**분리 방식 (image_url이 이미 있는 경우)**
```
1. POST /api/v1/uploads/meal-image   → image_url 획득
2. POST /api/v1/ai/analyze-meal-image (image_url 전달) → foods
3. POST /api/v1/meals → 저장
```

---

## Cloudflare R2 설정

### 1. R2 버킷 + API 토큰 생성

Cloudflare 대시보드 → R2 → 버킷 생성 (`kudal-prod-images`) → API 토큰 발급 (Object Read & Write)

### 2. .env에 값 입력

```bash
R2_ENDPOINT=https://<account_id>.r2.cloudflarestorage.com
R2_ACCESS_KEY=<R2 API Token ID>
R2_SECRET_KEY=<R2 API Token Secret>
R2_BUCKET_NAME=kudal-prod-images
R2_PUBLIC_BASE_URL=https://pub-<hash>.r2.dev   # 버킷 공개 URL
```

`R2_PUBLIC_BASE_URL` 확인 방법: R2 대시보드 → 버킷 → Settings → Public Access → Enable

### 3. 서비스 재시작

```bash
docker compose up --build -d
```

---

## 비즈니스 로직

### daily_summary 상태 계산

| 조건 | status |
|------|--------|
| total_kcal == 0 | `empty` |
| total_kcal ≤ daily_kcal_goal | `success` |
| total_kcal ≤ daily_kcal_goal × 1.15 | `warning` |
| 그 외 | `over` |

### 쿠달이 갱신 (식사 저장 시)

| 항목 | 로직 |
|------|------|
| EXP | +10 per meal |
| 레벨 | exp // 100 + 1 |
| 연속 기록일 | 하루 첫 식사 시 어제 기록 확인 후 +1 또는 1로 초기화 |
| 기분 | success→happy / warning→normal / over→sad / empty→sleepy |

---

## DB 마이그레이션 (Alembic)

```bash
# 마이그레이션 파일 생성
docker compose exec api alembic revision --autogenerate -m "initial tables"

# 마이그레이션 적용
docker compose exec api alembic upgrade head

# 롤백
docker compose exec api alembic downgrade -1

# 현재 버전
docker compose exec api alembic current
```

---

## Seed 데이터

```bash
docker compose exec api python scripts/seed.py
```

생성 데이터:
- 유저: `test@kudal.app` / 닉네임 `기안` / 목표 1800 kcal
- 오늘 날짜 `daily_summaries` 1건 (status=empty)
- `kudal_states` 초기 상태 1건 (Lv.1 / EXP 0)

---

## 로컬 개발 (Docker 없이)

```bash
cd api
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# .env의 DATABASE_URL host를 localhost로 변경 후
uvicorn app.main:app --reload --port 8000
```

---

## Flutter 앱 실행

```bash
cd app
flutter pub get

# Mock 모드 (기본값, 서버 불필요)
flutter run -d ios

# API 연결 모드
# app/lib/core/config/app_config.dart:
# static const current = AppConfig.development;
```

---

## 프로젝트 구조

```
kudal/
├── app/                         # Flutter 앱
│   └── lib/
│       ├── core/                # AppConfig (환경 전환)
│       ├── models/
│       ├── repositories/
│       │   ├── mock/
│       │   └── api/
│       ├── providers/           # Riverpod DI
│       └── screens/
│
├── api/                         # FastAPI 백엔드
│   ├── alembic/
│   ├── app/
│   │   ├── main.py
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   └── dependencies.py  # get_user_or_404
│   │   ├── models/
│   │   ├── schemas/             # Pydantic 스키마
│   │   ├── repositories/        # DB 접근 계층
│   │   ├── services/            # 비즈니스 로직
│   │   └── routers/
│   └── scripts/seed.py
│
└── docker-compose.yml
```

---

## DB 테이블 구조

```
users ──┬── meals ─── meal_items
        ├── weights
        ├── exercises
        ├── daily_summaries
        └── kudal_states (1:1)
```

---

## 서비스 종료

```bash
docker compose down            # 컨테이너 종료 (데이터 유지)
docker compose down -v         # 컨테이너 + 볼륨 삭제 (DB 초기화)
```

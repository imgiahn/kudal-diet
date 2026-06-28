# 쿠달이 API 명세

FastAPI 기반 백엔드 API 명세서  
Base URL: `https://api.kudal.app` (production) / `http://localhost:8000` (development)

---

## 공통

### 인증
```
Authorization: Bearer {access_token}
```

### 응답 형식
```json
{ "data": ..., "message": "ok" }
```

---

## User

### GET /user
현재 사용자 정보 조회

**Response**
```json
{
  "id": "u1",
  "name": "기안",
  "target_weight": 65.0,
  "target_calories": 1800,
  "target_carb": 150,
  "target_protein": 120,
  "target_fat": 50
}
```

### PATCH /user
사용자 정보 수정

**Request Body** (partial)
```json
{
  "name": "기안",
  "target_calories": 1800
}
```

---

## Meal

### GET /meal?date=YYYY-MM-DD
특정 날짜 식사 조회

**Response**
```json
{
  "sections": [
    {
      "type": "breakfast",
      "meals": [
        {
          "id": "m1",
          "name": "오트밀",
          "amount": "100g",
          "calories": 370,
          "carb": 60.0,
          "protein": 13.0,
          "fat": 7.0,
          "quantity": 1
        }
      ]
    }
  ]
}
```

### POST /meal
식사 저장

**Request Body**
```json
{
  "date": "2026-06-28",
  "meal_type": "lunch",
  "meal": {
    "name": "현미밥",
    "amount": "150g",
    "calories": 270,
    "carb": 56.0,
    "protein": 5.0,
    "fat": 1.0,
    "quantity": 1
  }
}
```

**Response**
```json
{ "id": "m_generated_id", "message": "saved" }
```

### PATCH /meal/{id}
식사 수정 (수량 등)

**Request Body**
```json
{ "quantity": 2 }
```

### DELETE /meal/{id}
식사 삭제

---

## POST /meal/image
음식 사진 AI 분석  
Content-Type: `multipart/form-data`

**Request**
```
file: <image bytes>
```

**Response**
```json
{
  "meals": [
    { "id": "a1", "name": "현미밥", "amount": "150g", "calories": 270, "carb": 56.0, "protein": 5.0, "fat": 1.0, "quantity": 1 },
    { "id": "a2", "name": "닭가슴살", "amount": "100g", "calories": 165, "carb": 0.0, "protein": 31.0, "fat": 4.0, "quantity": 1 }
  ],
  "total_calories": 435,
  "confidence": 0.92
}
```

**내부 처리 흐름**
1. 이미지를 Cloudflare R2에 업로드
2. R2 URL을 OpenAI Vision API에 전달
3. GPT 응답을 파싱하여 음식 목록 반환

---

## Weight

### POST /weight
체중 기록 저장

**Request Body**
```json
{
  "date": "2026-06-28",
  "weight": 67.1,
  "note": "아침 공복"
}
```

### GET /weight?days=7
최근 N일 체중 기록 조회

**Response**
```json
{
  "entries": [
    { "id": "w1", "date": "2026-06-22", "weight": 68.5 },
    { "id": "w7", "date": "2026-06-28", "weight": 67.1 }
  ]
}
```

---

## Calendar

### GET /calendar?year=2026&month=6
월간 캘린더 상태 조회

**Response**
```json
{
  "days": [
    {
      "date": "2026-06-01",
      "status": "success",
      "macro": { "calories": 1680, "carb": 120.0, "protein": 80.0, "fat": 30.0 }
    }
  ]
}
```

**status 값**
| 값 | 의미 |
|---|---|
| `success` | 칼로리 목표 달성 (초록 점) |
| `warning` | 목표 10~20% 초과 (노란 점) |
| `over` | 목표 20% 이상 초과 (빨간 점) |
| `empty` | 기록 없음 (회색 점) |

---

## Stats

### GET /stats
주간 통계 조회

**Response**
```json
{
  "daily_calories": [1650, 2100, 1800, 1980, 1750, 2050, 1620],
  "day_labels": ["월", "화", "수", "목", "금", "토", "일"],
  "streak_days": 12,
  "goal_rate": 0.78,
  "target_calories": 1800
}
```

---

## Kudal

### GET /kudal
쿠달이 현재 상태 조회

**Response**
```json
{
  "level": 3,
  "exp": 65,
  "max_exp": 100,
  "mood": "만족",
  "message": "오늘 단백질 아주 좋았어!\n저녁은 가볍게 가보자.",
  "streak_days": 12,
  "saved_meals": 38,
  "total_calories_burned": 12400
}
```

### POST /kudal/pet
쿠달이 쓰다듬기 → 경험치 증가

**Response**: GET /kudal 동일 형식 (업데이트된 상태)

### GET /kudal/cheer
오늘의 응원 메시지 목록

**Response**
```json
{
  "messages": [
    "오늘 단백질 목표 달성! 쿠달이가 칭찬해요 🌟",
    "물 2L 마셨죠? 피부가 맑아지고 있어요 💧"
  ]
}
```

---

## FastAPI 구현 예정 우선순위

1. `GET /user` + `PATCH /user`
2. `GET /meal?date=` + `POST /meal`
3. `GET /calendar`
4. `POST /meal/image` (OpenAI Vision 연동)
5. `GET /stats`
6. `POST /weight` + `GET /weight`
7. `GET /kudal` + `POST /kudal/pet`

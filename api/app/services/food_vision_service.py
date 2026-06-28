"""
Azure OpenAI Vision API로 음식 사진을 분석해 영양성분을 추정한다.

- AsyncAzureOpenAI 클라이언트를 lru_cache로 싱글턴 유지
- response_format=json_object 로 JSON 강제
- Pydantic 검증 실패 시 1회 재시도 → 그래도 실패하면 502
- total은 API 응답을 신뢰하지 않고 foods 합산으로 직접 계산
"""
from functools import lru_cache

from fastapi import HTTPException
from openai import AsyncAzureOpenAI, AuthenticationError, OpenAIError, RateLimitError
from pydantic import ValidationError

from app.core.config import settings
from app.schemas.ai import AnalysisResult, TotalMacroSchema

# ── 시스템 프롬프트 ────────────────────────────────────────────
_SYSTEM_PROMPT = """\
당신은 한국 음식 전문 영양 분석 AI입니다.
사진에 보이는 음식을 분석하여 반드시 아래 JSON 형식으로만 응답하세요.
JSON 외에 설명, 마크다운, 줄바꿈 텍스트를 절대 포함하지 마세요.

## 분석 원칙
- 사진에서 실제로 보이는 음식만 추정합니다. 보이지 않는 음식은 절대 추가하지 마세요.
- 한국 식품의약품안전처 영양성분 기준을 따릅니다.
- 중량(weight_g)은 그릇 크기와 시각적 양을 기준으로 g 단위로 추정합니다.
- kcal, carb_g, protein_g, fat_g는 weight_g 대비 해당 음식의 일반 영양성분표로 계산합니다.
- 확실하지 않으면 confidence를 0.5 이하로 설정합니다.
- 과도하게 확신하지 마세요.

## 반환 JSON 형식 (이 구조 그대로 반환)
{
  "foods": [
    {
      "food_name": "음식명 (한국어)",
      "weight_g": 150,
      "kcal": 270,
      "carb_g": 57.0,
      "protein_g": 5.0,
      "fat_g": 1.5,
      "confidence": 0.82
    }
  ],
  "total": {
    "kcal": 270,
    "carb_g": 57.0,
    "protein_g": 5.0,
    "fat_g": 1.5
  },
  "kudal_comment": "쿠달이의 격려 메시지 (한국어, 30자 이내, 친근한 톤)"
}

## 제약
- foods 배열에 실제 보이는 음식만 포함하세요.
- 모든 수치는 0 이상입니다.
- confidence는 0.0 ~ 1.0 사이 소수입니다.
- kudal_comment는 반드시 한국어로 작성하세요.
"""


@lru_cache(maxsize=1)
def _get_client() -> AsyncAzureOpenAI:
    """AsyncAzureOpenAI 클라이언트 싱글턴."""
    return AsyncAzureOpenAI(
        api_key=settings.azure_openai_api_key,
        api_version=settings.azure_openai_api_version,
        azure_endpoint=settings.azure_openai_endpoint or "",
    )


def _assert_configured() -> None:
    if not (settings.azure_openai_endpoint and settings.azure_openai_api_key):
        raise HTTPException(
            status_code=503,
            detail=(
                "Azure OpenAI is not configured. "
                "Set AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_API_KEY in .env"
            ),
        )


async def _call_api(image_url: str) -> str:
    """Vision API 호출 → 원본 JSON 문자열 반환."""
    response = await _get_client().chat.completions.create(
        model=settings.azure_openai_deployment_name,  # Azure: deployment name
        messages=[
            {"role": "system", "content": _SYSTEM_PROMPT},
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {"url": image_url, "detail": "auto"},
                    }
                ],
            },
        ],
        response_format={"type": "json_object"},
        max_tokens=2048,
        temperature=0.1,
    )
    return response.choices[0].message.content or "{}"


async def analyze_meal_image(image_url: str) -> AnalysisResult:
    """
    음식 사진 URL을 받아 Azure OpenAI Vision으로 분석하고 AnalysisResult를 반환한다.

    검증 실패 시 1회 재시도, 그래도 실패하면 502.
    total은 foods 합산으로 직접 계산해 정확성을 보장한다.
    """
    _assert_configured()

    last_error: Exception | None = None

    for attempt in range(2):
        try:
            raw = await _call_api(image_url)
            result = AnalysisResult.model_validate_json(raw)

            if not result.foods:
                raise HTTPException(
                    status_code=422,
                    detail="사진에서 음식을 인식하지 못했습니다. 더 선명한 사진을 사용해 주세요.",
                )

            # API가 계산한 total 대신 foods 합산으로 재계산 (신뢰성 보장)
            result.total = TotalMacroSchema(
                kcal=sum(f.kcal for f in result.foods),
                carb_g=round(sum(f.carb_g for f in result.foods), 1),
                protein_g=round(sum(f.protein_g for f in result.foods), 1),
                fat_g=round(sum(f.fat_g for f in result.foods), 1),
            )
            return result

        except ValidationError as exc:
            last_error = exc
            if attempt == 0:
                continue  # 1회 재시도

        except RateLimitError as exc:
            raise HTTPException(
                status_code=429,
                detail="Azure OpenAI rate limit exceeded. Please try again later.",
            ) from exc

        except AuthenticationError as exc:
            raise HTTPException(
                status_code=503,
                detail="Azure OpenAI authentication failed. Check AZURE_OPENAI_API_KEY.",
            ) from exc

        except OpenAIError as exc:
            raise HTTPException(
                status_code=502,
                detail=f"Azure OpenAI API error: {exc}",
            ) from exc

    raise HTTPException(
        status_code=502,
        detail="AI 응답이 예상 형식과 일치하지 않습니다. 잠시 후 다시 시도해 주세요.",
    )

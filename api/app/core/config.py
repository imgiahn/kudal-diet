from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # ── 앱 기본 ────────────────────────────────────────────
    app_name: str = "kudal-api"
    app_version: str = "0.1.0"
    debug: bool = False

    # ── 데이터베이스 ────────────────────────────────────────
    database_url: str = (
        "postgresql+asyncpg://kudal:kudal_pw@localhost:5432/kudal_db"
    )

    # ── CORS ───────────────────────────────────────────────
    allowed_origins: List[str] = ["*"]

    # ── 보안 (나중에 JWT 연동) ──────────────────────────────
    secret_key: str = "change-me-in-production"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7일

    # ── Cloudflare R2 ───────────────────────────────────────
    r2_endpoint: str | None = None
    r2_access_key: str | None = None
    r2_secret_key: str | None = None
    r2_bucket_name: str = "kudal-prod-images"
    r2_public_base_url: str | None = None

    # ── Azure OpenAI ────────────────────────────────────────
    azure_openai_endpoint: str | None = None
    azure_openai_api_key: str | None = None
    azure_openai_deployment_name: str = "gpt-5.4"
    azure_openai_api_version: str = "2024-02-01"


settings = Settings()

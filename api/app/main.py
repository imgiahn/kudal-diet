import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import ai, calendar, daily, exercises, health, kudal, meals, uploads, weights

# ── 로깅 설정 ────────────────────────────────────────────────
logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("kudal")

# 서드파티 라이브러리 로그 레벨 조정
logging.getLogger("httpx").setLevel(logging.WARNING)
logging.getLogger("openai").setLevel(logging.WARNING)
logging.getLogger("sqlalchemy.engine").setLevel(
    logging.INFO if settings.debug else logging.WARNING
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("🐾 Kudal API starting — env=debug=%s", settings.debug)
    yield
    logger.info("🐾 Kudal API shutting down")


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── 요청 로깅 미들웨어 ────────────────────────────────────────
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = round((time.perf_counter() - start) * 1000)

    level = logging.WARNING if response.status_code >= 400 else logging.INFO
    logger.log(
        level,
        "%s %s → %d (%dms)",
        request.method,
        request.url.path,
        response.status_code,
        elapsed_ms,
    )
    return response


# ── Routers ────────────────────────────────────────────────
app.include_router(health.router)
app.include_router(calendar.router)
app.include_router(daily.router)
app.include_router(meals.router)
app.include_router(meals.item_router)
app.include_router(weights.router)
app.include_router(exercises.router)
app.include_router(kudal.router)
app.include_router(uploads.router)
app.include_router(ai.router)

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_user_or_404
from app.repositories.kudal_repository import KudalRepository
from app.schemas.kudal import KudalResponse

router = APIRouter(prefix="/api/v1/kudal", tags=["kudal"])


@router.get("", response_model=KudalResponse)
async def get_kudal(
    user_id: uuid.UUID = Query(...),
    session: AsyncSession = Depends(get_db),
) -> KudalResponse:
    await get_user_or_404(session, user_id)

    kudal = await KudalRepository(session).get_by_user(user_id)
    if not kudal:
        raise HTTPException(
            status_code=404,
            detail="Kudal state not found. Run seed script first.",
        )

    return KudalResponse.model_validate(kudal)

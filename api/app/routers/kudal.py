from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.repositories.kudal_repository import KudalRepository
from app.schemas.kudal import KudalResponse

router = APIRouter(prefix="/api/v1/kudal", tags=["kudal"])


@router.get("", response_model=KudalResponse)
async def get_kudal(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> KudalResponse:
    kudal = await KudalRepository(session).get_by_user(current_user.id)
    if not kudal:
        raise HTTPException(status_code=404, detail="Kudal state not found.")
    return KudalResponse.model_validate(kudal)

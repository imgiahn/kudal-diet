from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.weight import Weight
from app.schemas.weight import WeightCreate, WeightResponse

router = APIRouter(prefix="/api/v1/weights", tags=["weights"])


@router.post("", response_model=WeightResponse, status_code=201)
async def create_weight(
    body: WeightCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
) -> WeightResponse:
    weight = Weight(
        user_id=current_user.id,
        weight_kg=body.weight_kg,
        record_date=body.record_date,
    )
    session.add(weight)
    await session.flush()
    return WeightResponse.model_validate(weight)

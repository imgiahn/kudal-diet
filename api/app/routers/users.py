from fastapi import APIRouter, Depends

from app.core.dependencies import get_current_user
from app.models.user import User

router = APIRouter(prefix="/api/v1/users", tags=["users"])


@router.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": str(current_user.id),
        "nickname": current_user.nickname,
        "email": current_user.email,
        "daily_kcal_goal": current_user.daily_kcal_goal or 1800,
        "target_weight_kg": float(current_user.target_weight_kg) if current_user.target_weight_kg else None,
        "current_weight_kg": float(current_user.current_weight_kg) if current_user.current_weight_kg else None,
    }

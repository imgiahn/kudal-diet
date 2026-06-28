from pydantic import BaseModel, ConfigDict


class KudalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    level: int
    exp: int
    streak_days: int
    mood: str
    last_message: str | None

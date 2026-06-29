from pydantic import BaseModel


class KakaoAuthRequest(BaseModel):
    kakao_token: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    nickname: str

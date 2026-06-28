from pydantic import BaseModel


class UploadResponse(BaseModel):
    image_url: str
    object_key: str

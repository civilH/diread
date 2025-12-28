from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ProgressResponse(BaseModel):
    id: str
    user_id: str
    book_id: str
    current_page: int
    current_cfi: Optional[str] = None
    progress_percent: float
    last_read_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ProgressUpdate(BaseModel):
    current_page: int
    current_cfi: Optional[str] = None
    progress_percent: float

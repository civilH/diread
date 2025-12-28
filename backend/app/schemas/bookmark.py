from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class BookmarkCreate(BaseModel):
    page_number: Optional[int] = None
    cfi: Optional[str] = None
    title: Optional[str] = None


class BookmarkResponse(BaseModel):
    id: str
    user_id: str
    book_id: str
    page_number: Optional[int] = None
    cfi: Optional[str] = None
    title: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

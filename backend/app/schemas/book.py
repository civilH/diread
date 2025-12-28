from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from ..models.book import BookType


class BookCreate(BaseModel):
    title: str
    author: Optional[str] = None


class BookResponse(BaseModel):
    id: str
    user_id: str
    title: str
    author: Optional[str] = None
    cover_url: Optional[str] = None
    file_url: str
    file_type: BookType
    file_size: Optional[int] = None
    total_pages: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True


class BookUpdate(BaseModel):
    title: Optional[str] = None
    author: Optional[str] = None

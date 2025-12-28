from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class HighlightCreate(BaseModel):
    text: str
    page_number: Optional[int] = None
    cfi: Optional[str] = None
    color: str = "yellow"
    note: Optional[str] = None


class HighlightResponse(BaseModel):
    id: str
    user_id: str
    book_id: str
    text: str
    page_number: Optional[int] = None
    cfi: Optional[str] = None
    color: str
    note: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class HighlightUpdate(BaseModel):
    color: Optional[str] = None
    note: Optional[str] = None

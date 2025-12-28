import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from ..database import Base


class Bookmark(Base):
    __tablename__ = "bookmarks"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    book_id = Column(String, ForeignKey("books.id", ondelete="CASCADE"), nullable=False)
    page_number = Column(Integer, nullable=True)
    cfi = Column(String, nullable=True)  # For EPUB location
    title = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="bookmarks")
    book = relationship("Book", back_populates="bookmarks")

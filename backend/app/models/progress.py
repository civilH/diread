import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from ..database import Base


class ReadingProgress(Base):
    __tablename__ = "reading_progress"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    book_id = Column(String, ForeignKey("books.id", ondelete="CASCADE"), nullable=False)
    current_page = Column(Integer, default=0)
    current_cfi = Column(String, nullable=True)  # For EPUB location
    progress_percent = Column(Float, default=0.0)
    last_read_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="reading_progress")
    book = relationship("Book", back_populates="reading_progress")

    __table_args__ = (
        UniqueConstraint("user_id", "book_id", name="unique_user_book_progress"),
    )

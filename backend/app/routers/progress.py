from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models.user import User
from ..schemas.progress import ProgressResponse, ProgressUpdate
from ..services.book_service import BookService
from ..utils.security import get_current_user

router = APIRouter(prefix="/books", tags=["Reading Progress"])


@router.get("/{book_id}/progress", response_model=ProgressResponse)
async def get_reading_progress(
    book_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get reading progress for a book."""
    # Check if book exists
    book = await BookService.get_book(db, book_id, current_user.id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )

    progress = await BookService.get_progress(db, book_id, current_user.id)
    if not progress:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No reading progress found",
        )

    return ProgressResponse.model_validate(progress)


@router.put("/{book_id}/progress", response_model=ProgressResponse)
async def update_reading_progress(
    book_id: str,
    progress_data: ProgressUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update reading progress for a book."""
    # Check if book exists
    book = await BookService.get_book(db, book_id, current_user.id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )

    progress = await BookService.update_progress(
        db,
        book_id,
        current_user.id,
        progress_data.current_page,
        progress_data.current_cfi,
        progress_data.progress_percent,
    )

    return ProgressResponse.model_validate(progress)

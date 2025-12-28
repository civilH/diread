from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models.user import User
from ..schemas.highlight import HighlightCreate, HighlightResponse, HighlightUpdate
from ..services.book_service import BookService
from ..utils.security import get_current_user

router = APIRouter(tags=["Highlights"])


@router.get("/books/{book_id}/highlights", response_model=List[HighlightResponse])
async def get_highlights(
    book_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get all highlights for a book."""
    # Check if book exists
    book = await BookService.get_book(db, book_id, current_user.id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )

    highlights = await BookService.get_highlights(db, book_id, current_user.id)
    return [HighlightResponse.model_validate(h) for h in highlights]


@router.post("/books/{book_id}/highlights", response_model=HighlightResponse, status_code=status.HTTP_201_CREATED)
async def create_highlight(
    book_id: str,
    highlight_data: HighlightCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new highlight."""
    # Check if book exists
    book = await BookService.get_book(db, book_id, current_user.id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )

    highlight = await BookService.create_highlight(
        db,
        book_id,
        current_user.id,
        highlight_data.text,
        highlight_data.page_number,
        highlight_data.cfi,
        highlight_data.color,
        highlight_data.note,
    )

    return HighlightResponse.model_validate(highlight)


@router.put("/highlights/{highlight_id}", response_model=HighlightResponse)
async def update_highlight(
    highlight_id: str,
    highlight_data: HighlightUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update a highlight."""
    highlight = await BookService.update_highlight(
        db,
        highlight_id,
        current_user.id,
        highlight_data.color,
        highlight_data.note,
    )

    if not highlight:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Highlight not found",
        )

    return HighlightResponse.model_validate(highlight)


@router.delete("/highlights/{highlight_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_highlight(
    highlight_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a highlight."""
    success = await BookService.delete_highlight(db, highlight_id, current_user.id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Highlight not found",
        )
    return None

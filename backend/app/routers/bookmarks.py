from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models.user import User
from ..schemas.bookmark import BookmarkCreate, BookmarkResponse
from ..services.book_service import BookService
from ..utils.security import get_current_user

router = APIRouter(tags=["Bookmarks"])


@router.get("/books/{book_id}/bookmarks", response_model=List[BookmarkResponse])
async def get_bookmarks(
    book_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get all bookmarks for a book."""
    # Check if book exists
    book = await BookService.get_book(db, book_id, current_user.id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )

    bookmarks = await BookService.get_bookmarks(db, book_id, current_user.id)
    return [BookmarkResponse.model_validate(b) for b in bookmarks]


@router.post("/books/{book_id}/bookmarks", response_model=BookmarkResponse, status_code=status.HTTP_201_CREATED)
async def create_bookmark(
    book_id: str,
    bookmark_data: BookmarkCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new bookmark."""
    # Check if book exists
    book = await BookService.get_book(db, book_id, current_user.id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )

    bookmark = await BookService.create_bookmark(
        db,
        book_id,
        current_user.id,
        bookmark_data.page_number,
        bookmark_data.cfi,
        bookmark_data.title,
    )

    return BookmarkResponse.model_validate(bookmark)


@router.delete("/bookmarks/{bookmark_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_bookmark(
    bookmark_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a bookmark."""
    success = await BookService.delete_bookmark(db, bookmark_id, current_user.id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Bookmark not found",
        )
    return None

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
import io

from ..database import get_db
from ..models.user import User
from ..schemas.book import BookResponse
from ..services.book_service import BookService
from ..utils.security import get_current_user

router = APIRouter(prefix="/books", tags=["Books"])


@router.get("", response_model=List[BookResponse])
async def get_books(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get all books for current user."""
    books = await BookService.get_user_books(db, current_user.id)
    return [BookResponse.model_validate(book) for book in books]


@router.post("/upload", response_model=BookResponse, status_code=status.HTTP_201_CREATED)
async def upload_book(
    file: UploadFile = File(...),
    title: Optional[str] = Form(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Upload a new book."""
    book = await BookService.create_book(db, current_user.id, file, title)
    return BookResponse.model_validate(book)


@router.get("/{book_id}", response_model=BookResponse)
async def get_book(
    book_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a specific book."""
    book = await BookService.get_book(db, book_id, current_user.id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )
    return BookResponse.model_validate(book)


@router.delete("/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_book(
    book_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a book."""
    success = await BookService.delete_book(db, book_id, current_user.id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )
    return None


@router.get("/{book_id}/download")
async def download_book(
    book_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Download book file."""
    book = await BookService.get_book(db, book_id, current_user.id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )

    content = await BookService.get_book_content(db, book_id, current_user.id)
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book file not found",
        )

    media_type = "application/pdf" if book.file_type.value == "pdf" else "application/epub+zip"
    filename = f"{book.title}.{book.file_type.value}"

    return StreamingResponse(
        io.BytesIO(content),
        media_type=media_type,
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
        },
    )

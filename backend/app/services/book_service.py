import io
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import UploadFile, HTTPException, status

from ..config import settings
from ..models.book import Book, BookType
from ..models.progress import ReadingProgress
from ..models.bookmark import Bookmark
from ..models.highlight import Highlight
from .storage_service import storage_service


class BookService:
    @staticmethod
    def get_file_extension(filename: str) -> str:
        return filename.rsplit(".", 1)[-1].lower()

    @staticmethod
    def validate_file(file: UploadFile) -> BookType:
        """Validate file type and return BookType."""
        if not file.filename:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No filename provided",
            )

        extension = BookService.get_file_extension(file.filename)
        if extension not in settings.allowed_file_types_list:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File type '{extension}' not allowed. Allowed types: {', '.join(settings.allowed_file_types_list)}",
            )

        return BookType.PDF if extension == "pdf" else BookType.EPUB

    @staticmethod
    async def extract_metadata(
        file_content: bytes,
        file_type: BookType,
    ) -> dict:
        """Extract metadata from book file."""
        metadata = {
            "title": None,
            "author": None,
            "cover": None,
            "total_pages": None,
        }

        try:
            if file_type == BookType.PDF:
                from pypdf import PdfReader
                pdf = PdfReader(io.BytesIO(file_content))
                info = pdf.metadata
                if info:
                    metadata["title"] = info.get("/Title")
                    metadata["author"] = info.get("/Author")
                metadata["total_pages"] = len(pdf.pages)

            elif file_type == BookType.EPUB:
                from ebooklib import epub, ITEM_DOCUMENT
                book = epub.read_epub(io.BytesIO(file_content))
                title = book.get_metadata("DC", "title")
                if title:
                    metadata["title"] = title[0][0]
                creator = book.get_metadata("DC", "creator")
                if creator:
                    metadata["author"] = creator[0][0]

                # Count chapters (spine items) as pages
                spine_items = [item for item in book.get_items() if item.get_type() == ITEM_DOCUMENT]
                metadata["total_pages"] = len(spine_items) if spine_items else len(list(book.get_items_of_type(ITEM_DOCUMENT)))

                # Get cover image
                for item in book.get_items():
                    if item.get_type() == 3:  # Image type
                        if "cover" in item.get_name().lower():
                            metadata["cover"] = item.get_content()
                            break
        except Exception:
            pass  # Silently fail metadata extraction

        return metadata

    @staticmethod
    async def create_book(
        db: AsyncSession,
        user_id: str,
        file: UploadFile,
        title: Optional[str] = None,
    ) -> Book:
        """Upload and create a new book."""
        # Validate file
        file_type = BookService.validate_file(file)

        # Read file content
        file_content = await file.read()
        file_size = len(file_content)

        # Check file size
        if file_size > settings.MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File too large. Maximum size: {settings.MAX_FILE_SIZE / 1024 / 1024}MB",
            )

        # Extract metadata
        metadata = await BookService.extract_metadata(file_content, file_type)

        # Use provided title or extracted title or filename
        book_title = title or metadata["title"] or file.filename.rsplit(".", 1)[0]

        # Upload file to storage
        extension = BookService.get_file_extension(file.filename)
        file_url = await storage_service.upload_book(user_id, file_content, extension)

        # Upload cover if available
        cover_url = None
        if metadata["cover"]:
            try:
                cover_url = await storage_service.upload_cover(
                    user_id,
                    str(file_url.split("/")[-1].rsplit(".", 1)[0]),
                    metadata["cover"],
                )
            except Exception:
                pass  # Silently fail cover upload

        # Create book record
        book = Book(
            user_id=user_id,
            title=book_title,
            author=metadata["author"],
            cover_url=cover_url,
            file_url=file_url,
            file_type=file_type,
            file_size=file_size,
            total_pages=metadata["total_pages"],
        )

        db.add(book)
        await db.commit()
        await db.refresh(book)
        return book

    @staticmethod
    async def get_user_books(db: AsyncSession, user_id: str) -> List[Book]:
        """Get all books for a user."""
        result = await db.execute(
            select(Book).where(Book.user_id == user_id).order_by(Book.created_at.desc())
        )
        return list(result.scalars().all())

    @staticmethod
    async def refresh_all_metadata(db: AsyncSession, user_id: str) -> List[Book]:
        """Refresh metadata (page count, etc.) for all books of a user."""
        books = await BookService.get_user_books(db, user_id)

        for book in books:
            try:
                # Get the book content
                content = await storage_service.get_book(book.file_url)
                if content:
                    # Re-extract metadata
                    metadata = await BookService.extract_metadata(content, book.file_type)

                    # Update book with new metadata
                    if metadata.get("total_pages"):
                        book.total_pages = metadata["total_pages"]
                    if metadata.get("author") and not book.author:
                        book.author = metadata["author"]
            except Exception:
                pass  # Skip books that fail to process

        await db.commit()

        # Refresh all books to get updated data
        for book in books:
            await db.refresh(book)

        return books

    @staticmethod
    async def get_book(db: AsyncSession, book_id: str, user_id: str) -> Optional[Book]:
        """Get a specific book."""
        result = await db.execute(
            select(Book).where(Book.id == book_id, Book.user_id == user_id)
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def delete_book(db: AsyncSession, book_id: str, user_id: str) -> bool:
        """Delete a book and its files."""
        book = await BookService.get_book(db, book_id, user_id)
        if not book:
            return False

        # Delete files from storage
        await storage_service.delete_book(book.file_url)
        if book.cover_url:
            await storage_service.delete_cover(book.cover_url)

        # Delete from database
        await db.delete(book)
        await db.commit()
        return True

    @staticmethod
    async def get_book_content(db: AsyncSession, book_id: str, user_id: str) -> Optional[bytes]:
        """Get book file content."""
        book = await BookService.get_book(db, book_id, user_id)
        if not book:
            return None
        return await storage_service.get_book(book.file_url)

    # Reading Progress
    @staticmethod
    async def get_progress(
        db: AsyncSession,
        book_id: str,
        user_id: str,
    ) -> Optional[ReadingProgress]:
        """Get reading progress for a book."""
        result = await db.execute(
            select(ReadingProgress).where(
                ReadingProgress.book_id == book_id,
                ReadingProgress.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def update_progress(
        db: AsyncSession,
        book_id: str,
        user_id: str,
        current_page: int,
        current_cfi: Optional[str],
        progress_percent: float,
    ) -> ReadingProgress:
        """Update or create reading progress."""
        progress = await BookService.get_progress(db, book_id, user_id)

        if progress:
            progress.current_page = current_page
            progress.current_cfi = current_cfi
            progress.progress_percent = progress_percent
        else:
            progress = ReadingProgress(
                user_id=user_id,
                book_id=book_id,
                current_page=current_page,
                current_cfi=current_cfi,
                progress_percent=progress_percent,
            )
            db.add(progress)

        await db.commit()
        await db.refresh(progress)
        return progress

    # Bookmarks
    @staticmethod
    async def get_bookmarks(
        db: AsyncSession,
        book_id: str,
        user_id: str,
    ) -> List[Bookmark]:
        """Get all bookmarks for a book."""
        result = await db.execute(
            select(Bookmark).where(
                Bookmark.book_id == book_id,
                Bookmark.user_id == user_id,
            ).order_by(Bookmark.created_at.desc())
        )
        return list(result.scalars().all())

    @staticmethod
    async def create_bookmark(
        db: AsyncSession,
        book_id: str,
        user_id: str,
        page_number: Optional[int],
        cfi: Optional[str],
        title: Optional[str],
    ) -> Bookmark:
        """Create a new bookmark."""
        bookmark = Bookmark(
            user_id=user_id,
            book_id=book_id,
            page_number=page_number,
            cfi=cfi,
            title=title,
        )
        db.add(bookmark)
        await db.commit()
        await db.refresh(bookmark)
        return bookmark

    @staticmethod
    async def delete_bookmark(
        db: AsyncSession,
        bookmark_id: str,
        user_id: str,
    ) -> bool:
        """Delete a bookmark."""
        result = await db.execute(
            select(Bookmark).where(
                Bookmark.id == bookmark_id,
                Bookmark.user_id == user_id,
            )
        )
        bookmark = result.scalar_one_or_none()
        if not bookmark:
            return False

        await db.delete(bookmark)
        await db.commit()
        return True

    # Highlights
    @staticmethod
    async def get_highlights(
        db: AsyncSession,
        book_id: str,
        user_id: str,
    ) -> List[Highlight]:
        """Get all highlights for a book."""
        result = await db.execute(
            select(Highlight).where(
                Highlight.book_id == book_id,
                Highlight.user_id == user_id,
            ).order_by(Highlight.created_at.desc())
        )
        return list(result.scalars().all())

    @staticmethod
    async def create_highlight(
        db: AsyncSession,
        book_id: str,
        user_id: str,
        text: str,
        page_number: Optional[int],
        cfi: Optional[str],
        color: str,
        note: Optional[str],
    ) -> Highlight:
        """Create a new highlight."""
        highlight = Highlight(
            user_id=user_id,
            book_id=book_id,
            text=text,
            page_number=page_number,
            cfi=cfi,
            color=color,
            note=note,
        )
        db.add(highlight)
        await db.commit()
        await db.refresh(highlight)
        return highlight

    @staticmethod
    async def update_highlight(
        db: AsyncSession,
        highlight_id: str,
        user_id: str,
        color: Optional[str],
        note: Optional[str],
    ) -> Optional[Highlight]:
        """Update a highlight."""
        result = await db.execute(
            select(Highlight).where(
                Highlight.id == highlight_id,
                Highlight.user_id == user_id,
            )
        )
        highlight = result.scalar_one_or_none()
        if not highlight:
            return None

        if color is not None:
            highlight.color = color
        if note is not None:
            highlight.note = note

        await db.commit()
        await db.refresh(highlight)
        return highlight

    @staticmethod
    async def delete_highlight(
        db: AsyncSession,
        highlight_id: str,
        user_id: str,
    ) -> bool:
        """Delete a highlight."""
        result = await db.execute(
            select(Highlight).where(
                Highlight.id == highlight_id,
                Highlight.user_id == user_id,
            )
        )
        highlight = result.scalar_one_or_none()
        if not highlight:
            return False

        await db.delete(highlight)
        await db.commit()
        return True

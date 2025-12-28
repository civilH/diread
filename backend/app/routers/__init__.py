from .auth import router as auth_router
from .users import router as users_router
from .books import router as books_router
from .progress import router as progress_router
from .bookmarks import router as bookmarks_router
from .highlights import router as highlights_router

__all__ = [
    "auth_router",
    "users_router",
    "books_router",
    "progress_router",
    "bookmarks_router",
    "highlights_router",
]

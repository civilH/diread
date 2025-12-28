import uuid
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status

from ..config import settings
from ..models.user import User
from ..models.refresh_token import RefreshToken


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        return pwd_context.verify(plain_password, hashed_password)

    @staticmethod
    def get_password_hash(password: str) -> str:
        return pwd_context.hash(password)

    @staticmethod
    def create_access_token(user_id: str) -> str:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode = {
            "sub": user_id,
            "exp": expire,
            "type": "access",
        }
        return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

    @staticmethod
    def create_refresh_token() -> tuple[str, str]:
        token = str(uuid.uuid4())
        token_hash = pwd_context.hash(token)
        return token, token_hash

    @staticmethod
    def verify_token(token: str) -> Optional[str]:
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            user_id: str = payload.get("sub")
            token_type: str = payload.get("type")
            if user_id is None or token_type != "access":
                return None
            return user_id
        except JWTError:
            return None

    @staticmethod
    async def get_user_by_email(db: AsyncSession, email: str) -> Optional[User]:
        result = await db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    @staticmethod
    async def get_user_by_id(db: AsyncSession, user_id: str) -> Optional[User]:
        result = await db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    @staticmethod
    async def create_user(
        db: AsyncSession,
        email: str,
        password: str,
        name: Optional[str] = None,
    ) -> User:
        # Check if user exists
        existing_user = await AuthService.get_user_by_email(db, email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="User with this email already exists",
            )

        # Create user
        user = User(
            email=email,
            password_hash=AuthService.get_password_hash(password),
            name=name,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def authenticate_user(
        db: AsyncSession,
        email: str,
        password: str,
    ) -> Optional[User]:
        user = await AuthService.get_user_by_email(db, email)
        if not user:
            return None
        if not AuthService.verify_password(password, user.password_hash):
            return None
        return user

    @staticmethod
    async def store_refresh_token(
        db: AsyncSession,
        user_id: str,
        token_hash: str,
    ) -> RefreshToken:
        expires_at = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        refresh_token = RefreshToken(
            user_id=user_id,
            token_hash=token_hash,
            expires_at=expires_at,
        )
        db.add(refresh_token)
        await db.commit()
        return refresh_token

    @staticmethod
    async def verify_refresh_token(
        db: AsyncSession,
        user_id: str,
        token: str,
    ) -> bool:
        result = await db.execute(
            select(RefreshToken).where(
                RefreshToken.user_id == user_id,
                RefreshToken.expires_at > datetime.utcnow(),
            )
        )
        refresh_tokens = result.scalars().all()

        for rt in refresh_tokens:
            if pwd_context.verify(token, rt.token_hash):
                return True
        return False

    @staticmethod
    async def invalidate_refresh_token(
        db: AsyncSession,
        user_id: str,
        token: str,
    ) -> None:
        result = await db.execute(
            select(RefreshToken).where(RefreshToken.user_id == user_id)
        )
        refresh_tokens = result.scalars().all()

        for rt in refresh_tokens:
            if pwd_context.verify(token, rt.token_hash):
                await db.delete(rt)
                await db.commit()
                break

    @staticmethod
    async def invalidate_all_refresh_tokens(db: AsyncSession, user_id: str) -> None:
        result = await db.execute(
            select(RefreshToken).where(RefreshToken.user_id == user_id)
        )
        refresh_tokens = result.scalars().all()

        for rt in refresh_tokens:
            await db.delete(rt)
        await db.commit()

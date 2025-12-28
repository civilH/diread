import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..schemas.auth import UserCreate, UserLogin, Token, TokenRefresh, PasswordResetRequest, PasswordReset
from ..schemas.user import UserResponse
from ..services.auth_service import AuthService
from ..services.email_service import EmailService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=dict, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db),
):
    """Register a new user."""
    # Validate password length
    if len(user_data.password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 8 characters",
        )

    # Create user
    user = await AuthService.create_user(
        db,
        email=user_data.email,
        password=user_data.password,
        name=user_data.name,
    )

    # Generate tokens
    access_token = AuthService.create_access_token(user.id)
    refresh_token, token_hash = AuthService.create_refresh_token()
    await AuthService.store_refresh_token(db, user.id, token_hash)

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": UserResponse.model_validate(user).model_dump(),
    }


@router.post("/login", response_model=dict)
async def login(
    credentials: UserLogin,
    db: AsyncSession = Depends(get_db),
):
    """Login with email and password."""
    user = await AuthService.authenticate_user(
        db,
        email=credentials.email,
        password=credentials.password,
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # Generate tokens
    access_token = AuthService.create_access_token(user.id)
    refresh_token, token_hash = AuthService.create_refresh_token()
    await AuthService.store_refresh_token(db, user.id, token_hash)

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": UserResponse.model_validate(user).model_dump(),
    }


@router.post("/refresh", response_model=Token)
async def refresh_token(
    token_data: TokenRefresh,
    db: AsyncSession = Depends(get_db),
):
    """Refresh access token using refresh token."""
    # Decode the refresh token to get user_id
    # Since refresh tokens are UUIDs, we need to verify against stored tokens
    from sqlalchemy import select
    from ..models.refresh_token import RefreshToken
    from datetime import datetime

    # Get all valid refresh tokens
    result = await db.execute(
        select(RefreshToken).where(RefreshToken.expires_at > datetime.utcnow())
    )
    tokens = result.scalars().all()

    # Find matching token
    from passlib.context import CryptContext
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

    user_id = None
    for rt in tokens:
        if pwd_context.verify(token_data.refresh_token, rt.token_hash):
            user_id = rt.user_id
            break

    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    # Generate new tokens
    access_token = AuthService.create_access_token(user_id)
    new_refresh_token, token_hash = AuthService.create_refresh_token()

    # Invalidate old token and store new one
    await AuthService.invalidate_refresh_token(db, user_id, token_data.refresh_token)
    await AuthService.store_refresh_token(db, user_id, token_hash)

    return Token(
        access_token=access_token,
        refresh_token=new_refresh_token,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    token_data: TokenRefresh,
    db: AsyncSession = Depends(get_db),
):
    """Logout and invalidate refresh token."""
    # Find and invalidate the refresh token
    from sqlalchemy import select
    from ..models.refresh_token import RefreshToken
    from passlib.context import CryptContext

    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

    result = await db.execute(select(RefreshToken))
    tokens = result.scalars().all()

    for rt in tokens:
        if pwd_context.verify(token_data.refresh_token, rt.token_hash):
            await db.delete(rt)
            await db.commit()
            break

    return None


@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(
    request: PasswordResetRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Request password reset email.

    Always returns success to prevent email enumeration attacks.
    """
    # Check if user exists
    user = await AuthService.get_user_by_email(db, request.email)

    if user:
        # Generate reset token
        token, token_hash = AuthService.create_password_reset_token()

        # Store token in database
        await AuthService.store_password_reset_token(
            db,
            str(user.id),
            token_hash,
        )

        # Send reset email
        user_name = user.name or user.email.split("@")[0]
        email_sent = EmailService.send_password_reset_email(
            to_email=user.email,
            reset_token=token,
            user_name=user_name,
        )

        if not email_sent:
            logger.error(f"Failed to send password reset email to {user.email}")
    else:
        logger.info(f"Password reset requested for non-existent email: {request.email}")

    # Always return success to prevent email enumeration
    return {
        "message": "If the email exists, a password reset link has been sent."
    }


@router.post("/reset-password", status_code=status.HTTP_200_OK)
async def reset_password(
    request: PasswordReset,
    db: AsyncSession = Depends(get_db),
):
    """Reset password with token."""
    # Validate password length
    if len(request.password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 8 characters",
        )

    # Verify token and get user
    user = await AuthService.verify_password_reset_token(db, request.token)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token",
        )

    # Mark token as used
    await AuthService.use_password_reset_token(db, request.token)

    # Update password
    await AuthService.update_password(db, user, request.password)

    # Invalidate all refresh tokens for security
    await AuthService.invalidate_all_refresh_tokens(db, str(user.id))

    logger.info(f"Password reset successful for user: {user.email}")

    return {
        "message": "Password has been reset successfully. Please log in with your new password."
    }

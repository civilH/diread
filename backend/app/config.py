from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import Optional, List


class Settings(BaseSettings):
    # App Settings
    APP_NAME: str = "diRead API"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"

    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./diread.db"

    # JWT Settings
    SECRET_KEY: str = "your-super-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Storage Settings
    STORAGE_PROVIDER: str = "local"  # "local", "s3", or "r2"
    STORAGE_BUCKET: str = "diread-books"
    STORAGE_ACCESS_KEY: Optional[str] = None
    STORAGE_SECRET_KEY: Optional[str] = None
    STORAGE_ENDPOINT_URL: Optional[str] = None
    STORAGE_REGION: str = "auto"
    LOCAL_STORAGE_PATH: str = "./storage"

    # File Upload Settings
    MAX_FILE_SIZE: int = 100 * 1024 * 1024  # 100MB
    ALLOWED_FILE_TYPES: str = "pdf,epub"

    # Email Settings (for password reset)
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: int = 587
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    EMAIL_FROM: Optional[str] = None
    EMAIL_FROM_NAME: str = "diRead"

    # Password Reset Settings
    PASSWORD_RESET_EXPIRE_MINUTES: int = 30
    FRONTEND_URL: str = "diread://reset-password"  # Deep link for mobile app

    # CORS Settings
    CORS_ORIGINS: str = "*"

    @property
    def allowed_file_types_list(self) -> List[str]:
        return [t.strip() for t in self.ALLOWED_FILE_TYPES.split(",")]

    @property
    def cors_origins_list(self) -> List[str]:
        if self.CORS_ORIGINS == "*":
            return ["*"]
        return [o.strip() for o in self.CORS_ORIGINS.split(",")]

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()

import os
import uuid
import aiofiles
from typing import Optional
from pathlib import Path

from ..config import settings


class StorageService:
    def __init__(self):
        self.provider = settings.STORAGE_PROVIDER
        self.local_path = Path(settings.LOCAL_STORAGE_PATH)
        self._ensure_local_dirs()

    def _ensure_local_dirs(self):
        """Create local storage directories if using local storage."""
        if self.provider == "local":
            (self.local_path / "books").mkdir(parents=True, exist_ok=True)
            (self.local_path / "covers").mkdir(parents=True, exist_ok=True)
            (self.local_path / "avatars").mkdir(parents=True, exist_ok=True)

    async def upload_book(
        self,
        user_id: str,
        file_content: bytes,
        file_extension: str,
    ) -> str:
        """Upload a book file and return the storage URL/path."""
        file_id = str(uuid.uuid4())
        filename = f"{user_id}/{file_id}.{file_extension}"

        if self.provider == "local":
            return await self._upload_local(filename, file_content, "books")
        else:
            return await self._upload_s3(filename, file_content, "books")

    async def upload_cover(
        self,
        user_id: str,
        book_id: str,
        file_content: bytes,
    ) -> str:
        """Upload a book cover and return the storage URL/path."""
        filename = f"{user_id}/{book_id}.jpg"

        if self.provider == "local":
            return await self._upload_local(filename, file_content, "covers")
        else:
            return await self._upload_s3(filename, file_content, "covers")

    async def upload_avatar(
        self,
        user_id: str,
        file_content: bytes,
    ) -> str:
        """Upload a user avatar and return the storage URL/path."""
        filename = f"{user_id}.jpg"

        if self.provider == "local":
            return await self._upload_local(filename, file_content, "avatars")
        else:
            return await self._upload_s3(filename, file_content, "avatars")

    async def get_book(self, file_path: str) -> Optional[bytes]:
        """Get book file content."""
        if self.provider == "local":
            return await self._get_local(file_path)
        else:
            return await self._get_s3(file_path)

    async def delete_book(self, file_path: str) -> bool:
        """Delete a book file."""
        if self.provider == "local":
            return await self._delete_local(file_path)
        else:
            return await self._delete_s3(file_path)

    async def delete_cover(self, file_path: str) -> bool:
        """Delete a cover file."""
        if self.provider == "local":
            return await self._delete_local(file_path)
        else:
            return await self._delete_s3(file_path)

    # Local storage methods
    async def _upload_local(
        self,
        filename: str,
        content: bytes,
        folder: str,
    ) -> str:
        file_path = self.local_path / folder / filename
        file_path.parent.mkdir(parents=True, exist_ok=True)

        async with aiofiles.open(file_path, "wb") as f:
            await f.write(content)

        return str(file_path)

    async def _get_local(self, file_path: str) -> Optional[bytes]:
        try:
            async with aiofiles.open(file_path, "rb") as f:
                return await f.read()
        except FileNotFoundError:
            return None

    async def _delete_local(self, file_path: str) -> bool:
        try:
            os.remove(file_path)
            return True
        except FileNotFoundError:
            return False

    # S3/R2 storage methods
    async def _upload_s3(
        self,
        filename: str,
        content: bytes,
        folder: str,
    ) -> str:
        import boto3
        from botocore.config import Config

        s3_client = boto3.client(
            "s3",
            endpoint_url=settings.STORAGE_ENDPOINT_URL,
            aws_access_key_id=settings.STORAGE_ACCESS_KEY,
            aws_secret_access_key=settings.STORAGE_SECRET_KEY,
            region_name=settings.STORAGE_REGION,
            config=Config(signature_version="s3v4"),
        )

        key = f"{folder}/{filename}"
        s3_client.put_object(
            Bucket=settings.STORAGE_BUCKET,
            Key=key,
            Body=content,
        )

        # Return the S3 URL
        if settings.STORAGE_ENDPOINT_URL:
            return f"{settings.STORAGE_ENDPOINT_URL}/{settings.STORAGE_BUCKET}/{key}"
        return f"https://{settings.STORAGE_BUCKET}.s3.amazonaws.com/{key}"

    async def _get_s3(self, file_path: str) -> Optional[bytes]:
        import boto3
        from botocore.config import Config
        from botocore.exceptions import ClientError

        s3_client = boto3.client(
            "s3",
            endpoint_url=settings.STORAGE_ENDPOINT_URL,
            aws_access_key_id=settings.STORAGE_ACCESS_KEY,
            aws_secret_access_key=settings.STORAGE_SECRET_KEY,
            region_name=settings.STORAGE_REGION,
            config=Config(signature_version="s3v4"),
        )

        try:
            # Extract key from URL
            key = file_path.split(f"{settings.STORAGE_BUCKET}/")[-1]
            response = s3_client.get_object(Bucket=settings.STORAGE_BUCKET, Key=key)
            return response["Body"].read()
        except ClientError:
            return None

    async def _delete_s3(self, file_path: str) -> bool:
        import boto3
        from botocore.config import Config
        from botocore.exceptions import ClientError

        s3_client = boto3.client(
            "s3",
            endpoint_url=settings.STORAGE_ENDPOINT_URL,
            aws_access_key_id=settings.STORAGE_ACCESS_KEY,
            aws_secret_access_key=settings.STORAGE_SECRET_KEY,
            region_name=settings.STORAGE_REGION,
            config=Config(signature_version="s3v4"),
        )

        try:
            key = file_path.split(f"{settings.STORAGE_BUCKET}/")[-1]
            s3_client.delete_object(Bucket=settings.STORAGE_BUCKET, Key=key)
            return True
        except ClientError:
            return False

    def get_signed_url(self, file_path: str, expires_in: int = 3600) -> str:
        """Generate a signed URL for file access."""
        if self.provider == "local":
            # For local storage, return the file path
            # In production, you'd serve this through your API
            return f"/api/v1/files/{file_path}"

        import boto3
        from botocore.config import Config

        s3_client = boto3.client(
            "s3",
            endpoint_url=settings.STORAGE_ENDPOINT_URL,
            aws_access_key_id=settings.STORAGE_ACCESS_KEY,
            aws_secret_access_key=settings.STORAGE_SECRET_KEY,
            region_name=settings.STORAGE_REGION,
            config=Config(signature_version="s3v4"),
        )

        key = file_path.split(f"{settings.STORAGE_BUCKET}/")[-1]
        return s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.STORAGE_BUCKET, "Key": key},
            ExpiresIn=expires_in,
        )


storage_service = StorageService()

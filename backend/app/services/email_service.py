"""Email service for sending emails."""
import smtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional

from ..config import settings

logger = logging.getLogger(__name__)


class EmailService:
    """Service for sending emails."""

    @staticmethod
    def _create_smtp_connection():
        """Create SMTP connection."""
        if not settings.SMTP_HOST:
            return None

        try:
            server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT)
            server.starttls()
            if settings.SMTP_USER and settings.SMTP_PASSWORD:
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            return server
        except Exception as e:
            logger.error(f"Failed to connect to SMTP server: {e}")
            return None

    @staticmethod
    def send_email(
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None,
    ) -> bool:
        """
        Send an email.

        Args:
            to_email: Recipient email address
            subject: Email subject
            html_content: HTML email body
            text_content: Plain text fallback (optional)

        Returns:
            True if sent successfully, False otherwise
        """
        # If SMTP is not configured, log the email content (for development)
        if not settings.SMTP_HOST or not settings.EMAIL_FROM:
            logger.info("=" * 50)
            logger.info("EMAIL (SMTP not configured - development mode)")
            logger.info(f"To: {to_email}")
            logger.info(f"Subject: {subject}")
            logger.info(f"Content:\n{text_content or html_content}")
            logger.info("=" * 50)
            return True

        try:
            # Create message
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = f"{settings.EMAIL_FROM_NAME} <{settings.EMAIL_FROM}>"
            message["To"] = to_email

            # Add plain text and HTML parts
            if text_content:
                message.attach(MIMEText(text_content, "plain"))
            message.attach(MIMEText(html_content, "html"))

            # Send email
            server = EmailService._create_smtp_connection()
            if server:
                server.sendmail(settings.EMAIL_FROM, to_email, message.as_string())
                server.quit()
                logger.info(f"Email sent successfully to {to_email}")
                return True
            else:
                logger.error("Failed to create SMTP connection")
                return False

        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            return False

    @staticmethod
    def send_password_reset_email(to_email: str, reset_token: str, user_name: str) -> bool:
        """
        Send password reset email.

        Args:
            to_email: Recipient email address
            reset_token: Password reset token
            user_name: User's name for personalization

        Returns:
            True if sent successfully, False otherwise
        """
        reset_link = f"{settings.FRONTEND_URL}?token={reset_token}"

        subject = "Reset Your diRead Password"

        html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="text-align: center; margin-bottom: 30px;">
        <h1 style="color: #1a1a1a; margin: 0;">diRead</h1>
        <p style="color: #666; margin: 5px 0 0 0;">Your Family Library</p>
    </div>

    <div style="background-color: #f9f9f9; border-radius: 10px; padding: 30px; margin-bottom: 20px;">
        <h2 style="color: #1a1a1a; margin-top: 0;">Reset Your Password</h2>
        <p>Hi {user_name},</p>
        <p>We received a request to reset your password. Click the button below to create a new password:</p>

        <div style="text-align: center; margin: 30px 0;">
            <a href="{reset_link}"
               style="background-color: #007AFF; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: 600; display: inline-block;">
                Reset Password
            </a>
        </div>

        <p style="color: #666; font-size: 14px;">This link will expire in {settings.PASSWORD_RESET_EXPIRE_MINUTES} minutes.</p>

        <p style="color: #666; font-size: 14px;">If you didn't request this, you can safely ignore this email. Your password won't be changed.</p>
    </div>

    <div style="text-align: center; color: #999; font-size: 12px;">
        <p>If the button doesn't work, copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #007AFF;">{reset_link}</p>
    </div>

    <div style="text-align: center; color: #999; font-size: 12px; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
        <p>&copy; diRead - Your Family Library</p>
    </div>
</body>
</html>
"""

        text_content = f"""
Reset Your diRead Password

Hi {user_name},

We received a request to reset your password.

Click here to reset your password:
{reset_link}

This link will expire in {settings.PASSWORD_RESET_EXPIRE_MINUTES} minutes.

If you didn't request this, you can safely ignore this email.

- diRead Team
"""

        return EmailService.send_email(to_email, subject, html_content, text_content)

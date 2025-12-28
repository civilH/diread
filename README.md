<p align="center">
  <img src="assets/images/logo.png" alt="diRead Logo" width="120" height="120">
</p>

<h1 align="center">diRead</h1>

<p align="center">
  <strong>A Private Family Digital Reading App</strong><br>
  Your personal library, beautifully designed. Inspired by Apple Books.
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#roadmap">Roadmap</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.1+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/Python-3.9+-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite">
</p>

---

## About

**diRead** is a private, family-focused digital reading application that lets you upload, organize, and read your personal e-book collection. Built with Flutter for a beautiful cross-platform experience and FastAPI for a robust backend.

> This is **not** a public marketplace — it's designed for private family use with secure, per-user libraries.

### Why diRead?

- **Privacy First**: Your books, your data. No tracking, no ads.
- **Cross-Platform**: iOS, Android, macOS, Windows, Linux, and Web.
- **Offline Support**: Read anywhere, sync when connected.
- **Beautiful UX**: Clean, distraction-free reading experience.

---

## Features

### Core Features

| Feature | PDF | EPUB | Status |
|---------|:---:|:----:|:------:|
| File Upload | ✅ | ✅ | Complete |
| Reading | ✅ | 🚧 | PDF Complete |
| Progress Sync | ✅ | ✅ | Complete |
| Bookmarks | ✅ | ✅ | Complete |
| Highlights | ✅ | ✅ | Complete |
| Notes | ✅ | ✅ | Complete |

### Authentication & Security
- [x] Email + password registration
- [x] Secure password hashing (bcrypt + salt)
- [x] JWT authentication with refresh tokens
- [x] Per-user private libraries
- [ ] Password reset via email (coming soon)

### Library Management
- [x] Upload PDF and EPUB files (up to 100MB)
- [x] Automatic metadata extraction (title, author, cover)
- [x] Grid and List view toggle
- [x] Sort by: Recently added, Title, Author
- [x] Delete and re-download books

### Reading Experience
- [x] High-quality PDF rendering (Syncfusion)
- [x] Smooth page navigation
- [x] Reading progress percentage
- [x] Remember last position
- [ ] EPUB rendering (coming soon)
- [ ] Table of contents navigation

### Customization
- [x] Adjustable font size
- [x] Line spacing control
- [x] Margin width settings
- [x] Light / Dark theme
- [ ] Sepia theme
- [ ] Font family selection

### Offline & Sync
- [x] Local SQLite caching
- [x] Offline reading support
- [x] Automatic progress sync
- [x] Cross-device synchronization

---

## Screenshots

<p align="center">
  <em>Screenshots coming soon</em>
</p>

<!--
<p align="center">
  <img src="docs/screenshots/login.png" width="200" alt="Login">
  <img src="docs/screenshots/library.png" width="200" alt="Library">
  <img src="docs/screenshots/reader.png" width="200" alt="Reader">
  <img src="docs/screenshots/settings.png" width="200" alt="Settings">
</p>
-->

---

## Installation

### Prerequisites

| Requirement | Version |
|-------------|---------|
| Flutter SDK | 3.1 or higher |
| Python | 3.9 or higher |
| Git | Latest |

### Quick Start

#### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/diread.git
cd diread
```

#### 2. Backend Setup

```bash
# Navigate to backend
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your settings (see Configuration section)

# Run server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

Interactive API docs: `http://localhost:8000/docs`

#### 3. Frontend Setup

```bash
# From project root
cd ..

# Install Flutter dependencies
flutter pub get

# Configure API endpoint (edit lib/core/config/app_config.dart)
# Set baseUrl to your backend server address

# Run the app
flutter run
```

### Platform-Specific Commands

```bash
# iOS (requires macOS)
flutter run -d ios

# Android
flutter run -d android

# macOS Desktop
flutter run -d macos

# Web
flutter run -d chrome
```

---

## Configuration

### Backend Environment Variables

Create a `.env` file in the `backend/` directory:

```env
# Required
SECRET_KEY=your-super-secret-key-change-this-in-production

# Database (SQLite default, PostgreSQL for production)
DATABASE_URL=sqlite+aiosqlite:///./diread.db

# File Storage
STORAGE_TYPE=local
STORAGE_PATH=./storage

# Token Expiry
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=30

# Upload Limits
MAX_FILE_SIZE_MB=100
ALLOWED_EXTENSIONS=pdf,epub
```

### Frontend Configuration

Edit `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  // Your backend server URL
  static const String baseUrl = 'http://localhost:8000';

  // For production, use your deployed server:
  // static const String baseUrl = 'https://api.yourdiread.com';
}
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Backend Guide](backend/README.md) | API server setup and configuration |
| [API Reference](docs/API.md) | Complete API documentation |
| [Architecture](docs/ARCHITECTURE.md) | System design and structure |
| [Contributing](CONTRIBUTING.md) | How to contribute |

---

## Tech Stack

### Frontend

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform UI framework |
| **Provider** | State management |
| **go_router** | Declarative routing |
| **Dio** | HTTP client with interceptors |
| **SQLite** | Local offline database |
| **Syncfusion PDF Viewer** | PDF rendering |
| **flutter_secure_storage** | Secure token storage |

### Backend

| Technology | Purpose |
|------------|---------|
| **FastAPI** | Modern async REST API |
| **SQLAlchemy** | Async ORM |
| **Pydantic** | Data validation |
| **PyJWT** | JWT authentication |
| **bcrypt** | Password hashing |
| **PyPDF2** | PDF metadata extraction |
| **ebooklib** | EPUB parsing |

---

## Project Structure

```
diread/
├── lib/                              # Flutter application
│   ├── core/                         # Core utilities
│   │   ├── config/                   # App & theme configuration
│   │   ├── constants/                # API constants
│   │   ├── errors/                   # Exception definitions
│   │   └── utils/                    # Validators, helpers
│   ├── data/                         # Data layer
│   │   ├── local/                    # Local database
│   │   ├── models/                   # Data models
│   │   ├── repositories/             # Repository pattern
│   │   └── services/                 # API services
│   └── presentation/                 # UI layer
│       ├── providers/                # State management
│       ├── screens/                  # App screens
│       │   ├── auth/                 # Login, Register, Forgot Password
│       │   ├── library/              # Library, Book Details
│       │   ├── reader/               # PDF, EPUB readers
│       │   └── profile/              # User profile
│       └── widgets/                  # Reusable components
│
├── backend/                          # FastAPI server
│   ├── app/
│   │   ├── models/                   # Database models
│   │   ├── routers/                  # API endpoints
│   │   ├── schemas/                  # Request/Response schemas
│   │   ├── services/                 # Business logic
│   │   └── utils/                    # Security, helpers
│   ├── main.py                       # Application entry
│   ├── requirements.txt              # Python dependencies
│   └── Dockerfile                    # Container config
│
├── assets/                           # Static assets
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── docs/                             # Documentation
│   ├── API.md
│   └── ARCHITECTURE.md
│
└── pubspec.yaml                      # Flutter dependencies
```

---

## API Overview

### Authentication

```
POST /api/v1/auth/register    # Create account
POST /api/v1/auth/login       # Sign in
POST /api/v1/auth/refresh     # Refresh token
POST /api/v1/auth/logout      # Sign out
```

### Books

```
GET    /api/v1/books              # List all books
POST   /api/v1/books/upload       # Upload new book
GET    /api/v1/books/{id}         # Get book details
DELETE /api/v1/books/{id}         # Delete book
GET    /api/v1/books/{id}/download # Download file
```

### Reading Progress

```
GET /api/v1/books/{id}/progress   # Get progress
PUT /api/v1/books/{id}/progress   # Update progress
```

### Bookmarks & Highlights

```
GET    /api/v1/books/{id}/bookmarks           # List bookmarks
POST   /api/v1/books/{id}/bookmarks           # Add bookmark
DELETE /api/v1/books/{id}/bookmarks/{bid}     # Remove bookmark

GET    /api/v1/books/{id}/highlights          # List highlights
POST   /api/v1/books/{id}/highlights          # Add highlight
PUT    /api/v1/books/{id}/highlights/{hid}    # Update highlight
DELETE /api/v1/books/{id}/highlights/{hid}    # Remove highlight
```

> Full API documentation available at `/docs` when running the server.

---

## Deployment

### Backend (Production)

#### Option 1: Railway

```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
railway login
railway init
railway up
```

#### Option 2: Docker

```bash
cd backend
docker build -t diread-api .
docker run -p 8000:8000 --env-file .env diread-api
```

#### Option 3: Manual VPS

```bash
# On your server
git clone <repo>
cd diread/backend
pip install -r requirements.txt
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000
```

### Mobile App (Release Build)

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS + Apple Developer account)
flutter build ios --release
```

---

## Roadmap

### Version 1.1 (Next)
- [ ] EPUB reader implementation
- [ ] Password reset via email
- [ ] Search inside books

### Version 1.2
- [ ] Font family selection
- [ ] Sepia reading theme
- [ ] Table of contents (EPUB)

### Future
- [ ] Family sharing features
- [ ] Book collections/folders
- [ ] Reading statistics & goals
- [ ] Annotations export (PDF/Markdown)
- [ ] Text-to-speech

---

## Security

| Feature | Implementation |
|---------|----------------|
| Password Storage | bcrypt with salt |
| Authentication | JWT with short-lived access tokens |
| Token Refresh | Secure refresh token rotation |
| File Access | Authenticated endpoints only |
| Communication | HTTPS required in production |

---

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```bash
# Fork the repo
# Create your feature branch
git checkout -b feature/amazing-feature

# Commit your changes
git commit -m 'Add amazing feature'

# Push to the branch
git push origin feature/amazing-feature

# Open a Pull Request
```

---

## License

This project is for private/family use. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Flutter](https://flutter.dev) — Beautiful native apps
- [FastAPI](https://fastapi.tiangolo.com) — Modern Python web framework
- [Syncfusion](https://www.syncfusion.com) — PDF viewer component

---

<p align="center">
  Made with ❤️ for families who love reading
</p>

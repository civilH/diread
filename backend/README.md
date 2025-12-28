# diRead Backend API

FastAPI-based REST API server for the diRead application.

## Quick Start

### Prerequisites

- Python 3.9 or higher
- pip (Python package manager)

### Installation

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt
```

### Configuration

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your settings:
   ```env
   SECRET_KEY=your-secure-secret-key-here
   DATABASE_URL=sqlite+aiosqlite:///./diread.db
   STORAGE_TYPE=local
   STORAGE_PATH=./storage
   ```

### Running the Server

```bash
# Development (with auto-reload)
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Production
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000
```

### API Documentation

Once the server is running, access:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SECRET_KEY` | JWT signing key | - | Yes |
| `DATABASE_URL` | Database connection string | `sqlite+aiosqlite:///./diread.db` | No |
| `STORAGE_TYPE` | Storage backend (`local`, `s3`, `r2`) | `local` | No |
| `STORAGE_PATH` | Local storage directory | `./storage` | No |
| `S3_BUCKET` | S3 bucket name | - | If S3 |
| `S3_ACCESS_KEY` | S3 access key | - | If S3 |
| `S3_SECRET_KEY` | S3 secret key | - | If S3 |
| `S3_ENDPOINT` | S3 endpoint (for R2/MinIO) | - | If S3 |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | JWT access token expiry | `15` | No |
| `REFRESH_TOKEN_EXPIRE_DAYS` | Refresh token expiry | `30` | No |
| `MAX_FILE_SIZE_MB` | Maximum upload size | `100` | No |

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── config.py           # Configuration management
│   ├── database.py         # Database connection
│   │
│   ├── models/             # SQLAlchemy ORM models
│   │   ├── user.py         # User model
│   │   ├── book.py         # Book model
│   │   ├── progress.py     # Reading progress
│   │   ├── bookmark.py     # Bookmarks
│   │   ├── highlight.py    # Highlights
│   │   └── refresh_token.py
│   │
│   ├── schemas/            # Pydantic schemas
│   │   ├── auth.py         # Auth request/response
│   │   ├── user.py         # User schemas
│   │   ├── book.py         # Book schemas
│   │   ├── progress.py     # Progress schemas
│   │   ├── bookmark.py     # Bookmark schemas
│   │   └── highlight.py    # Highlight schemas
│   │
│   ├── routers/            # API endpoints
│   │   ├── auth.py         # Authentication routes
│   │   ├── users.py        # User routes
│   │   ├── books.py        # Book routes
│   │   ├── progress.py     # Progress routes
│   │   ├── bookmarks.py    # Bookmark routes
│   │   └── highlights.py   # Highlight routes
│   │
│   ├── services/           # Business logic
│   │   ├── auth_service.py     # Auth operations
│   │   ├── book_service.py     # Book operations
│   │   └── storage_service.py  # File storage
│   │
│   └── utils/
│       └── security.py     # JWT, password hashing
│
├── main.py                 # Application entry point
├── requirements.txt        # Python dependencies
├── Dockerfile              # Container configuration
├── railway.toml            # Railway deployment config
└── .env.example            # Environment template
```

## Database Models

### User
```
- id: UUID (Primary Key)
- email: String (Unique)
- hashed_password: String
- name: String
- avatar_url: String (Optional)
- created_at: DateTime
- updated_at: DateTime
```

### Book
```
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key)
- title: String
- author: String
- cover_url: String (Optional)
- file_url: String
- file_type: Enum (PDF, EPUB)
- file_size: Integer
- total_pages: Integer
- metadata: JSON
- created_at: DateTime
```

### ReadingProgress
```
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key)
- book_id: UUID (Foreign Key)
- current_page: Integer
- current_cfi: String (EPUB position)
- progress_percent: Float
- last_read_at: DateTime
```

### Bookmark
```
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key)
- book_id: UUID (Foreign Key)
- page_number: Integer
- cfi: String (EPUB position)
- title: String
- created_at: DateTime
```

### Highlight
```
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key)
- book_id: UUID (Foreign Key)
- text: String
- page_number: Integer
- cfi: String (EPUB position)
- color: Enum (yellow, green, blue, pink, purple)
- note: String (Optional)
- created_at: DateTime
```

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| POST | `/api/v1/auth/logout` | Logout |
| POST | `/api/v1/auth/forgot-password` | Request password reset |
| POST | `/api/v1/auth/reset-password` | Reset password |

### Users
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/users/profile` | Get current user |
| PUT | `/api/v1/users/profile` | Update profile |

### Books
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/books` | List user's books |
| POST | `/api/v1/books/upload` | Upload book |
| GET | `/api/v1/books/{id}` | Get book |
| DELETE | `/api/v1/books/{id}` | Delete book |
| GET | `/api/v1/books/{id}/download` | Download file |

### Progress
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/books/{id}/progress` | Get progress |
| PUT | `/api/v1/books/{id}/progress` | Update progress |

### Bookmarks
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/books/{id}/bookmarks` | List bookmarks |
| POST | `/api/v1/books/{id}/bookmarks` | Create bookmark |
| DELETE | `/api/v1/books/{id}/bookmarks/{bid}` | Delete bookmark |

### Highlights
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/books/{id}/highlights` | List highlights |
| POST | `/api/v1/books/{id}/highlights` | Create highlight |
| PUT | `/api/v1/books/{id}/highlights/{hid}` | Update highlight |
| DELETE | `/api/v1/books/{id}/highlights/{hid}` | Delete highlight |

## Deployment

### Docker

```bash
# Build image
docker build -t diread-api .

# Run container
docker run -d \
  -p 8000:8000 \
  -e SECRET_KEY=your-secret-key \
  -e DATABASE_URL=sqlite+aiosqlite:///./diread.db \
  -v $(pwd)/storage:/app/storage \
  diread-api
```

### Railway

```bash
railway login
railway init
railway up
```

### Production Checklist

- [ ] Set strong `SECRET_KEY`
- [ ] Use PostgreSQL instead of SQLite
- [ ] Configure cloud storage (S3/R2)
- [ ] Enable HTTPS
- [ ] Set up database backups
- [ ] Configure CORS properly
- [ ] Add rate limiting
- [ ] Set up monitoring/logging

## Testing

```bash
# Run tests
pytest

# With coverage
pytest --cov=app tests/
```

## Security Considerations

- Passwords hashed with bcrypt (work factor 12)
- JWT access tokens expire in 15 minutes
- Refresh tokens stored hashed in database
- File access requires authentication
- CORS configured for allowed origins only

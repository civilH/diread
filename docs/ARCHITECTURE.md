# diRead Architecture

System design and architecture overview for the diRead application.

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Mobile Apps                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │   iOS    │  │ Android  │  │  macOS   │  │   Web    │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘        │
│       └─────────────┴─────────────┴─────────────┘               │
│                           │                                      │
│                    Flutter App                                   │
│       ┌───────────────────┴───────────────────┐                 │
│       │  Provider (State Management)          │                 │
│       │  go_router (Navigation)               │                 │
│       │  Dio (HTTP Client)                    │                 │
│       │  SQLite (Local Cache)                 │                 │
│       └───────────────────┬───────────────────┘                 │
└───────────────────────────┼─────────────────────────────────────┘
                            │ HTTPS
                            ▼
┌───────────────────────────────────────────────────────────────┐
│                      Backend API                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                    FastAPI Server                        │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │  │
│  │  │  Auth    │  │  Books   │  │  Users   │              │  │
│  │  │  Router  │  │  Router  │  │  Router  │              │  │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘              │  │
│  │       └─────────────┴─────────────┘                     │  │
│  │                     │                                    │  │
│  │       ┌─────────────┴─────────────┐                     │  │
│  │       │      Services Layer       │                     │  │
│  │       │  (Business Logic)         │                     │  │
│  │       └─────────────┬─────────────┘                     │  │
│  │                     │                                    │  │
│  │  ┌──────────────────┴──────────────────┐               │  │
│  │  │         SQLAlchemy ORM              │               │  │
│  │  └──────────────────┬──────────────────┘               │  │
│  └─────────────────────┼───────────────────────────────────┘  │
└────────────────────────┼──────────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        ▼                                  ▼
┌───────────────┐                 ┌───────────────┐
│   Database    │                 │  File Storage │
│  (SQLite/     │                 │  (Local/S3/   │
│   PostgreSQL) │                 │   R2)         │
└───────────────┘                 └───────────────┘
```

## Frontend Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │   Screens   │  │   Widgets   │  │  Providers  │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────┴────────────────────────────┐
│                    Data Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │   Models    │  │ Repositories│  │  Services   │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────┴────────────────────────────┐
│                    Core Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │   Config    │  │    Utils    │  │   Errors    │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────┘
```

### State Management (Provider)

```dart
// Provider hierarchy
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProxyProvider<AuthProvider, LibraryProvider>(...),
    ChangeNotifierProxyProvider<AuthProvider, ReaderProvider>(...),
  ],
  child: App(),
)
```

### Navigation (go_router)

```
/login          → LoginScreen
/register       → RegisterScreen
/forgot-password → ForgotPasswordScreen
/library        → LibraryScreen (authenticated)
/book/:id       → BookDetailScreen
/reader/:id     → ReaderScreen
/profile        → ProfileScreen
```

## Backend Architecture

### Service Layer Pattern

```
Router (HTTP) → Service (Logic) → Repository (Data) → Model (DB)
```

### Authentication Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │────▶│  Login   │────▶│ Validate │────▶│  Issue   │
│          │     │ Endpoint │     │ Password │     │  Tokens  │
└──────────┘     └──────────┘     └──────────┘     └────┬─────┘
                                                        │
     ┌──────────────────────────────────────────────────┘
     ▼
┌──────────┐     ┌──────────┐
│  Access  │     │ Refresh  │
│  Token   │     │  Token   │
│ (15 min) │     │ (30 day) │
└──────────┘     └──────────┘
```

### Token Refresh Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │────▶│ Refresh  │────▶│ Validate │────▶│  Issue   │
│          │     │ Endpoint │     │  Token   │     │  New AT  │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
```

### File Upload Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │────▶│ Validate │────▶│ Extract  │────▶│  Store   │
│  Upload  │     │ File     │     │ Metadata │     │  File    │
└──────────┘     └──────────┘     └──────────┘     └────┬─────┘
                                                        │
     ┌──────────────────────────────────────────────────┘
     ▼
┌──────────┐     ┌──────────┐
│  Create  │────▶│ Return   │
│  Book    │     │ Response │
│  Record  │     │          │
└──────────┘     └──────────┘
```

## Database Schema

### Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐
│      User       │       │      Book       │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │
│ email           │◄──────│ user_id (FK)    │
│ hashed_password │       │ title           │
│ name            │       │ author          │
│ avatar_url      │       │ cover_url       │
│ created_at      │       │ file_url        │
│ updated_at      │       │ file_type       │
└────────┬────────┘       │ file_size       │
         │                │ total_pages     │
         │                │ created_at      │
         │                └────────┬────────┘
         │                         │
         │    ┌────────────────────┼────────────────────┐
         │    │                    │                    │
         ▼    ▼                    ▼                    ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ ReadingProgress │    │    Bookmark     │    │    Highlight    │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ id (PK)         │    │ id (PK)         │    │ id (PK)         │
│ user_id (FK)    │    │ user_id (FK)    │    │ user_id (FK)    │
│ book_id (FK)    │    │ book_id (FK)    │    │ book_id (FK)    │
│ current_page    │    │ page_number     │    │ text            │
│ current_cfi     │    │ cfi             │    │ page_number     │
│ progress_percent│    │ title           │    │ cfi             │
│ last_read_at    │    │ created_at      │    │ color           │
└─────────────────┘    └─────────────────┘    │ note            │
                                              │ created_at      │
                                              └─────────────────┘

┌─────────────────┐
│  RefreshToken   │
├─────────────────┤
│ id (PK)         │
│ user_id (FK)    │
│ token_hash      │
│ expires_at      │
│ created_at      │
└─────────────────┘
```

## Offline Architecture

### Local Database Schema

```
┌──────────────────────────────────────────────────────────────┐
│                    SQLite Local Database                      │
├──────────────────────────────────────────────────────────────┤
│  users          - Cached user profile                        │
│  books          - Cached book metadata                       │
│  reading_progress - Cached & pending progress updates        │
│  bookmarks      - Cached & pending bookmarks                 │
│  highlights     - Cached & pending highlights                │
│  pending_sync   - Queue of changes to sync                   │
│  settings       - App settings (theme, font, etc.)           │
└──────────────────────────────────────────────────────────────┘
```

### Sync Strategy

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Online    │    │  Offline    │    │   Sync      │
│   Mode      │    │   Mode      │    │   Mode      │
├─────────────┤    ├─────────────┤    ├─────────────┤
│ Read from   │    │ Read from   │    │ Push local  │
│ API         │    │ local DB    │    │ changes     │
│             │    │             │    │             │
│ Write to    │    │ Write to    │    │ Pull remote │
│ API + local │    │ local only  │    │ changes     │
│             │    │             │    │             │
│ Cache       │    │ Queue sync  │    │ Resolve     │
│ responses   │    │ operations  │    │ conflicts   │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Security Architecture

### Password Storage

```
Password → bcrypt(password, salt, rounds=12) → hashed_password
```

### JWT Structure

```json
// Access Token Payload
{
  "sub": "user-uuid",
  "exp": 1704067200,
  "iat": 1704066300,
  "type": "access"
}

// Refresh Token Payload
{
  "sub": "user-uuid",
  "exp": 1706659200,
  "iat": 1704066300,
  "type": "refresh",
  "jti": "unique-token-id"
}
```

### Request Authentication

```
Client                    Server
  │                         │
  │  GET /api/v1/books      │
  │  Authorization: Bearer  │
  │  <access_token>         │
  │────────────────────────▶│
  │                         │ Validate JWT
  │                         │ Check expiry
  │                         │ Extract user_id
  │      200 OK             │
  │◀────────────────────────│
  │                         │
```

## File Storage Architecture

### Storage Abstraction

```python
class StorageService:
    def upload(file, path) -> url
    def download(path) -> bytes
    def delete(path) -> bool
    def get_url(path) -> signed_url

# Implementations
LocalStorage      # Development
S3Storage         # AWS
R2Storage         # Cloudflare
```

### File Organization

```
storage/
├── books/
│   └── {user_id}/
│       └── {book_id}.{pdf|epub}
├── covers/
│   └── {book_id}.jpg
└── avatars/
    └── {user_id}.jpg
```

## Scalability Considerations

### Horizontal Scaling

```
                    ┌─────────────┐
                    │   Load      │
                    │   Balancer  │
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │   API       │ │   API       │ │   API       │
    │   Server 1  │ │   Server 2  │ │   Server N  │
    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
           └───────────────┼───────────────┘
                           ▼
                    ┌─────────────┐
                    │ PostgreSQL  │
                    │  (Primary)  │
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    ▼             ▼
             ┌───────────┐ ┌───────────┐
             │  Replica  │ │  Replica  │
             └───────────┘ └───────────┘
```

### Caching Strategy

```
Client Request
      │
      ▼
┌─────────────┐    Miss    ┌─────────────┐
│   Redis     │───────────▶│  Database   │
│   Cache     │            └──────┬──────┘
└──────┬──────┘                   │
       │ Hit                      │
       ▼                          ▼
   Response ◀─────────────── Update Cache
```

## Future Considerations

1. **Real-time Sync**: WebSocket for live progress updates
2. **CDN**: CloudFront/Cloudflare for book file delivery
3. **Search**: Elasticsearch for full-text book search
4. **Analytics**: Reading statistics and insights
5. **Push Notifications**: Reading reminders

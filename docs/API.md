# diRead API Reference

Complete API documentation for the diRead backend.

**Base URL**: `http://localhost:8000/api/v1`

## Authentication

All endpoints except `/auth/register` and `/auth/login` require authentication.

Include the JWT token in the Authorization header:
```
Authorization: Bearer <access_token>
```

---

## Auth Endpoints

### Register

Create a new user account.

```http
POST /auth/register
```

**Request Body**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "name": "John Doe"
}
```

**Response** `201 Created`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "John Doe",
  "avatar_url": null,
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Errors**
- `400` - Email already registered
- `422` - Validation error

---

### Login

Authenticate and receive tokens.

```http
POST /auth/login
```

**Request Body**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response** `200 OK`
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 900,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

**Errors**
- `401` - Invalid credentials

---

### Refresh Token

Get a new access token using refresh token.

```http
POST /auth/refresh
```

**Request Body**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response** `200 OK`
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 900
}
```

**Errors**
- `401` - Invalid or expired refresh token

---

### Logout

Invalidate the current refresh token.

```http
POST /auth/logout
```

**Headers**
```
Authorization: Bearer <access_token>
```

**Request Body**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response** `200 OK`
```json
{
  "message": "Successfully logged out"
}
```

---

### Forgot Password

Request a password reset email.

```http
POST /auth/forgot-password
```

**Request Body**
```json
{
  "email": "user@example.com"
}
```

**Response** `200 OK`
```json
{
  "message": "If the email exists, a reset link has been sent"
}
```

> Note: Always returns 200 to prevent email enumeration.

---

### Reset Password

Reset password with token from email.

```http
POST /auth/reset-password
```

**Request Body**
```json
{
  "token": "reset-token-from-email",
  "password": "newpassword123"
}
```

**Response** `200 OK`
```json
{
  "message": "Password successfully reset"
}
```

**Errors**
- `400` - Invalid or expired token

---

## User Endpoints

### Get Profile

Get current user's profile.

```http
GET /users/profile
```

**Response** `200 OK`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "John Doe",
  "avatar_url": "https://storage.example.com/avatars/user.jpg",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-20T15:45:00Z"
}
```

---

### Update Profile

Update current user's profile.

```http
PUT /users/profile
```

**Request Body**
```json
{
  "name": "John Smith",
  "avatar_url": "https://example.com/avatar.jpg"
}
```

**Response** `200 OK`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "John Smith",
  "avatar_url": "https://example.com/avatar.jpg",
  "updated_at": "2024-01-20T16:00:00Z"
}
```

---

## Book Endpoints

### List Books

Get all books for the current user.

```http
GET /books
```

**Query Parameters**
| Parameter | Type | Description |
|-----------|------|-------------|
| `sort` | string | Sort by: `title`, `author`, `created_at`, `last_read` |
| `order` | string | Order: `asc`, `desc` (default: `desc`) |

**Response** `200 OK`
```json
{
  "books": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "title": "The Great Gatsby",
      "author": "F. Scott Fitzgerald",
      "cover_url": "https://storage.example.com/covers/gatsby.jpg",
      "file_type": "pdf",
      "file_size": 2456789,
      "total_pages": 180,
      "created_at": "2024-01-15T10:30:00Z",
      "progress": {
        "current_page": 45,
        "progress_percent": 25.0,
        "last_read_at": "2024-01-20T15:45:00Z"
      }
    }
  ],
  "total": 1
}
```

---

### Upload Book

Upload a new book (PDF or EPUB).

```http
POST /books/upload
Content-Type: multipart/form-data
```

**Form Data**
| Field | Type | Description |
|-------|------|-------------|
| `file` | file | PDF or EPUB file (max 100MB) |

**Response** `201 Created`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "title": "The Great Gatsby",
  "author": "F. Scott Fitzgerald",
  "cover_url": "https://storage.example.com/covers/gatsby.jpg",
  "file_url": "https://storage.example.com/books/gatsby.pdf",
  "file_type": "pdf",
  "file_size": 2456789,
  "total_pages": 180,
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Errors**
- `400` - Invalid file type
- `413` - File too large

---

### Get Book

Get a specific book's details.

```http
GET /books/{book_id}
```

**Response** `200 OK`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "title": "The Great Gatsby",
  "author": "F. Scott Fitzgerald",
  "cover_url": "https://storage.example.com/covers/gatsby.jpg",
  "file_url": "https://storage.example.com/books/gatsby.pdf",
  "file_type": "pdf",
  "file_size": 2456789,
  "total_pages": 180,
  "metadata": {
    "publisher": "Scribner",
    "year": "1925"
  },
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Errors**
- `404` - Book not found

---

### Delete Book

Delete a book and its associated data.

```http
DELETE /books/{book_id}
```

**Response** `200 OK`
```json
{
  "message": "Book deleted successfully"
}
```

**Errors**
- `404` - Book not found

---

### Download Book

Download the book file.

```http
GET /books/{book_id}/download
```

**Response** `200 OK`
- Returns the file with appropriate content-type
- `Content-Disposition: attachment; filename="book.pdf"`

**Errors**
- `404` - Book not found

---

## Progress Endpoints

### Get Progress

Get reading progress for a book.

```http
GET /books/{book_id}/progress
```

**Response** `200 OK`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "book_id": "550e8400-e29b-41d4-a716-446655440001",
  "current_page": 45,
  "current_cfi": null,
  "progress_percent": 25.0,
  "last_read_at": "2024-01-20T15:45:00Z"
}
```

**Errors**
- `404` - Progress not found (book never opened)

---

### Update Progress

Update reading progress.

```http
PUT /books/{book_id}/progress
```

**Request Body**
```json
{
  "current_page": 50,
  "current_cfi": "epubcfi(/6/4!/4/2/1:0)",
  "progress_percent": 27.8
}
```

**Response** `200 OK`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "book_id": "550e8400-e29b-41d4-a716-446655440001",
  "current_page": 50,
  "current_cfi": "epubcfi(/6/4!/4/2/1:0)",
  "progress_percent": 27.8,
  "last_read_at": "2024-01-20T16:00:00Z"
}
```

---

## Bookmark Endpoints

### List Bookmarks

Get all bookmarks for a book.

```http
GET /books/{book_id}/bookmarks
```

**Response** `200 OK`
```json
{
  "bookmarks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "book_id": "550e8400-e29b-41d4-a716-446655440001",
      "page_number": 45,
      "cfi": null,
      "title": "Chapter 3 - The Party",
      "created_at": "2024-01-18T12:00:00Z"
    }
  ],
  "total": 1
}
```

---

### Create Bookmark

Add a new bookmark.

```http
POST /books/{book_id}/bookmarks
```

**Request Body**
```json
{
  "page_number": 45,
  "cfi": "epubcfi(/6/4!/4/2/1:0)",
  "title": "Chapter 3 - The Party"
}
```

**Response** `201 Created`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "book_id": "550e8400-e29b-41d4-a716-446655440001",
  "page_number": 45,
  "cfi": "epubcfi(/6/4!/4/2/1:0)",
  "title": "Chapter 3 - The Party",
  "created_at": "2024-01-18T12:00:00Z"
}
```

---

### Delete Bookmark

Remove a bookmark.

```http
DELETE /books/{book_id}/bookmarks/{bookmark_id}
```

**Response** `200 OK`
```json
{
  "message": "Bookmark deleted successfully"
}
```

**Errors**
- `404` - Bookmark not found

---

## Highlight Endpoints

### List Highlights

Get all highlights for a book.

```http
GET /books/{book_id}/highlights
```

**Response** `200 OK`
```json
{
  "highlights": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440004",
      "book_id": "550e8400-e29b-41d4-a716-446655440001",
      "text": "So we beat on, boats against the current...",
      "page_number": 180,
      "cfi": null,
      "color": "yellow",
      "note": "Famous last line",
      "created_at": "2024-01-19T14:30:00Z"
    }
  ],
  "total": 1
}
```

---

### Create Highlight

Add a new highlight.

```http
POST /books/{book_id}/highlights
```

**Request Body**
```json
{
  "text": "So we beat on, boats against the current...",
  "page_number": 180,
  "cfi": "epubcfi(/6/4!/4/2/1:0)",
  "color": "yellow",
  "note": "Famous last line"
}
```

**Available Colors**
- `yellow`
- `green`
- `blue`
- `pink`
- `purple`

**Response** `201 Created`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "book_id": "550e8400-e29b-41d4-a716-446655440001",
  "text": "So we beat on, boats against the current...",
  "page_number": 180,
  "cfi": "epubcfi(/6/4!/4/2/1:0)",
  "color": "yellow",
  "note": "Famous last line",
  "created_at": "2024-01-19T14:30:00Z"
}
```

---

### Update Highlight

Update a highlight's color or note.

```http
PUT /books/{book_id}/highlights/{highlight_id}
```

**Request Body**
```json
{
  "color": "blue",
  "note": "Updated note about this passage"
}
```

**Response** `200 OK`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "book_id": "550e8400-e29b-41d4-a716-446655440001",
  "text": "So we beat on, boats against the current...",
  "page_number": 180,
  "color": "blue",
  "note": "Updated note about this passage",
  "created_at": "2024-01-19T14:30:00Z"
}
```

---

### Delete Highlight

Remove a highlight.

```http
DELETE /books/{book_id}/highlights/{highlight_id}
```

**Response** `200 OK`
```json
{
  "message": "Highlight deleted successfully"
}
```

**Errors**
- `404` - Highlight not found

---

## Error Responses

All errors follow this format:

```json
{
  "detail": "Error message describing what went wrong"
}
```

### Common HTTP Status Codes

| Code | Description |
|------|-------------|
| `200` | Success |
| `201` | Created |
| `400` | Bad Request - Invalid input |
| `401` | Unauthorized - Invalid/missing token |
| `403` | Forbidden - Not allowed |
| `404` | Not Found - Resource doesn't exist |
| `413` | Payload Too Large - File exceeds limit |
| `422` | Validation Error - Invalid data format |
| `500` | Internal Server Error |

---

## Rate Limiting

Currently, no rate limiting is implemented. For production, consider implementing:
- 100 requests/minute for authenticated users
- 10 requests/minute for unauthenticated endpoints

---

## Pagination

For endpoints that return lists, pagination is available:

```http
GET /books?page=1&per_page=20
```

| Parameter | Type | Default | Max |
|-----------|------|---------|-----|
| `page` | int | 1 | - |
| `per_page` | int | 20 | 100 |

Response includes:
```json
{
  "items": [...],
  "total": 50,
  "page": 1,
  "per_page": 20,
  "pages": 3
}
```

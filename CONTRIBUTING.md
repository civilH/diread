# Contributing to diRead

Thank you for your interest in contributing to diRead! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Coding Standards](#coding-standards)
- [Commit Messages](#commit-messages)
- [Pull Requests](#pull-requests)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/diread.git
   cd diread
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/diread.git
   ```

## Development Setup

### Backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your settings
uvicorn main:app --reload
```

### Frontend

```bash
flutter pub get
# Edit lib/core/config/app_config.dart with your backend URL
flutter run
```

### Running Tests

```bash
# Backend tests
cd backend
pytest

# Frontend tests
flutter test
```

## Making Changes

### Branch Naming

Use descriptive branch names:

- `feature/add-epub-reader` - New features
- `fix/login-error-handling` - Bug fixes
- `docs/update-api-docs` - Documentation
- `refactor/auth-service` - Code refactoring

### Workflow

1. Create a new branch from `main`:
   ```bash
   git checkout main
   git pull upstream main
   git checkout -b feature/your-feature-name
   ```

2. Make your changes

3. Test your changes:
   ```bash
   # Backend
   pytest

   # Frontend
   flutter test
   flutter analyze
   ```

4. Commit your changes (see [Commit Messages](#commit-messages))

5. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

6. Create a Pull Request

## Coding Standards

### Flutter/Dart

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep widgets small and focused
- Use `const` constructors where possible

```dart
// Good
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    this.onTap,
  });

  final Book book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // ...
  }
}

// Bad
class bookcard extends StatelessWidget {
  var b;
  var tap;
  // ...
}
```

### Python/FastAPI

- Follow [PEP 8](https://pep8.org/) style guide
- Use type hints for function parameters and return values
- Write docstrings for functions and classes
- Keep functions focused and small

```python
# Good
async def get_book_by_id(
    book_id: UUID,
    user_id: UUID,
    db: AsyncSession
) -> Book:
    """
    Retrieve a book by its ID.

    Args:
        book_id: The unique identifier of the book
        user_id: The ID of the user requesting the book
        db: Database session

    Returns:
        The book if found and owned by user

    Raises:
        HTTPException: If book not found or not owned by user
    """
    # ...

# Bad
async def get(id, uid, db):
    # ...
```

### File Organization

```
# Flutter - Keep related files together
lib/presentation/screens/reader/
├── reader_screen.dart      # Main screen
├── pdf_reader.dart         # PDF-specific widget
├── epub_reader.dart        # EPUB-specific widget
└── reader_settings.dart    # Settings sheet

# Python - Group by functionality
app/routers/
├── __init__.py
├── auth.py
├── books.py
└── users.py
```

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
# Feature
feat(reader): add highlight color selection

# Bug fix
fix(auth): handle token refresh race condition

# Documentation
docs(api): add endpoint documentation for bookmarks

# Refactor
refactor(storage): extract file validation to separate function
```

## Pull Requests

### Before Submitting

- [ ] Code compiles without errors
- [ ] All tests pass
- [ ] Code follows project style guidelines
- [ ] Documentation is updated (if applicable)
- [ ] Commit messages follow conventions

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## How to Test
Steps to test the changes

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Code follows style guidelines
```

### Review Process

1. Submit your PR
2. Maintainers will review your code
3. Address any requested changes
4. Once approved, your PR will be merged

## Reporting Issues

### Bug Reports

Include:
- Clear description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Environment details (OS, Flutter version, etc.)

### Feature Requests

Include:
- Clear description of the feature
- Use case / problem it solves
- Proposed implementation (optional)
- Mockups (if applicable)

### Issue Template

```markdown
## Description
Clear description of the issue or feature

## Steps to Reproduce (for bugs)
1. Go to '...'
2. Click on '...'
3. See error

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., macOS 14.0]
- Flutter: [e.g., 3.16.0]
- Device: [e.g., iPhone 15 Pro]

## Screenshots
If applicable

## Additional Context
Any other relevant information
```

## Questions?

If you have questions, feel free to:
- Open an issue with the `question` label
- Start a discussion in the Discussions tab

Thank you for contributing!

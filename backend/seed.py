#!/usr/bin/env python3
"""
Database seed script for diRead.
Creates dummy users and sample data for testing.

Usage:
    cd backend
    source venv/bin/activate
    python seed.py
"""

import asyncio
import uuid
from datetime import datetime
from passlib.context import CryptContext
from sqlalchemy import text

# Database setup
import sqlite3

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def seed_database():
    """Seed the database with dummy users."""

    # Connect to SQLite database
    conn = sqlite3.connect('diread.db')
    cursor = conn.cursor()

    print("=" * 50)
    print("diRead Database Seeder")
    print("=" * 50)

    # Dummy users data
    users = [
        {
            "id": str(uuid.uuid4()),
            "email": "admin@diread.app",
            "password": "admin123",
            "name": "Admin User",
        },
        {
            "id": str(uuid.uuid4()),
            "email": "test@example.com",
            "password": "test1234",
            "name": "Test User",
        },
        {
            "id": str(uuid.uuid4()),
            "email": "john@family.com",
            "password": "john1234",
            "name": "John Doe",
        },
        {
            "id": str(uuid.uuid4()),
            "email": "jane@family.com",
            "password": "jane1234",
            "name": "Jane Doe",
        },
        {
            "id": str(uuid.uuid4()),
            "email": "demo@diread.app",
            "password": "demo1234",
            "name": "Demo Account",
        },
    ]

    print("\nCreating dummy users...")
    print("-" * 50)

    created_count = 0
    skipped_count = 0

    for user in users:
        # Check if user already exists
        cursor.execute("SELECT id FROM users WHERE email = ?", (user["email"],))
        existing = cursor.fetchone()

        if existing:
            print(f"  [SKIP] {user['email']} (already exists)")
            skipped_count += 1
            continue

        # Hash password
        password_hash = get_password_hash(user["password"])
        now = datetime.utcnow().isoformat()

        # Insert user
        cursor.execute("""
            INSERT INTO users (id, email, password_hash, name, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (user["id"], user["email"], password_hash, user["name"], now, now))

        print(f"  [OK] {user['email']} (password: {user['password']})")
        created_count += 1

    conn.commit()

    print("-" * 50)
    print(f"Created: {created_count} users")
    print(f"Skipped: {skipped_count} users (already exist)")

    # Show all users
    print("\n" + "=" * 50)
    print("All Users in Database:")
    print("=" * 50)

    cursor.execute("SELECT id, email, name, created_at FROM users ORDER BY created_at")
    rows = cursor.fetchall()

    print(f"\n{'ID':<40} {'Email':<25} {'Name':<20}")
    print("-" * 85)

    for row in rows:
        user_id, email, name, created = row
        print(f"{user_id:<40} {email:<25} {name or 'N/A':<20}")

    print(f"\nTotal users: {len(rows)}")

    # Show database tables
    print("\n" + "=" * 50)
    print("Database Tables:")
    print("=" * 50)

    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
    tables = cursor.fetchall()

    for table in tables:
        table_name = table[0]
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        print(f"  {table_name}: {count} rows")

    conn.close()

    print("\n" + "=" * 50)
    print("Dummy Accounts for Testing:")
    print("=" * 50)
    print("""
+----------------------+-------------+
| Email                | Password    |
+----------------------+-------------+
| admin@diread.app     | admin123    |
| test@example.com     | test1234    |
| john@family.com      | john1234    |
| jane@family.com      | jane1234    |
| demo@diread.app      | demo1234    |
+----------------------+-------------+
""")


def view_database():
    """View current database contents."""
    conn = sqlite3.connect('diread.db')
    cursor = conn.cursor()

    print("=" * 50)
    print("diRead Database Viewer")
    print("=" * 50)

    # Show tables and counts
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
    tables = cursor.fetchall()

    for table in tables:
        table_name = table[0]
        print(f"\n--- {table_name.upper()} ---")

        # Get column names
        cursor.execute(f"PRAGMA table_info({table_name})")
        columns = [col[1] for col in cursor.fetchall()]

        # Get data
        cursor.execute(f"SELECT * FROM {table_name} LIMIT 20")
        rows = cursor.fetchall()

        if rows:
            # Print header
            print(" | ".join(f"{col[:15]:<15}" for col in columns[:5]))
            print("-" * 80)

            # Print rows
            for row in rows:
                display_row = []
                for val in row[:5]:
                    val_str = str(val)[:15] if val else "NULL"
                    display_row.append(f"{val_str:<15}")
                print(" | ".join(display_row))
        else:
            print("(empty)")

        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        print(f"Total: {count} rows")

    conn.close()


def query_database(sql: str):
    """Execute a custom SQL query."""
    conn = sqlite3.connect('diread.db')
    cursor = conn.cursor()

    try:
        cursor.execute(sql)

        if sql.strip().upper().startswith("SELECT"):
            rows = cursor.fetchall()

            # Get column names from cursor description
            if cursor.description:
                columns = [desc[0] for desc in cursor.description]
                print(" | ".join(columns))
                print("-" * 80)

                for row in rows:
                    print(" | ".join(str(val) for val in row))

                print(f"\n{len(rows)} rows returned")
        else:
            conn.commit()
            print(f"Query executed. Rows affected: {cursor.rowcount}")

    except Exception as e:
        print(f"Error: {e}")

    conn.close()


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        if sys.argv[1] == "view":
            view_database()
        elif sys.argv[1] == "query" and len(sys.argv) > 2:
            query_database(" ".join(sys.argv[2:]))
        else:
            print("Usage:")
            print("  python seed.py          - Seed database with dummy users")
            print("  python seed.py view     - View database contents")
            print("  python seed.py query 'SELECT * FROM users'  - Run custom query")
    else:
        seed_database()

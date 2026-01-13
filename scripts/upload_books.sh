#!/bin/bash

# Bulk Book Upload Script for diRead
# Usage: ./upload_books.sh <folder_path> <email> <password>
#
# Example: ./upload_books.sh ~/Books myemail@example.com mypassword

# Set your server URL here or pass as environment variable
API_BASE="${DIREAD_API_URL:-http://localhost:8000/api/v1}"
FOLDER_PATH="$1"
EMAIL="$2"
PASSWORD="$3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ -z "$FOLDER_PATH" ] || [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
    echo -e "${RED}Usage: $0 <folder_path> <email> <password>${NC}"
    echo "Example: $0 ~/Books myemail@example.com mypassword"
    exit 1
fi

# Check if folder exists
if [ ! -d "$FOLDER_PATH" ]; then
    echo -e "${RED}Error: Folder '$FOLDER_PATH' does not exist${NC}"
    exit 1
fi

echo -e "${YELLOW}=== diRead Bulk Book Uploader ===${NC}"
echo ""

# Step 1: Login to get token
echo -e "${YELLOW}Logging in...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")

# Extract token (using grep and sed for compatibility)
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"//')

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Login failed. Response: $LOGIN_RESPONSE${NC}"
    exit 1
fi

echo -e "${GREEN}Login successful!${NC}"
echo ""

# Step 2: Count books to upload
PDF_COUNT=$(find "$FOLDER_PATH" -maxdepth 1 -type f -name "*.pdf" 2>/dev/null | wc -l | tr -d ' ')
EPUB_COUNT=$(find "$FOLDER_PATH" -maxdepth 1 -type f -name "*.epub" 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$((PDF_COUNT + EPUB_COUNT))

echo -e "${YELLOW}Found $TOTAL books ($PDF_COUNT PDF, $EPUB_COUNT EPUB)${NC}"
echo ""

if [ "$TOTAL" -eq 0 ]; then
    echo -e "${RED}No PDF or EPUB files found in '$FOLDER_PATH'${NC}"
    exit 1
fi

# Step 3: Upload each book
SUCCESS=0
FAILED=0

for file in "$FOLDER_PATH"/*.pdf "$FOLDER_PATH"/*.epub; do
    # Skip if no matches (glob pattern didn't expand)
    [ -e "$file" ] || continue

    FILENAME=$(basename "$file")
    echo -n "Uploading: $FILENAME ... "

    # Upload the file
    RESPONSE=$(curl -s -X POST "$API_BASE/books/upload" \
        -H "Authorization: Bearer $TOKEN" \
        -F "file=@$file")

    # Check if upload was successful
    if echo "$RESPONSE" | grep -q '"id"'; then
        echo -e "${GREEN}OK${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Error: $RESPONSE"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo -e "${YELLOW}=== Upload Complete ===${NC}"
echo -e "${GREEN}Success: $SUCCESS${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""
echo "Refresh your app to see the new books!"

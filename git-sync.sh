#!/bin/bash
#
# EZTeach Git Auto-Sync Script
# 
# This script automatically stages, commits, and pushes all changes to GitHub.
# 
# Usage:
#   ./git-sync.sh              # Auto-commit with timestamp message
#   ./git-sync.sh "message"    # Commit with custom message
#
# To make it executable: chmod +x git-sync.sh
#

cd "$(dirname "$0")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📚 EZTeach Git Sync${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if there are any changes
if git diff-index --quiet HEAD -- && [ -z "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  No changes to sync.${NC}"
    exit 0
fi

# Show what will be synced
echo -e "\n${YELLOW}📝 Changes to sync:${NC}"
git status --short

# Generate commit message
if [ -n "$1" ]; then
    COMMIT_MSG="$1"
else
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    # Count changes
    ADDED=$(git status --short | grep "^??" | wc -l | tr -d ' ')
    MODIFIED=$(git status --short | grep "^ M\|^M " | wc -l | tr -d ' ')
    DELETED=$(git status --short | grep "^ D\|^D " | wc -l | tr -d ' ')
    
    COMMIT_MSG="Auto-sync: ${TIMESTAMP}"
    if [ "$ADDED" -gt 0 ]; then
        COMMIT_MSG="${COMMIT_MSG} (+${ADDED} new)"
    fi
    if [ "$MODIFIED" -gt 0 ]; then
        COMMIT_MSG="${COMMIT_MSG} (~${MODIFIED} modified)"
    fi
    if [ "$DELETED" -gt 0 ]; then
        COMMIT_MSG="${COMMIT_MSG} (-${DELETED} deleted)"
    fi
fi

echo -e "\n${BLUE}📦 Staging all changes...${NC}"
git add -A

echo -e "${BLUE}💾 Committing with message:${NC} ${COMMIT_MSG}"
git commit -m "$COMMIT_MSG"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Commit failed.${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Pushing to GitHub...${NC}"
git push origin main

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Successfully synced to GitHub!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    echo -e "${RED}❌ Push failed. Check your internet connection or credentials.${NC}"
    exit 1
fi

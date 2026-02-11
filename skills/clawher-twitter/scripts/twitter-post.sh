#!/bin/bash
# ClawHer Twitter - Post to Twitter/X via Bird CLI
#
# Usage: ./twitter-post.sh "<tweet_text>" [image_url]
#
# Environment: AUTH_TOKEN, CT0

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ -z "${AUTH_TOKEN:-}" ] || [ -z "${CT0:-}" ]; then
    log_error "AUTH_TOKEN and CT0 are required"
    echo "Get from: Chrome DevTools > Application > Cookies > twitter.com"
    exit 1
fi

# Check bird CLI
if ! command -v bird &> /dev/null; then
    if command -v bunx &> /dev/null; then
        BIRD="bunx @steipete/bird"
    elif command -v npx &> /dev/null; then
        BIRD="npx @steipete/bird"
    else
        log_error "Bird CLI not found. Install: npm install -g @steipete/bird"
        exit 1
    fi
else
    BIRD="bird"
fi

TWEET_TEXT="${1:-}"
IMAGE_URL="${2:-}"

if [ -z "$TWEET_TEXT" ]; then
    echo "Usage: $0 <tweet_text> [image_url]"
    exit 1
fi

AUTH_ARGS="--auth-token $AUTH_TOKEN --ct0 $CT0"
MEDIA_ARG=""

# Download image if URL provided
if [ -n "$IMAGE_URL" ]; then
    TMP_IMAGE="/tmp/clawher_tweet_$$.jpg"
    log_info "Downloading image..."
    curl -sL -o "$TMP_IMAGE" "$IMAGE_URL"

    FILE_SIZE=$(wc -c < "$TMP_IMAGE" | tr -d ' ')
    if [ "$FILE_SIZE" -lt 100 ]; then
        log_error "Image download failed"
        rm -f "$TMP_IMAGE"
        exit 1
    fi

    MEDIA_ARG="--media $TMP_IMAGE"
    log_info "Image ready (${FILE_SIZE} bytes)"
fi

# Post tweet
log_info "Posting tweet..."
RESULT=$($BIRD tweet "$TWEET_TEXT" $MEDIA_ARG $AUTH_ARGS --plain 2>&1)

# Clean up
if [ -n "${TMP_IMAGE:-}" ]; then
    rm -f "$TMP_IMAGE"
fi

echo "$RESULT"
log_info "Done!"

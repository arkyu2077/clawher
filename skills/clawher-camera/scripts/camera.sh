#!/bin/bash
# ClawHer Camera - Generate and send AI photos
#
# Usage: ./camera.sh "<prompt>" "<channel>" [image_size] [caption]
#
# Environment: FAL_KEY, OPENCLAW_GATEWAY_TOKEN

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ -z "${FAL_KEY:-}" ]; then
    log_error "FAL_KEY not set. Get from: https://fal.ai/dashboard/keys"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    log_error "jq is required: brew install jq"
    exit 1
fi

PROMPT="${1:-}"
CHANNEL="${2:-}"
IMAGE_SIZE="${3:-auto}"
CAPTION="${4:-}"

if [ -z "$PROMPT" ] || [ -z "$CHANNEL" ]; then
    echo "Usage: $0 <prompt> <channel> [image_size] [caption]"
    echo "Sizes: square_hd, portrait_16_9, landscape_16_9, portrait_4_3, landscape_4_3, auto"
    exit 1
fi

# Auto-detect image size from prompt keywords
if [ "$IMAGE_SIZE" == "auto" ]; then
    if echo "$PROMPT" | grep -qiE "landscape|scenery|view|panorama|horizon|sunset|sunrise"; then
        IMAGE_SIZE="landscape_16_9"
    elif echo "$PROMPT" | grep -qiE "portrait|standing|full-body|outfit|person|tall"; then
        IMAGE_SIZE="portrait_16_9"
    else
        IMAGE_SIZE="square_hd"
    fi
fi

log_info "Size: $IMAGE_SIZE"
log_info "Generating photo..."

JSON_PAYLOAD=$(jq -n \
    --arg prompt "$PROMPT" \
    --arg image_size "$IMAGE_SIZE" \
    '{prompt: $prompt, image_size: $image_size, num_images: 1}')

RESPONSE=$(curl -s -X POST "https://fal.run/fal-ai/flux/schnell" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

IMAGE_URL=$(echo "$RESPONSE" | jq -r '.images[0].url')

if [ "$IMAGE_URL" == "null" ] || [ -z "$IMAGE_URL" ]; then
    log_error "Failed to generate photo"
    echo "Response: $RESPONSE"
    exit 1
fi

log_info "Photo generated: $IMAGE_URL"

# Send via OpenClaw
SEND_CAPTION="${CAPTION:-$PROMPT}"
openclaw message send \
    --action send \
    --channel "$CHANNEL" \
    --message "$SEND_CAPTION" \
    --media "$IMAGE_URL"

log_info "Sent to $CHANNEL"

# JSON output
jq -n --arg url "$IMAGE_URL" --arg channel "$CHANNEL" --arg size "$IMAGE_SIZE" \
    '{success: true, image_url: $url, channel: $channel, image_size: $size}'

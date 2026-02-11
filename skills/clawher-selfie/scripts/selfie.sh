#!/bin/bash
# ClawHer Selfie - Generate and send AI girlfriend selfies
#
# Usage: ./selfie.sh "<user_context>" "<channel>" [mode] [caption]
#
# Environment: FAL_KEY, OPENCLAW_GATEWAY_TOKEN

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

REFERENCE_IMAGE="https://cdn.jsdelivr.net/gh/yuxh1996/clawher@main/assets/clawher.png"

USER_CONTEXT="${1:-}"
CHANNEL="${2:-}"
MODE="${3:-auto}"
CAPTION="${4:-}"

if [ -z "$USER_CONTEXT" ] || [ -z "$CHANNEL" ]; then
    echo "Usage: $0 <user_context> <channel> [mode] [caption]"
    echo "Modes: mirror, direct, auto (default)"
    exit 1
fi

# Auto-detect mode
if [ "$MODE" == "auto" ]; then
    if echo "$USER_CONTEXT" | grep -qiE "outfit|wearing|clothes|dress|suit|fashion|full-body|mirror"; then
        MODE="mirror"
    elif echo "$USER_CONTEXT" | grep -qiE "cafe|restaurant|beach|park|city|close-up|portrait|face|eyes|smile"; then
        MODE="direct"
    else
        MODE="mirror"
    fi
fi

# Build prompt
if [ "$MODE" == "direct" ]; then
    EDIT_PROMPT="a close-up selfie taken by herself at $USER_CONTEXT, direct eye contact with the camera, looking straight into the lens, eyes centered and clearly visible, not a mirror selfie, phone held at arm's length, face fully visible"
else
    EDIT_PROMPT="make a pic of this person, but $USER_CONTEXT. the person is taking a mirror selfie"
fi

log_info "Mode: $MODE"
log_info "Generating selfie..."

JSON_PAYLOAD=$(jq -n \
    --arg image_url "$REFERENCE_IMAGE" \
    --arg prompt "$EDIT_PROMPT" \
    '{image_url: $image_url, prompt: $prompt, num_images: 1, output_format: "jpeg"}')

RESPONSE=$(curl -s -X POST "https://fal.run/xai/grok-imagine-image/edit" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

IMAGE_URL=$(echo "$RESPONSE" | jq -r '.images[0].url')

if [ "$IMAGE_URL" == "null" ] || [ -z "$IMAGE_URL" ]; then
    log_error "Failed to generate selfie"
    echo "Response: $RESPONSE"
    exit 1
fi

log_info "Selfie generated: $IMAGE_URL"

# Send via OpenClaw
SEND_CAPTION="${CAPTION:-$USER_CONTEXT}"
openclaw message send \
    --action send \
    --channel "$CHANNEL" \
    --message "$SEND_CAPTION" \
    --media "$IMAGE_URL"

log_info "Sent to $CHANNEL"

# JSON output
jq -n --arg url "$IMAGE_URL" --arg channel "$CHANNEL" --arg mode "$MODE" \
    '{success: true, image_url: $url, channel: $channel, mode: $mode}'

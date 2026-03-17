#!/bin/bash
# ClawHer Video - Generate and send AI girlfriend videos
#
# Usage: ./video.sh <mode> "<input1>" "<input2>" "<channel>" [caption]
#
# Modes:
#   talking   <image_url> <audio_url> <channel> [caption]  - Talking head video
#   text      <prompt>    ""          <channel> [caption]  - Text-to-video
#   animate   <image_url> <prompt>    <channel> [caption]  - Image-to-video
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

MODE="${1:-}"
INPUT1="${2:-}"
INPUT2="${3:-}"
CHANNEL="${4:-}"
CAPTION="${5:-}"

if [ -z "$MODE" ] || [ -z "$INPUT1" ] || [ -z "$CHANNEL" ]; then
    echo "Usage: $0 <mode> <input1> <input2> <channel> [caption]"
    echo ""
    echo "Modes:"
    echo "  talking  <image_url> <audio_url> <channel>  - Talking head video (OmniHuman)"
    echo "  text     <prompt>    \"\"          <channel>  - Text-to-video (Wan 2.5)"
    echo "  animate  <image_url> <prompt>    <channel>  - Image-to-video (Kling v3)"
    exit 1
fi

case "$MODE" in
    talking)
        IMAGE_URL="$INPUT1"
        AUDIO_URL="$INPUT2"
        if [ -z "$AUDIO_URL" ]; then
            log_error "Talking mode requires both image_url and audio_url"
            exit 1
        fi

        MODEL="fal-ai/bytedance/omnihuman"
        log_info "Generating talking video (OmniHuman)..."

        JSON_PAYLOAD=$(jq -n \
            --arg image_url "$IMAGE_URL" \
            --arg audio_url "$AUDIO_URL" \
            '{image_url: $image_url, audio_url: $audio_url}')
        ;;

    text)
        PROMPT="$INPUT1"
        MODEL="fal-ai/wan-2-5"
        log_info "Generating video from text (Wan 2.5)..."

        JSON_PAYLOAD=$(jq -n \
            --arg prompt "$PROMPT" \
            '{prompt: $prompt}')
        ;;

    animate)
        IMAGE_URL="$INPUT1"
        PROMPT="${INPUT2:-The person smiles and looks at the camera}"
        MODEL="fal-ai/kling-video/v3/standard/image-to-video"
        log_info "Animating image (Kling v3)..."

        JSON_PAYLOAD=$(jq -n \
            --arg image_url "$IMAGE_URL" \
            --arg prompt "$PROMPT" \
            '{image_url: $image_url, prompt: $prompt}')
        ;;

    *)
        log_error "Unknown mode: $MODE (use: talking, text, animate)"
        exit 1
        ;;
esac

log_info "Model: $MODEL"

RESPONSE=$(curl -s -X POST "https://fal.run/$MODEL" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

# Extract video URL (try common response formats)
VIDEO_URL=$(echo "$RESPONSE" | jq -r '.video.url // .video_url // .output.url // empty')

if [ -z "$VIDEO_URL" ] || [ "$VIDEO_URL" == "null" ]; then
    log_error "Failed to generate video"
    echo "Response: $RESPONSE"
    exit 1
fi

log_info "Video generated: $VIDEO_URL"

# Send via OpenClaw
SEND_CAPTION="${CAPTION:-Video message}"
openclaw message send \
    --action send \
    --channel "$CHANNEL" \
    --message "$SEND_CAPTION" \
    --media "$VIDEO_URL"

log_info "Sent to $CHANNEL"

# JSON output
jq -n --arg url "$VIDEO_URL" --arg channel "$CHANNEL" --arg mode "$MODE" --arg model "$MODEL" \
    '{success: true, video_url: $url, channel: $channel, mode: $mode, model: $model}'

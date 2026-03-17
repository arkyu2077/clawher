#!/bin/bash
# ClawHer Voice - Generate and send AI girlfriend voice messages
#
# Usage: ./voice.sh "<text_to_speak>" "<channel>" [caption]
#
# Environment: FAL_KEY, OPENCLAW_GATEWAY_TOKEN
# Optional: VOICE_REF_URL, VOICE_REF_TEXT (for voice cloning via F5 TTS)

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

TEXT_TO_SPEAK="${1:-}"
CHANNEL="${2:-}"
CAPTION="${3:-}"

if [ -z "$TEXT_TO_SPEAK" ] || [ -z "$CHANNEL" ]; then
    echo "Usage: $0 <text_to_speak> <channel> [caption]"
    exit 1
fi

# Choose model based on whether voice cloning is configured
if [ -n "${VOICE_REF_URL:-}" ] && [ -n "${VOICE_REF_TEXT:-}" ]; then
    # F5 TTS - voice cloning mode
    MODEL="fal-ai/f5-tts"
    log_info "Using F5 TTS (voice cloning)..."

    JSON_PAYLOAD=$(jq -n \
        --arg gen_text "$TEXT_TO_SPEAK" \
        --arg ref_audio_url "$VOICE_REF_URL" \
        --arg ref_text "$VOICE_REF_TEXT" \
        '{gen_text: $gen_text, ref_audio_url: $ref_audio_url, ref_text: $ref_text}')
else
    # Dia TTS - default mode
    MODEL="fal-ai/dia-tts"
    log_info "Using Dia TTS..."

    # Wrap in [S1] tag for single speaker
    TAGGED_TEXT="[S1] $TEXT_TO_SPEAK"
    JSON_PAYLOAD=$(jq -n \
        --arg text "$TAGGED_TEXT" \
        '{text: $text}')
fi

log_info "Generating voice message..."

RESPONSE=$(curl -s -X POST "https://fal.run/$MODEL" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

# Extract audio URL (try common response formats)
AUDIO_URL=$(echo "$RESPONSE" | jq -r '.audio.url // .audio_url // .output.url // empty')

if [ -z "$AUDIO_URL" ] || [ "$AUDIO_URL" == "null" ]; then
    log_error "Failed to generate voice message"
    echo "Response: $RESPONSE"
    exit 1
fi

log_info "Voice generated: $AUDIO_URL"

# Send via OpenClaw
SEND_CAPTION="${CAPTION:-Voice message}"
openclaw message send \
    --action send \
    --channel "$CHANNEL" \
    --message "$SEND_CAPTION" \
    --media "$AUDIO_URL"

log_info "Sent to $CHANNEL"

# JSON output
jq -n --arg url "$AUDIO_URL" --arg channel "$CHANNEL" --arg model "$MODEL" \
    '{success: true, audio_url: $url, channel: $channel, model: $model}'

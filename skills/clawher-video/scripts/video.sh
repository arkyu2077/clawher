#!/bin/bash
# ClawHer Video - Generate and send AI girlfriend videos
#
# Usage: ./video.sh <mode> "<input1>" "<input2>" "<channel>" [caption]
#
# Modes:
#   talking   <image_url> <audio_url> <channel> [caption]
#   text      <prompt>    ""          <channel> [caption]
#   animate   <image_url> <prompt>    <channel> [caption]
#
# Environment:
#   FAL_KEY                         Required
#   CLAWHER_VIDEO_TIMEOUT          Optional request timeout seconds (default: 300)
#   CLAWHER_VIDEO_TALKING_MODEL    Default: fal-ai/bytedance/omnihuman/v1.5
#   CLAWHER_VIDEO_TEXT_MODEL       Default: fal-ai/veo3/fast
#   CLAWHER_VIDEO_ANIMATE_MODEL    Default: fal-ai/kling-video/v3/standard/image-to-video

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../../common-media.sh
source "$SCRIPT_DIR/../../common-media.sh"

require_bin jq "brew install jq"
require_bin curl "brew install curl"

MODE="${1:-}"
INPUT1="${2:-}"
INPUT2="${3:-}"
CHANNEL="${4:-}"
CAPTION="${5:-}"

if [ -z "$MODE" ] || [ -z "$INPUT1" ] || [ -z "$CHANNEL" ]; then
  echo "Usage: $0 <mode> <input1> <input2> <channel> [caption]"
  exit 1
fi

if [ -z "${FAL_KEY:-}" ]; then
  log_error "FAL_KEY not set. Get from: https://fal.ai/dashboard/keys"
  exit 1
fi

TIMEOUT="${CLAWHER_VIDEO_TIMEOUT:-300}"
TALKING_MODEL="${CLAWHER_VIDEO_TALKING_MODEL:-fal-ai/bytedance/omnihuman/v1.5}"
TEXT_MODEL="${CLAWHER_VIDEO_TEXT_MODEL:-fal-ai/veo3/fast}"
ANIMATE_MODEL="${CLAWHER_VIDEO_ANIMATE_MODEL:-fal-ai/kling-video/v3/standard/image-to-video}"
MEDIA_ROOT="$(media_dir)"
RUN_DIR="$MEDIA_ROOT/video-$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$RUN_DIR"
LAST_RESPONSE="$RUN_DIR/last-response.json"
LOCAL_VIDEO="$RUN_DIR/video.mp4"

case "$MODE" in
  talking)
    IMAGE_URL="$INPUT1"
    AUDIO_URL="$INPUT2"
    if [ -z "$AUDIO_URL" ]; then
      log_error "Talking mode requires both image_url and audio_url"
      exit 1
    fi
    MODEL="$TALKING_MODEL"
    JSON_PAYLOAD=$(jq -n \
      --arg image_url "$IMAGE_URL" \
      --arg audio_url "$AUDIO_URL" \
      '{image_url: $image_url, audio_url: $audio_url}')
    ;;
  text)
    PROMPT="$INPUT1"
    MODEL="$TEXT_MODEL"
    JSON_PAYLOAD=$(jq -n --arg prompt "$PROMPT" '{prompt: $prompt}')
    ;;
  animate)
    IMAGE_URL="$INPUT1"
    PROMPT="${INPUT2:-The person smiles and looks at the camera}"
    MODEL="$ANIMATE_MODEL"
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

log_info "Generating video with model: $MODEL"
RESPONSE=$(http_post_json "https://fal.run/$MODEL" "$JSON_PAYLOAD" "$TIMEOUT")
printf '%s' "$RESPONSE" > "$LAST_RESPONSE"

VIDEO_URL=$(json_get_first "$RESPONSE" '.video.url' '.video_url' '.output.url' '.data.video_url')
if [ -z "$VIDEO_URL" ] || [ "$VIDEO_URL" = "null" ]; then
  log_error "Failed to generate video"
  echo "Response: $RESPONSE" >&2
  exit 1
fi

log_info "Downloading generated video"
download_media "$VIDEO_URL" "$LOCAL_VIDEO"
assert_nonempty_file "$LOCAL_VIDEO"

SEND_CAPTION="${CAPTION:-Video message}"
send_local_media "$CHANNEL" "$LOCAL_VIDEO" "$SEND_CAPTION" media

jq -n \
  --arg model "$MODEL" \
  --arg mode "$MODE" \
  --arg video_url "$VIDEO_URL" \
  --arg local_path "$LOCAL_VIDEO" \
  --arg channel "$CHANNEL" \
  '{success: true, model: $model, mode: $mode, video_url: $video_url, local_path: $local_path, channel: $channel}'

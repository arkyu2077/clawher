#!/bin/bash
# ClawHer Voice - Generate and send AI girlfriend voice messages
#
# Usage: ./voice.sh "<text_to_speak>" "<channel>" [caption]
#
# Environment:
#   FAL_KEY                  Required for fal.ai providers
#   VOICE_REF_URL            Optional for voice cloning
#   VOICE_REF_TEXT           Optional transcript for VOICE_REF_URL
#   CLAWHER_TTS_MODELS       Optional comma-separated model fallback order
#                            Default: fal-ai/dia-tts,fal-ai/f5-tts
#   CLAWHER_TTS_TIMEOUT      Optional request timeout seconds (default: 180)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../../common-media.sh
source "$SCRIPT_DIR/../../common-media.sh"

require_bin jq "brew install jq"
require_bin curl "brew install curl"

TEXT_TO_SPEAK="${1:-}"
CHANNEL="${2:-}"
CAPTION="${3:-}"

if [ -z "$TEXT_TO_SPEAK" ] || [ -z "$CHANNEL" ]; then
  echo "Usage: $0 <text_to_speak> <channel> [caption]"
  exit 1
fi

if [ -z "${FAL_KEY:-}" ]; then
  log_error "FAL_KEY not set. Get from: https://fal.ai/dashboard/keys"
  exit 1
fi

TIMEOUT="${CLAWHER_TTS_TIMEOUT:-180}"
MODELS_CSV="${CLAWHER_TTS_MODELS:-fal-ai/dia-tts,fal-ai/f5-tts}"
MEDIA_ROOT="$(media_dir)"
RUN_DIR="$MEDIA_ROOT/voice-$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$RUN_DIR"
LAST_RESPONSE="$RUN_DIR/last-response.json"
LOCAL_AUDIO="$RUN_DIR/voice.mp3"

IFS=',' read -r -a MODELS <<< "$MODELS_CSV"
SUCCESS_MODEL=""
AUDIO_URL=""

for MODEL in "${MODELS[@]}"; do
  MODEL="$(echo "$MODEL" | xargs)"
  [ -z "$MODEL" ] && continue

  case "$MODEL" in
    fal-ai/f5-tts)
      if [ -z "${VOICE_REF_URL:-}" ] || [ -z "${VOICE_REF_TEXT:-}" ]; then
        log_warn "Skipping $MODEL: VOICE_REF_URL / VOICE_REF_TEXT not configured"
        continue
      fi
      JSON_PAYLOAD=$(jq -n \
        --arg gen_text "$TEXT_TO_SPEAK" \
        --arg ref_audio_url "$VOICE_REF_URL" \
        --arg ref_text "$VOICE_REF_TEXT" \
        '{gen_text: $gen_text, ref_audio_url: $ref_audio_url, ref_text: $ref_text}')
      ;;
    fal-ai/dia-tts)
      TAGGED_TEXT="[S1] $TEXT_TO_SPEAK"
      JSON_PAYLOAD=$(jq -n --arg text "$TAGGED_TEXT" '{text: $text}')
      ;;
    *)
      log_warn "Skipping unsupported TTS model mapping: $MODEL"
      continue
      ;;
  esac

  log_info "Trying TTS model: $MODEL"
  if RESPONSE=$(http_post_json "https://fal.run/$MODEL" "$JSON_PAYLOAD" "$TIMEOUT" 2>"$RUN_DIR/curl.stderr"); then
    printf '%s' "$RESPONSE" > "$LAST_RESPONSE"
    AUDIO_URL=$(json_get_first "$RESPONSE" '.audio.url' '.audio_url' '.output.url')
    if [ -n "$AUDIO_URL" ] && [ "$AUDIO_URL" != "null" ]; then
      SUCCESS_MODEL="$MODEL"
      break
    fi
    log_warn "Model $MODEL returned no audio URL"
  else
    log_warn "Model $MODEL request failed"
  fi

done

if [ -z "$AUDIO_URL" ]; then
  log_error "All TTS models failed"
  [ -f "$LAST_RESPONSE" ] && echo "Last response: $(cat "$LAST_RESPONSE")" >&2
  exit 1
fi

log_info "Downloading audio from $SUCCESS_MODEL"
download_media "$AUDIO_URL" "$LOCAL_AUDIO"
assert_nonempty_file "$LOCAL_AUDIO"

SEND_CAPTION="${CAPTION:-Voice message}"
send_local_media "$CHANNEL" "$LOCAL_AUDIO" "$SEND_CAPTION" voice

jq -n \
  --arg model "$SUCCESS_MODEL" \
  --arg audio_url "$AUDIO_URL" \
  --arg local_path "$LOCAL_AUDIO" \
  --arg channel "$CHANNEL" \
  '{success: true, model: $model, audio_url: $audio_url, local_path: $local_path, channel: $channel}'

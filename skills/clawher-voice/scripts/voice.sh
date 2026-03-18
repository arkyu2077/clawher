#!/bin/bash
# ClawHer Voice - Generate and send AI girlfriend voice messages
#
# Usage: ./voice.sh "<text_to_speak>" "<channel>" [caption]
#
# Environment:
#   FAL_KEY                  Required for fal.ai providers
#   VOICE_REF_URL            Optional for voice cloning
#   VOICE_REF_TEXT           Optional transcript for VOICE_REF_URL
#   CLAWHER_TTS_MODELS       Optional comma-separated provider fallback order
#                            Default: fal-ai/dia-tts,fal-ai/f5-tts,macos-say
#   CLAWHER_TTS_TIMEOUT      Optional request timeout seconds (default: 180)
#   CLAWHER_SAY_VOICE        Optional macOS say voice (default: Tingting)
#   CLAWHER_SAY_RATE         Optional macOS say rate words/minute (default: 190)
#   CLAWHER_SAY_FALLBACK     Set to 0 to disable macOS local fallback
#
# Providers:
#   fal-ai/dia-tts
#   fal-ai/f5-tts
#   macos-say
#
# Notes:
#   - Remote providers are tried first.
#   - macos-say is a local fallback for reliability on macOS and does not require Python.
#   - Every successful provider is normalized to a local media file before upload.

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

TIMEOUT="${CLAWHER_TTS_TIMEOUT:-180}"
MODELS_CSV="${CLAWHER_TTS_MODELS:-fal-ai/dia-tts,fal-ai/f5-tts,macos-say}"
SAY_VOICE="${CLAWHER_SAY_VOICE:-Tingting}"
SAY_RATE="${CLAWHER_SAY_RATE:-190}"
SAY_FALLBACK="${CLAWHER_SAY_FALLBACK:-1}"

MEDIA_ROOT="$(media_dir)"
RUN_DIR="$MEDIA_ROOT/voice-$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$RUN_DIR"
LAST_RESPONSE="$RUN_DIR/last-response.json"
LOCAL_AUDIO="$RUN_DIR/voice.m4a"
TEMP_AIFF="$RUN_DIR/voice.aiff"

IFS=',' read -r -a MODELS <<< "$MODELS_CSV"
SUCCESS_MODEL=""
AUDIO_URL=""

for MODEL in "${MODELS[@]}"; do
  MODEL="$(echo "$MODEL" | xargs)"
  [ -z "$MODEL" ] && continue

  case "$MODEL" in
    fal-ai/f5-tts)
      if [ -z "${FAL_KEY:-}" ]; then
        log_warn "Skipping $MODEL: FAL_KEY not configured"
        continue
      fi
      if [ -z "${VOICE_REF_URL:-}" ] || [ -z "${VOICE_REF_TEXT:-}" ]; then
        log_warn "Skipping $MODEL: VOICE_REF_URL / VOICE_REF_TEXT not configured"
        continue
      fi
      JSON_PAYLOAD=$(jq -n \
        --arg gen_text "$TEXT_TO_SPEAK" \
        --arg ref_audio_url "$VOICE_REF_URL" \
        --arg ref_text "$VOICE_REF_TEXT" \
        '{gen_text: $gen_text, ref_audio_url: $ref_audio_url, ref_text: $ref_text}')
      log_info "Trying TTS model: $MODEL"
      if RESPONSE=$(http_post_json "https://fal.run/$MODEL" "$JSON_PAYLOAD" "$TIMEOUT" 2>"$RUN_DIR/curl.stderr"); then
        printf '%s' "$RESPONSE" > "$LAST_RESPONSE"
        AUDIO_URL=$(json_get_first "$RESPONSE" '.audio.url' '.audio_url' '.output.url')
        if [ -n "$AUDIO_URL" ] && [ "$AUDIO_URL" != "null" ]; then
          SUCCESS_MODEL="$MODEL"
          break
        fi
      fi
      ;;
    fal-ai/dia-tts)
      if [ -z "${FAL_KEY:-}" ]; then
        log_warn "Skipping $MODEL: FAL_KEY not configured"
        continue
      fi
      TAGGED_TEXT="[S1] $TEXT_TO_SPEAK"
      JSON_PAYLOAD=$(jq -n --arg text "$TAGGED_TEXT" '{text: $text}')
      log_info "Trying TTS model: $MODEL"
      if RESPONSE=$(http_post_json "https://fal.run/$MODEL" "$JSON_PAYLOAD" "$TIMEOUT" 2>"$RUN_DIR/curl.stderr"); then
        printf '%s' "$RESPONSE" > "$LAST_RESPONSE"
        AUDIO_URL=$(json_get_first "$RESPONSE" '.audio.url' '.audio_url' '.output.url')
        if [ -n "$AUDIO_URL" ] && [ "$AUDIO_URL" != "null" ]; then
          SUCCESS_MODEL="$MODEL"
          break
        fi
      fi
      ;;
    macos-say)
      if [ "$SAY_FALLBACK" = "0" ]; then
        log_warn "Skipping macos-say: disabled by CLAWHER_SAY_FALLBACK=0"
        continue
      fi
      if ! command -v say >/dev/null 2>&1; then
        log_warn "Skipping macos-say: say command not available"
        continue
      fi
      if ! command -v afconvert >/dev/null 2>&1; then
        log_warn "Skipping macos-say: afconvert command not available"
        continue
      fi
      log_info "Trying local fallback: macos-say ($SAY_VOICE)"
      say -v "$SAY_VOICE" -r "$SAY_RATE" -o "$TEMP_AIFF" "$TEXT_TO_SPEAK"
      afconvert -f m4af -d aac "$TEMP_AIFF" "$LOCAL_AUDIO" >/dev/null 2>&1
      assert_nonempty_file "$LOCAL_AUDIO"
      SUCCESS_MODEL="macos-say"
      break
      ;;
    *)
      log_warn "Skipping unsupported TTS provider: $MODEL"
      ;;
  esac
done

if [ -z "$SUCCESS_MODEL" ]; then
  log_error "All TTS providers failed"
  [ -f "$LAST_RESPONSE" ] && echo "Last response: $(cat "$LAST_RESPONSE")" >&2
  exit 1
fi

if [ "$SUCCESS_MODEL" != "macos-say" ]; then
  log_info "Downloading audio from $SUCCESS_MODEL"
  download_media "$AUDIO_URL" "$LOCAL_AUDIO"
  assert_nonempty_file "$LOCAL_AUDIO"
fi

SEND_CAPTION="${CAPTION:-Voice message}"
send_local_media "$CHANNEL" "$LOCAL_AUDIO" "$SEND_CAPTION" voice

jq -n \
  --arg model "$SUCCESS_MODEL" \
  --arg audio_url "$AUDIO_URL" \
  --arg local_path "$LOCAL_AUDIO" \
  --arg channel "$CHANNEL" \
  '{success: true, model: $model, audio_url: $audio_url, local_path: $local_path, channel: $channel}'

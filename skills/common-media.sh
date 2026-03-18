#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

require_bin() {
  local bin="$1"
  local hint="${2:-}"
  if ! command -v "$bin" >/dev/null 2>&1; then
    log_error "$bin is required${hint:+: $hint}"
    exit 1
  fi
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

workspace_root() {
  local root
  root="$(cd "$(repo_root)/.." && pwd)"
  echo "$root"
}

media_dir() {
  local root
  if [ -n "${CLAWHER_MEDIA_ROOT:-}" ]; then
    root="$CLAWHER_MEDIA_ROOT"
  else
    root="$(workspace_root)/tmp/clawher-media"
  fi
  mkdir -p "$root"
  echo "$root"
}

json_get_first() {
  local json="$1"
  shift
  printf '%s' "$json" | jq -r "$* // empty"
}

http_post_json() {
  local url="$1"
  local payload="$2"
  local timeout="${3:-180}"
  curl -sS --fail-with-body --max-time "$timeout" \
    -X POST "$url" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload"
}

download_media() {
  local url="$1"
  local output="$2"
  curl -sS -L --fail --max-time 120 "$url" -o "$output"
}

assert_nonempty_file() {
  local path="$1"
  if [ ! -f "$path" ] || [ ! -s "$path" ]; then
    log_error "Expected non-empty file: $path"
    exit 1
  fi
}

parse_channel_target() {
  local raw="$1"
  if [[ "$raw" == *:* ]]; then
    local channel="${raw%%:*}"
    local target="${raw#*:}"
    echo "$channel"$'\n'"$target"
  else
    log_error "Channel target must look like <channel>:<target>, e.g. telegram:691799783"
    exit 1
  fi
}

telegram_bot_token() {
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
    echo "$TELEGRAM_BOT_TOKEN"
    return 0
  fi
  local cfg="$HOME/.openclaw/openclaw.json"
  if [ -f "$cfg" ]; then
    jq -r '.channels.telegram.botToken // empty' "$cfg"
    return 0
  fi
  return 1
}

telegram_send_local_media() {
  local chat_id="$1"
  local path="$2"
  local caption="$3"
  local mode="${4:-media}"
  local token method field mime

  token="$(telegram_bot_token)"
  if [ -z "$token" ]; then
    log_error "Telegram fallback requires TELEGRAM_BOT_TOKEN or ~/.openclaw/openclaw.json"
    exit 1
  fi

  mime="$(file --mime-type -b "$path")"
  case "$mode:$mime" in
    voice:*)
      method="sendVoice"
      field="voice"
      ;;
    *:video/*)
      method="sendVideo"
      field="video"
      ;;
    *:image/*)
      method="sendPhoto"
      field="photo"
      ;;
    *)
      method="sendDocument"
      field="document"
      ;;
  esac

  curl -sS --fail-with-body -X POST "https://api.telegram.org/bot${token}/${method}" \
    -F "chat_id=${chat_id}" \
    -F "${field}=@${path}" \
    -F "caption=${caption}" >/dev/null
}

send_local_media() {
  local destination="$1"
  local path="$2"
  local caption="$3"
  local mode="${4:-media}"
  local parsed channel target

  assert_nonempty_file "$path"

  parsed="$(parse_channel_target "$destination")"
  channel="$(printf '%s' "$parsed" | sed -n '1p')"
  target="$(printf '%s' "$parsed" | sed -n '2p')"

  local cmd=(openclaw message send --channel "$channel" --target "$target" --media "$path")
  if [ -n "$caption" ]; then
    cmd+=(--message "$caption")
  fi

  if "${cmd[@]}" >/dev/null 2>"$(media_dir)/last-send-error.log"; then
    return 0
  fi

  if [ "$channel" = "telegram" ]; then
    log_warn "OpenClaw local-media send failed; falling back to Telegram Bot API"
    telegram_send_local_media "$target" "$path" "$caption" "$mode"
    return 0
  fi

  log_error "Local media send failed and no fallback is configured for channel: $channel"
  cat "$(media_dir)/last-send-error.log" >&2 || true
  exit 1
}

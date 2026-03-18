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

media_dir() {
  local root
  root="$(repo_root)"
  mkdir -p "$root/.clawher-media"
  echo "$root/.clawher-media"
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

send_local_media() {
  local channel="$1"
  local path="$2"
  local caption="$3"
  local mode="${4:-media}"

  assert_nonempty_file "$path"

  local cmd=(openclaw message send --action send --channel "$channel" --media "$path")
  if [ -n "$caption" ]; then
    cmd+=(--message "$caption")
  fi
  if [ "$mode" = "voice" ]; then
    cmd+=(--as-voice)
  fi
  "${cmd[@]}"
}

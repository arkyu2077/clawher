#!/bin/bash
# ClawHer Twitter - Post images to Twitter/X using cookie auth
#
# Usage: ./twitter-post.sh "<image_url>" "<tweet_text>"
#
# Environment: TWITTER_AUTH_TOKEN, TWITTER_CT0

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

BEARER="AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA"

if [ -z "${TWITTER_AUTH_TOKEN:-}" ]; then
    log_error "TWITTER_AUTH_TOKEN not set"
    echo "Get from: Chrome DevTools > Application > Cookies > twitter.com > auth_token"
    exit 1
fi

if [ -z "${TWITTER_CT0:-}" ]; then
    log_error "TWITTER_CT0 not set"
    echo "Get from: Chrome DevTools > Application > Cookies > twitter.com > ct0"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    log_error "jq is required: brew install jq"
    exit 1
fi

IMAGE_URL="${1:-}"
TWEET_TEXT="${2:-}"

if [ -z "$IMAGE_URL" ] || [ -z "$TWEET_TEXT" ]; then
    echo "Usage: $0 <image_url> <tweet_text>"
    exit 1
fi

log_info "Posting to Twitter..."

# Download image
TMP_IMAGE="/tmp/clawher_tweet_$$.jpg"
curl -sL -o "$TMP_IMAGE" "$IMAGE_URL"

FILE_SIZE=$(wc -c < "$TMP_IMAGE" | tr -d ' ')
if [ "$FILE_SIZE" -lt 100 ]; then
    log_error "Download failed"
    rm -f "$TMP_IMAGE"
    exit 1
fi

# Upload media
log_info "Uploading media..."
MEDIA_RESPONSE=$(curl -s -X POST "https://upload.twitter.com/1.1/media/upload.json" \
    -H "Authorization: Bearer $BEARER" \
    -H "Cookie: auth_token=$TWITTER_AUTH_TOKEN; ct0=$TWITTER_CT0" \
    -H "x-csrf-token: $TWITTER_CT0" \
    -F "media=@$TMP_IMAGE")

rm -f "$TMP_IMAGE"

MEDIA_ID=$(echo "$MEDIA_RESPONSE" | jq -r '.media_id_string // empty')
if [ -z "$MEDIA_ID" ]; then
    log_error "Media upload failed"
    echo "Response: $MEDIA_RESPONSE"
    exit 1
fi

log_info "Media uploaded: $MEDIA_ID"

# Create tweet
log_info "Creating tweet..."
TWEET_PAYLOAD=$(jq -n \
    --arg text "$TWEET_TEXT" \
    --arg media_id "$MEDIA_ID" \
    '{
        "variables": {
            "tweet_text": $text,
            "dark_request": false,
            "media": {
                "media_entities": [{"media_id": $media_id, "tagged_users": []}],
                "possibly_sensitive": false
            },
            "semantic_annotation_ids": []
        },
        "features": {
            "communities_web_enable_tweet_community_results_fetch": true,
            "c9s_tweet_anatomy_moderator_badge_enabled": true,
            "tweetypie_unmention_optimization_enabled": true,
            "responsive_web_edit_tweet_api_enabled": true,
            "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true,
            "view_counts_everywhere_api_enabled": true,
            "longform_notetweets_consumption_enabled": true,
            "responsive_web_twitter_article_tweet_consumption_enabled": true,
            "tweet_awards_web_tipping_enabled": false,
            "creator_subscriptions_quote_tweet_preview_enabled": false,
            "longform_notetweets_rich_text_read_enabled": true,
            "longform_notetweets_inline_media_enabled": true,
            "responsive_web_graphql_exclude_directive_enabled": true,
            "verified_phone_label_enabled": false,
            "freedom_of_speech_not_reach_fetch_enabled": true,
            "standardized_nudges_misinfo": true,
            "responsive_web_graphql_timeline_navigation_enabled": true,
            "responsive_web_enhance_cards_enabled": false
        },
        "queryId": "mnCM2K0Bsc2Boir2NMxgPg"
    }')

TWEET_RESPONSE=$(curl -s -X POST "https://twitter.com/i/api/graphql/mnCM2K0Bsc2Boir2NMxgPg/CreateTweet" \
    -H "Authorization: Bearer $BEARER" \
    -H "Cookie: auth_token=$TWITTER_AUTH_TOKEN; ct0=$TWITTER_CT0" \
    -H "x-csrf-token: $TWITTER_CT0" \
    -H "Content-Type: application/json" \
    -d "$TWEET_PAYLOAD")

TWEET_ID=$(echo "$TWEET_RESPONSE" | jq -r '.data.create_tweet.tweet_results.result.rest_id // empty')

if [ -z "$TWEET_ID" ]; then
    ERROR=$(echo "$TWEET_RESPONSE" | jq -r '.errors[0].message // empty')
    if [ -n "$ERROR" ]; then
        log_error "Tweet failed: $ERROR"
    else
        log_error "Tweet failed"
        echo "Response: $TWEET_RESPONSE"
    fi
    exit 1
fi

SCREEN_NAME=$(echo "$TWEET_RESPONSE" | jq -r '.data.create_tweet.tweet_results.result.core.user_results.result.legacy.screen_name // "i"')
TWEET_URL="https://twitter.com/$SCREEN_NAME/status/$TWEET_ID"

log_info "Tweet posted: $TWEET_URL"

jq -n --arg url "$TWEET_URL" --arg id "$TWEET_ID" --arg text "$TWEET_TEXT" \
    '{success: true, tweet_url: $url, tweet_id: $id, text: $text}'

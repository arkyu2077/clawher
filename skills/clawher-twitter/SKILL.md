---
name: clawher-twitter
description: Post images and text to Twitter/X using cookie-based authentication via OpenClaw
allowed-tools: Bash(npm:*) Bash(npx:*) Bash(openclaw:*) Bash(curl:*) Read Write WebFetch
---

# ClawHer Twitter

Post images and text to the user's Twitter/X account. Works alongside `clawher-selfie` to share AI-generated selfies on social media.

## Required Environment Variables

```bash
TWITTER_AUTH_TOKEN=your_auth_token   # Twitter auth_token cookie
TWITTER_CT0=your_ct0_token           # Twitter ct0 cookie (CSRF token)
```

## When to Use

- User says "post this to Twitter", "tweet this", "share on Twitter"
- User says "post my selfie to Twitter", "put this on X"
- User asks to share a generated image on social media
- After generating a selfie, if user wants it posted publicly

## Workflow

1. **Get content**: Determine the image URL and tweet text
2. **Upload media**: Upload the image to Twitter via media/upload API
3. **Create tweet**: Post the tweet with the uploaded media
4. **Return result**: Share the tweet URL with the user

## Step-by-Step Instructions

### Step 1: Prepare Content

- **Image URL**: From clawher-selfie output or user-provided URL
- **Tweet text**: Compose or ask user

### Step 2: Post to Twitter

```bash
./scripts/twitter-post.sh "$IMAGE_URL" "$TWEET_TEXT"
```

## How Users Get Their Twitter Cookies

1. Open Twitter/X in Chrome and log in
2. Press F12 to open DevTools
3. Go to Application > Cookies > twitter.com
4. Copy `auth_token` and `ct0` values

## Error Handling

- **401 Unauthorized**: Cookies expired, user needs to re-extract from browser
- **403 Forbidden**: Account restricted or ct0 mismatch
- **Media upload failed**: Image too large (max 5MB) or wrong format
- **Rate limited**: ~300 tweets/3 hours, wait and retry

---
name: clawher-twitter
description: Post images and text to Twitter/X using Bird CLI via OpenClaw
allowed-tools: Bash(npm:*) Bash(npx:*) Bash(bunx:*) Bash(bird:*) Bash(openclaw:*) Bash(curl:*) Read Write WebFetch
---

# ClawHer Twitter

Post images, text, and replies to the user's Twitter/X account using [Bird CLI](https://github.com/steipete/bird). Works alongside `clawher-selfie` to share AI-generated selfies on social media.

## Required Environment Variables

```bash
AUTH_TOKEN=your_auth_token   # Twitter auth_token cookie
CT0=your_ct0_token           # Twitter ct0 cookie (CSRF token)
```

## When to Use

- User says "post this to Twitter", "tweet this", "share on Twitter/X"
- User says "post my selfie to Twitter", "put this on X"
- User says "reply to this tweet", "check my mentions"
- User asks to share a generated image on social media
- After generating a selfie, if user wants it posted publicly

## Commands

### Post a tweet with image

```bash
bird tweet "Just vibing ✨" --media "/tmp/selfie.jpg" --auth-token "$AUTH_TOKEN" --ct0 "$CT0"
```

### Post text-only tweet

```bash
bird tweet "Hello world" --auth-token "$AUTH_TOKEN" --ct0 "$CT0"
```

### Reply to a tweet

```bash
bird reply <tweet-id-or-url> "Nice!" --auth-token "$AUTH_TOKEN" --ct0 "$CT0"
```

### Read a tweet

```bash
bird read <tweet-id-or-url> --auth-token "$AUTH_TOKEN" --ct0 "$CT0"
```

### Check mentions

```bash
bird mentions --auth-token "$AUTH_TOKEN" --ct0 "$CT0"
```

### Search tweets

```bash
bird search "keyword" --auth-token "$AUTH_TOKEN" --ct0 "$CT0"
```

### Check who I am

```bash
bird whoami --auth-token "$AUTH_TOKEN" --ct0 "$CT0"
```

## Workflow for Posting Selfie to Twitter

1. **clawher-selfie** generates image → returns image URL
2. **Download image** to local temp file:
   ```bash
   curl -sL -o /tmp/clawher_selfie.jpg "$IMAGE_URL"
   ```
3. **Post with Bird**:
   ```bash
   bird tweet "$TWEET_TEXT" --media /tmp/clawher_selfie.jpg --auth-token "$AUTH_TOKEN" --ct0 "$CT0"
   ```
4. Clean up temp file

## Notes

- Bird uses Twitter's internal GraphQL endpoints, query IDs auto-refresh
- `--media` accepts local file paths (up to 4 images or 1 video)
- Add `--json` to any read command for structured output
- Add `--plain` for stable, parseable output without emoji/color

## How Users Get Their Twitter Cookies

1. Open Twitter/X in Chrome and log in
2. Press F12 to open DevTools
3. Go to Application > Cookies > twitter.com
4. Copy `auth_token` and `ct0` values

## Error Handling

- **Missing credentials**: Ensure AUTH_TOKEN and CT0 are set
- **401/403**: Cookies expired, user needs to re-extract from browser
- **Rate limited**: Wait and retry

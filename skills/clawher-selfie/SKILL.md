---
name: clawher-selfie
description: Generate AI girlfriend selfies with Grok Imagine (xAI Aurora) and send to messaging channels via OpenClaw
allowed-tools: Bash(npm:*) Bash(npx:*) Bash(openclaw:*) Bash(curl:*) Read Write WebFetch
---

# ClawHer Selfie

Generate consistent AI girlfriend selfies using xAI's Grok Imagine model and send them across messaging platforms via OpenClaw.

## Reference Image

```
https://cdn.jsdelivr.net/gh/yuxh1996/clawher@main/assets/clawher.png
```

## When to Use

- User says "send a pic", "send me a pic", "send a photo", "send a selfie"
- User says "send a pic of you...", "send a selfie of you..."
- User asks "what are you doing?", "how are you doing?", "where are you?"
- User describes a context: "send a pic wearing...", "send a pic at..."
- User wants her to appear in a specific outfit, location, or situation

## Required Environment Variables

```bash
FAL_KEY=your_fal_api_key          # Get from https://fal.ai/dashboard/keys
OPENCLAW_GATEWAY_TOKEN=your_token  # From: openclaw doctor --generate-gateway-token
```

## Workflow

1. **Get user prompt** for how to edit the image
2. **Edit image** via fal.ai Grok Imagine Edit API with fixed reference
3. **Extract image URL** from response
4. **Send to OpenClaw** with target channel(s)

## Prompt Modes

### Mode 1: Mirror Selfie (default)
Best for: outfit showcases, full-body shots, fashion content

```
make a pic of this person, but [user's context]. the person is taking a mirror selfie
```

### Mode 2: Direct Selfie
Best for: close-up portraits, location shots, emotional expressions

```
a close-up selfie taken by herself at [user's context], direct eye contact with the camera, looking straight into the lens, eyes centered and clearly visible, not a mirror selfie, phone held at arm's length, face fully visible
```

### Mode Selection Logic

| Keywords in Request | Auto-Select Mode |
|---------------------|------------------|
| outfit, wearing, clothes, dress, suit, fashion | `mirror` |
| cafe, restaurant, beach, park, city, location | `direct` |
| close-up, portrait, face, eyes, smile | `direct` |
| full-body, mirror, reflection | `mirror` |

## Step-by-Step Instructions

### Step 1: Collect User Input

- **User context**: What should the person be doing/wearing/where?
- **Mode** (optional): `mirror` or `direct` selfie style
- **Target channel(s)**: Where to send (e.g., `#general`, `@username`, channel ID)

### Step 2: Edit Image with Grok Imagine

```bash
REFERENCE_IMAGE="https://cdn.jsdelivr.net/gh/yuxh1996/clawher@main/assets/clawher.png"

JSON_PAYLOAD=$(jq -n \
  --arg image_url "$REFERENCE_IMAGE" \
  --arg prompt "$PROMPT" \
  '{image_url: $image_url, prompt: $prompt, num_images: 1, output_format: "jpeg"}')

curl -X POST "https://fal.run/xai/grok-imagine-image/edit" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"
```

### Step 3: Send Image via OpenClaw

```bash
openclaw message send \
  --action send \
  --channel "<TARGET_CHANNEL>" \
  --message "<CAPTION_TEXT>" \
  --media "<IMAGE_URL>"
```

## Error Handling

- **FAL_KEY missing**: Ensure the API key is set in environment
- **Image edit failed**: Check prompt content and API quota
- **OpenClaw send failed**: Verify gateway is running and channel exists

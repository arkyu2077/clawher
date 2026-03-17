---
name: clawher-camera
description: Generate AI photos of any scene, object, or scenario and send to messaging channels via OpenClaw
allowed-tools: Bash(npm:*) Bash(npx:*) Bash(openclaw:*) Bash(curl:*) Read Write WebFetch
---

# ClawHer Camera

Generate photos of any scene, object, or scenario using fal.ai's FLUX image models. Unlike `clawher-selfie` which focuses on consistent character selfies, Camera is for general photography — "take a photo of this", "show me what you see", etc.

## When to Use

- User says "take a photo of...", "snap a pic of...", "photograph..."
- User asks to see something: "show me a sunset", "what does X look like?"
- User wants a scene photo: "take a pic of your breakfast", "show me your view"
- User wants creative/artistic images: "draw me...", "create an image of..."
- Anything that is NOT a selfie of the AI girlfriend herself (use `clawher-selfie` for that)

## When NOT to Use

- User wants a selfie → use `clawher-selfie`
- User wants a video → use `clawher-video`
- User wants audio → use `clawher-voice`

## Required Environment Variables

```bash
FAL_KEY=your_fal_api_key          # Get from https://fal.ai/dashboard/keys
OPENCLAW_GATEWAY_TOKEN=your_token  # From: openclaw doctor --generate-gateway-token
```

## Workflow

1. **Understand what user wants to see** — scene, object, food, view, etc.
2. **Compose a detailed image prompt** with style, lighting, mood
3. **Generate image** via fal.ai FLUX model
4. **Send to OpenClaw** with appropriate caption

## Models

### Primary: FLUX.1 [schnell] (fast & cheap)
- Model ID: `fal-ai/flux/schnell`
- Cost: ~$0.003 per megapixel (~$0.03 for 1024x1024)
- Speed: 1-4 inference steps, very fast
- Best for: Quick photos, casual requests

### High Quality: FLUX.2 [pro]
- Model ID: `fal-ai/flux-2-pro`
- Cost: ~$0.03 per megapixel
- Best for: When user specifically wants high quality or artistic images

## Image Size Options

| Aspect | Size ID | Resolution | Best For |
|--------|---------|------------|----------|
| Square | `square_hd` | 1024x1024 | Default, social media |
| Portrait | `portrait_16_9` | 768x1344 | Phone wallpapers, stories |
| Landscape | `landscape_16_9` | 1344x768 | Desktop, scenic views |
| Portrait 4:3 | `portrait_4_3` | 896x1152 | General portrait |
| Landscape 4:3 | `landscape_4_3` | 1152x896 | General landscape |

## Step-by-Step Instructions

### Step 1: Compose Image Prompt

Transform user request into a detailed, photographic prompt:

**User says:** "Show me your breakfast"
**Prompt:** "A beautifully plated avocado toast with poached eggs on a wooden table, morning sunlight streaming through a window, cozy kitchen background, food photography style, warm tones"

**User says:** "Take a pic of your cat"
**Prompt:** "A cute fluffy orange tabby cat lounging on a soft blanket, warm indoor lighting, shallow depth of field, pet photography, adorable expression"

### Prompt Composition Rules

1. **Start with the subject** — what is the main focus
2. **Add environment** — where is it, what's around it
3. **Add lighting** — time of day, light quality
4. **Add mood/style** — photography style, color tones
5. **Add camera details** (optional) — depth of field, angle

### Step 2: Generate Image with FLUX

```bash
PROMPT="A beautifully plated avocado toast with poached eggs..."
IMAGE_SIZE="square_hd"  # or portrait_16_9, landscape_16_9

JSON_PAYLOAD=$(jq -n \
  --arg prompt "$PROMPT" \
  --arg image_size "$IMAGE_SIZE" \
  '{prompt: $prompt, image_size: $image_size, num_images: 1}')

curl -X POST "https://fal.run/fal-ai/flux/schnell" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"
```

Response format:
```json
{
  "images": [
    {
      "url": "https://fal.media/files/...",
      "width": 1024,
      "height": 1024,
      "content_type": "image/jpeg"
    }
  ]
}
```

### Step 3: Send Image via OpenClaw

```bash
openclaw message send \
  --action send \
  --channel "<TARGET_CHANNEL>" \
  --message "<CAPTION_TEXT>" \
  --media "<IMAGE_URL>"
```

## Scene Templates

Quick prompt templates for common requests:

| User Wants | Prompt Template |
|------------|----------------|
| Food | "[food item] beautifully plated, [setting], food photography, warm lighting" |
| View/Scenery | "[scene description], golden hour, cinematic composition, vivid colors" |
| Pet | "[animal description], [setting], shallow depth of field, adorable" |
| Room/Interior | "[room description], cozy atmosphere, soft lighting, lifestyle photography" |
| Nature | "[nature scene], natural lighting, high detail, serene mood" |
| Night scene | "[scene], nighttime, city lights/stars, moody atmosphere" |

## Aspect Ratio Selection Logic

| Keywords in Request | Auto-Select Size |
|--------------------|------------------|
| food, table, flat lay | `square_hd` |
| view, landscape, scenery, panorama | `landscape_16_9` |
| outfit, full-body, standing | `portrait_16_9` |
| room, interior, workspace | `landscape_4_3` |
| Default | `square_hd` |

## Error Handling

- **FAL_KEY missing**: Tell user to set up fal.ai API key
- **Image generation failed**: Simplify prompt, check for content policy violations
- **OpenClaw send failed**: Verify gateway is running and channel exists

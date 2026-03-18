---
name: clawher-video
description: Generate AI girlfriend talking videos and short clips with stable local-media delivery and configurable model routing
allowed-tools: Bash(npm:*) Bash(npx:*) Bash(openclaw:*) Bash(curl:*) Read Write WebFetch
---

# ClawHer Video

Generate talking-head videos and short video clips using fal.ai models. The stable path is: generate remotely, download locally, validate the file, then upload that local file to the messaging channel.

## When to Use

- User says "send me a video", "send a video message", "record a video for me"
- User says "I want to see you talk", "video call me"
- User wants a talking video of the AI girlfriend saying something
- User asks for a short video clip: "make a video of you at the beach"
- After generating a selfie + voice, user wants them combined into a video

## Required Environment Variables

```bash
FAL_KEY=your_fal_api_key          # Get from https://fal.ai/dashboard/keys
OPENCLAW_GATEWAY_TOKEN=your_token  # From: openclaw doctor --generate-gateway-token
```

## Workflow

### Mode 1: Talking Video (Image + Audio → Video)
Best for: Personal video messages, "talking to you" feel

1. **Get or generate a selfie image** (via clawher-selfie or clawher-camera)
2. **Get or generate voice audio** (via clawher-voice)
3. **Combine into talking video** via OmniHuman
4. **Send to OpenClaw**

### Mode 2: Text-to-Video
Best for: Scene videos, lifestyle clips, "what I'm doing" content

1. **Compose video description** based on user request
2. **Generate video** via Wan 2.5 or Veo 3
3. **Send to OpenClaw**

### Mode 3: Image-to-Video (Animate a Photo)
Best for: Turning a selfie into a short animated clip

1. **Get a selfie image**
2. **Generate animation** via Kling or Veo 3 image-to-video
3. **Send to OpenClaw**

## Models

### Talking Video: OmniHuman v1.5 (recommended)
- Model ID: `fal-ai/bytedance/omnihuman/v1.5`
- Cost: ~$0.14/second of video
- Input: Image URL + Audio URL
- Output: MP4 video with lip-sync and natural body motion
- Max audio: 30 seconds

### Text-to-Video: Veo 3 Fast (default text model)
- Model ID: `fal-ai/veo3/fast`
- Input: Text prompt
- Output: MP4 video with optional audio
- Can be overridden via `CLAWHER_VIDEO_TEXT_MODEL`

### Image-to-Video: Kling v3
- Model ID: `fal-ai/kling-video/v3/standard/image-to-video`
- Input: Image URL + motion prompt
- Output: MP4 video
- Can be overridden via `CLAWHER_VIDEO_ANIMATE_MODEL`

## Step-by-Step Instructions

### Talking Video Pipeline (Most Common)

#### Step 1: Ensure you have an image and audio

If not already available, generate them first:
- Image: Use `clawher-selfie` skill or provide a URL
- Audio: Use `clawher-voice` skill or provide a URL

#### Step 2: Generate Talking Video with OmniHuman

```bash
IMAGE_URL="https://..."  # Selfie image URL
AUDIO_URL="https://..."  # Voice audio URL

JSON_PAYLOAD=$(jq -n \
  --arg image_url "$IMAGE_URL" \
  --arg audio_url "$AUDIO_URL" \
  '{image_url: $image_url, audio_url: $audio_url}')

curl -X POST "https://fal.run/fal-ai/bytedance/omnihuman" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"
```

Response format:
```json
{
  "video": {
    "url": "https://fal.media/files/...",
    "content_type": "video/mp4"
  }
}
```

### Text-to-Video (Quick Clip)

```bash
PROMPT="A young woman waving at the camera at a cozy cafe, warm lighting, casual outfit, smiling"

JSON_PAYLOAD=$(jq -n \
  --arg prompt "$PROMPT" \
  '{prompt: $prompt}')

curl -X POST "https://fal.run/fal-ai/veo3/fast" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"
```

### Image-to-Video (Animate a Selfie)

```bash
IMAGE_URL="https://..."
PROMPT="The woman smiles and waves at the camera"

JSON_PAYLOAD=$(jq -n \
  --arg image_url "$IMAGE_URL" \
  --arg prompt "$PROMPT" \
  '{image_url: $image_url, prompt: $prompt}')

curl -X POST "https://fal.run/fal-ai/kling-video/v3/standard/image-to-video" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"
```

### Step 3: Download + Send Video via OpenClaw

```bash
curl -L "$VIDEO_URL" -o ./video.mp4
openclaw message send \
  --action send \
  --channel "<TARGET_CHANNEL>" \
  --message "<CAPTION_TEXT>" \
  --media ./video.mp4
```

## Prompt Guide for Videos

### Talking Video (OmniHuman)
No text prompt needed — it syncs to the audio automatically. Just provide a good selfie image (upper body, facing camera) and clear audio.

### Text-to-Video Prompts
Keep prompts cinematic and descriptive:

| Scenario | Example Prompt |
|----------|---------------|
| Casual vlog | "A young woman talking to camera in her room, natural lighting, cozy setup" |
| Outdoor | "A woman walking through a park in autumn, golden hour, peaceful mood" |
| Coffee date | "A woman sitting across a cafe table, smiling warmly, soft background music" |
| Getting ready | "A woman doing her makeup in front of a mirror, morning sunlight, relaxed" |

## Mode Selection Logic

| User Request Keywords | Auto-Select Mode |
|-----------------------|------------------|
| talk, say, message, tell me | `talking` (OmniHuman) |
| video of you at..., doing... | `text-to-video` (Wan 2.5) |
| animate, move, come alive | `image-to-video` (Kling) |
| video call, face time | `talking` (OmniHuman) |

## Error Handling

- **FAL_KEY missing**: Tell user to set up fal.ai API key
- **OmniHuman failed**: Check image (must show face clearly) and audio (max 30s, clear speech)
- **Video too long**: Split audio into <30s segments for OmniHuman
- **OpenClaw send failed**: Verify gateway is running and channel exists

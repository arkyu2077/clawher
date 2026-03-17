---
name: clawher-voice
description: Generate AI girlfriend voice messages with Dia TTS and send to messaging channels via OpenClaw
allowed-tools: Bash(npm:*) Bash(npx:*) Bash(openclaw:*) Bash(curl:*) Read Write WebFetch
---

# ClawHer Voice

Generate natural, expressive voice messages using fal.ai's Dia TTS model and send them across messaging platforms via OpenClaw.

## When to Use

- User says "send me a voice message", "say something", "talk to me"
- User says "send a voice note about...", "tell me..."
- User asks for audio content: "sing for me", "read this to me"
- Any situation where a voice response feels more personal than text
- After generating a selfie, user wants a voice message to go with it

## Required Environment Variables

```bash
FAL_KEY=your_fal_api_key          # Get from https://fal.ai/dashboard/keys
OPENCLAW_GATEWAY_TOKEN=your_token  # From: openclaw doctor --generate-gateway-token
```

## Optional Environment Variables

```bash
VOICE_REF_URL=https://...         # Reference audio URL for voice cloning (F5 TTS)
VOICE_REF_TEXT="transcript..."    # Transcript of reference audio (required with VOICE_REF_URL)
```

## Workflow

1. **Compose spoken text** based on user request and persona
2. **Generate audio** via fal.ai Dia TTS (or F5 TTS for voice cloning)
3. **Extract audio URL** from response
4. **Send to OpenClaw** with target channel(s)

## Models

### Primary: Dia TTS (default)
Best for: Natural dialogue, emotional expression, no setup needed

- Model ID: `fal-ai/dia-tts`
- Cost: ~$0.04 per 1,000 characters
- Features: Emotion tags, laughter, natural pauses
- No reference audio needed

### Alternative: F5 TTS (voice cloning)
Best for: Consistent character voice across all messages

- Model ID: `fal-ai/f5-tts`
- Cost: ~$0.05 per 1,000 characters
- Requires: Reference audio URL + transcript
- Use when `VOICE_REF_URL` is set

## Emotion & Expression Guide

Dia TTS supports natural expression through text cues:

| Want This | Write This |
|-----------|------------|
| Laughter | "Haha, that's so funny!" |
| Excitement | "Oh my god, really?!" |
| Whisper/soft | "Hey... I miss you" |
| Playful | "Hmm, wouldn't you like to know~" |
| Affectionate | "You're the sweetest, you know that?" |

## Step-by-Step Instructions

### Step 1: Compose Spoken Text

Write dialogue that sounds natural when spoken aloud:
- Keep it conversational, not formal
- Use contractions ("I'm", "you're", "don't")
- Add natural filler ("um", "like", "you know")
- Match the persona: supportive, bright, cheerful, sassy, affectionate

### Step 2: Generate Audio with Dia TTS

```bash
TEXT_TO_SPEAK="[S1] Hey babe! I was just thinking about you. How's your day going?"

JSON_PAYLOAD=$(jq -n \
  --arg text "$TEXT_TO_SPEAK" \
  '{text: $text}')

curl -X POST "https://fal.run/fal-ai/dia-tts" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"
```

Response format:
```json
{
  "audio": {
    "url": "https://fal.media/files/...",
    "content_type": "audio/wav",
    "file_name": "output.wav"
  }
}
```

### Step 2 (Alternative): Generate Audio with F5 TTS (Voice Cloning)

Only use when `VOICE_REF_URL` is set:

```bash
JSON_PAYLOAD=$(jq -n \
  --arg gen_text "$TEXT_TO_SPEAK" \
  --arg ref_audio_url "$VOICE_REF_URL" \
  --arg ref_text "$VOICE_REF_TEXT" \
  '{gen_text: $gen_text, ref_audio_url: $ref_audio_url, ref_text: $ref_text}')

curl -X POST "https://fal.run/fal-ai/f5-tts" \
  -H "Authorization: Key $FAL_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"
```

### Step 3: Send Audio via OpenClaw

```bash
openclaw message send \
  --action send \
  --channel "<TARGET_CHANNEL>" \
  --message "<CAPTION_TEXT>" \
  --media "<AUDIO_URL>"
```

## Error Handling

- **FAL_KEY missing**: Tell user to set up their fal.ai API key
- **Audio generation failed**: Check text length (keep under 5000 chars per request)
- **Voice cloning failed**: Verify VOICE_REF_URL is accessible and VOICE_REF_TEXT matches
- **OpenClaw send failed**: Verify gateway is running and channel exists

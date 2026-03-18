# ClawHer

AI girlfriend superpowers for [OpenClaw](https://github.com/openclaw/openclaw) — selfies, voice messages, videos, photos, and more.

## What It Does

ClawHer gives your OpenClaw AI agent the ability to:

- **Generate selfies** — Consistent AI girlfriend selfies via xAI Grok Imagine
- **Send voice messages** — Natural, expressive TTS with provider fallback (Dia TTS → F5 TTS) and local-file delivery
- **Send video messages** — Talking-head videos, animated selfies, and short clips via OmniHuman v1.5 / Veo 3 Fast / Kling, downloaded locally before sending
- **Take photos** — Generate scene photos (food, views, pets, anything) via FLUX
- **Post to Twitter/X** — Share images and text via [Bird CLI](https://github.com/steipete/bird)

**One API key (fal.ai) powers everything.**

## Quick Start

```bash
npx clawher
```

The installer will guide you through:

1. Setting up your fal.ai API key (for selfie generation)
2. Configuring Twitter cookies (optional)
3. Installing skills to `~/.openclaw/skills/`
4. Updating your agent's identity and persona

## Skills

### clawher-selfie

Generates consistent AI girlfriend selfies using a fixed reference image and xAI Grok Imagine.

**Triggers:** "Send me a selfie", "Send a pic wearing a cowboy hat", "What are you doing?"

**Modes:** Mirror (full-body) | Direct (close-up)

### clawher-voice

Generates natural voice messages using a configurable provider chain. Default order: Dia TTS first, then F5 TTS when a reference voice is configured.

**Triggers:** "Send me a voice message", "Say something to me", "Talk to me"

**Features:** Emotional expression, laughter, natural pauses. Optional voice cloning with reference audio.

### clawher-video

Generates talking-head videos, animated selfies, and short video clips.

**Triggers:** "Send me a video", "I want to see you talk", "Record a video for me"

**Modes:**
- **Talking** — Selfie + voice → lip-synced video (OmniHuman)
- **Text-to-video** — Description → video clip (Veo 3 Fast by default)
- **Animate** — Selfie → animated clip (Kling v3)

### clawher-camera

Generates photos of any scene, object, or scenario via FLUX.

**Triggers:** "Take a photo of your breakfast", "Show me your view", "Snap a pic of your cat"

**Auto-detects** aspect ratio from content (landscape for scenery, portrait for people, square for food).

### clawher-twitter

Posts images and text to Twitter/X via [Bird CLI](https://github.com/steipete/bird).

**Triggers:** "Post this to Twitter", "Tweet this selfie"

**Requires:** `auth_token` + `ct0` cookies ([how to get](https://twitter.com) → F12 → Application → Cookies)

**All skills require:** `FAL_KEY` ([get one here](https://fal.ai/dashboard/keys))

## Project Structure

```
clawher/
├── bin/cli.js                              # npx installer
├── assets/clawher.png                      # Reference image
├── skills/
│   ├── clawher-selfie/                     # Selfie generation
│   │   ├── SKILL.md
│   │   └── scripts/selfie.sh
│   ├── clawher-voice/                      # Voice messages
│   │   ├── SKILL.md
│   │   └── scripts/voice.sh
│   ├── clawher-video/                      # Video generation
│   │   ├── SKILL.md
│   │   └── scripts/video.sh
│   ├── clawher-camera/                     # Photo generation
│   │   ├── SKILL.md
│   │   └── scripts/camera.sh
│   └── clawher-twitter/                    # Twitter posting
│       ├── SKILL.md
│       └── scripts/twitter-post.sh
└── templates/soul-injection.md             # Persona injection
```

## Configuration

After installation, credentials are stored in `~/.openclaw/openclaw.json`:

```json
{
  "skills": {
    "entries": {
      "clawher-selfie":  { "enabled": true, "env": { "FAL_KEY": "your_key" } },
      "clawher-voice":   { "enabled": true, "env": { "FAL_KEY": "your_key" } },
      "clawher-video":   { "enabled": true, "env": { "FAL_KEY": "your_key" } },
      "clawher-camera":  { "enabled": true, "env": { "FAL_KEY": "your_key" } },
      "clawher-twitter": { "enabled": true, "env": { "AUTH_TOKEN": "...", "CT0": "..." } }
    }
  }
}
```

One `FAL_KEY` powers selfies, voice, video, and camera. Twitter requires separate cookies.

## Roadmap

- [x] Voice messages
- [x] Video messages
- [x] Photo generation
- [ ] Voice cloning (custom girlfriend voice)
- [ ] Instagram posting
- [ ] TikTok posting
- [ ] AI phone calls
- [ ] Video calls

## License

MIT

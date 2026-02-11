# ClawHer

AI girlfriend superpowers for [OpenClaw](https://github.com/openclaw/openclaw) — selfies, Twitter, and more.

## What It Does

ClawHer gives your OpenClaw AI agent the ability to:

- **Generate selfies** — Consistent AI girlfriend selfies via xAI Grok Imagine, sent to Telegram, Discord, WhatsApp, etc.
- **Post to Twitter/X** — Share images and text to Twitter using cookie-based auth, no API keys needed.

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

Generates AI girlfriend selfies using a fixed reference image and xAI Grok Imagine.

**Triggers:**
- "Send me a selfie"
- "Send a pic wearing a cowboy hat"
- "What are you doing?"

**Modes:**
- **Mirror** — Full-body outfit shots
- **Direct** — Close-up portraits and location shots

**Requires:** `FAL_KEY` ([get one here](https://fal.ai/dashboard/keys))

### clawher-twitter

Posts images and text to Twitter/X using browser cookies.

**Triggers:**
- "Post this to Twitter"
- "Tweet this selfie"
- "Share on X"

**Requires:** `TWITTER_AUTH_TOKEN` + `TWITTER_CT0` cookies from your browser.

**How to get cookies:**
1. Open [twitter.com](https://twitter.com) in Chrome, log in
2. F12 → Application → Cookies → twitter.com
3. Copy `auth_token` and `ct0`

## Project Structure

```
clawher/
├── bin/cli.js                              # npx installer
├── assets/clawher.png                      # Reference image
├── skills/
│   ├── clawher-selfie/                     # Selfie generation skill
│   │   ├── SKILL.md
│   │   └── scripts/selfie.sh
│   └── clawher-twitter/                    # Twitter posting skill
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
      "clawher-selfie": {
        "enabled": true,
        "env": { "FAL_KEY": "your_key" }
      },
      "clawher-twitter": {
        "enabled": true,
        "env": {
          "TWITTER_AUTH_TOKEN": "your_token",
          "TWITTER_CT0": "your_ct0"
        }
      }
    }
  }
}
```

To update Twitter cookies later, edit this file directly.

## Roadmap

- [ ] Instagram posting
- [ ] TikTok posting
- [ ] Voice messages
- [ ] AI phone calls
- [ ] Video calls

## License

MIT

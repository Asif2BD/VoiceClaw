# 🎙️ VoiceClaw — Local Voice I/O for OpenClaw Agents

> **Created by [M Asif Rahman](https://github.com/Asif2BD)** ([@Asif2BD](https://github.com/Asif2BD))  
> AI Enthusiast · WordPress Veteran · Entrepreneur-Investor  
> Founder of [@xCloudDev](https://github.com/xCloudDev), [@WPDevelopers](https://github.com/WPDevelopers)

A local-only voice skill for [OpenClaw](https://openclaw.ai) agents. Transcribe inbound voice messages with **Whisper** and reply with synthesized speech via **Piper TTS** — no cloud, no API keys, no paid services.

---

## What it does

- **Speech-to-Text**: Converts inbound audio (OGG, MP3, WAV, M4A) to text using [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)
- **Text-to-Speech**: Generates voice replies using [Piper](https://github.com/rhasspy/piper) with 7 English voices
- **Agent behavior rules**: When a voice message arrives, agents respond in voice + text automatically
- **100% local**: No data sent anywhere, no API keys, no internet required

---

## Requirements

- `whisper` (whisper.cpp binary)
- Whisper model: `ggml-base.en.bin` (auto-downloaded on first run, or manually)
- `piper` TTS with voice models in `/opt/piper/voices/`
- `ffmpeg` (for audio format conversion)

---

## Install via ClawhHub

```bash
clawhub install voiceclaw
```

## Manual Install

Copy the `voiceclaw/` folder into your OpenClaw skills directory.

---

## Usage

```bash
# Transcribe a voice message
bash scripts/transcribe.sh /path/to/voice.ogg

# Generate a voice reply
bash scripts/speak.sh "Hello, your task is complete." /tmp/reply.wav

# Convert to OGG for Telegram
ffmpeg -i /tmp/reply.wav -c:a libopus -b:a 32k /tmp/reply.ogg -y
```

---

## Available Voices

| Voice | Style |
|---|---|
| `en_US-lessac-medium` | Neutral American (default) |
| `en_US-amy-medium` | Warm American female |
| `en_US-joe-medium` | American male |
| `en_US-kusal-medium` | Expressive American male |
| `en_US-danny-low` | Deep American male |
| `en_GB-alba-medium` | British female |
| `en_GB-northern_english_male-medium` | Northern British male |

---

## Security

- **All processing is local** — no audio or text is ever sent to a cloud service or external API
- **Temporary files are cleaned up** — audio is converted to WAV in `/tmp` and deleted immediately after transcription
- **Voice model selection is sanitized** — input stripped to `[a-zA-Z0-9_-]` only, preventing path traversal attacks
- **No network calls** — neither script makes any network request; all inference runs on-device

---

## How it works

```
User voice message (OGG/MP3/WAV)
        ↓
  ffmpeg → 16kHz mono WAV
        ↓
  whisper.cpp → transcript text
        ↓
  Agent processes as normal text
        ↓
  Agent composes reply
        ↓
  Piper TTS → WAV → OGG Opus
        ↓
Voice reply + text reply sent together
```

---

## Author

**M Asif Rahman** — [asif.im](https://asif.im) · [GitHub](https://github.com/Asif2BD) · [Twitter/X](https://twitter.com/Asif2BD)

Built for the [Matrix Zion](https://openclaw.ai) multi-agent system.  
Part of the [OpenClaw](https://openclaw.ai) skill ecosystem.

---

## Author

Created by **[M Asif Rahman](https://github.com/Asif2BD)** — maker of [MissionDeck.ai](https://missiondeck.ai) and the Matrix Zion AI agent system.

- GitHub: [@Asif2BD](https://github.com/Asif2BD)
- ClawHub: [clawhub.ai/Asif2BD](https://clawhub.ai/Asif2BD)

## License

MIT © 2026 [M Asif Rahman](https://github.com/Asif2BD)

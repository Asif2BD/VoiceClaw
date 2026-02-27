# 🎙️ VoiceClaw — Local Voice I/O for OpenClaw Agents

A local-only voice skill for [OpenClaw](https://openclaw.ai) agents. Transcribe inbound voice messages with **Whisper** and reply with synthesized speech via **Piper TTS** — no cloud, no API keys, no paid services.

## What it does

- **Speech-to-Text**: Converts inbound audio (OGG, MP3, WAV, M4A) to text using [Whisper.cpp](https://github.com/ggerganov/whisper.cpp)
- **Text-to-Speech**: Generates voice replies using [Piper](https://github.com/rhasspy/piper) with 7 English voices
- **Agent rules**: When a voice message arrives, agents respond in voice + text automatically

## Requirements

- `whisper` (whisper.cpp binary)
- Whisper model: `ggml-base.en.bin` (auto-downloaded on first run, or manually)
- `piper` TTS with voice models in `/opt/piper/voices/`
- `ffmpeg` (for audio format conversion)

## Install via ClawhHub

```bash
clawhub install voiceclaw
```

## Manual Install

Copy the `voiceclaw/` folder into your OpenClaw skills directory.

## Usage

```bash
# Transcribe a voice message
bash scripts/transcribe.sh /path/to/voice.ogg

# Generate a voice reply
bash scripts/speak.sh "Hello, your task is complete." /tmp/reply.wav

# Convert to OGG for Telegram
ffmpeg -i /tmp/reply.wav -c:a libopus -b:a 32k /tmp/reply.ogg -y
```

## Available Voices

| Voice | Style |
|---|---|
| `en_US-lessac-medium` | Neutral American (default) |
| `en_US-amy-medium` | Warm American female |
| `en_US-joe-medium` | American male |
| `en_GB-alba-medium` | British female |
| more... | See SKILL.md |

## License

MIT

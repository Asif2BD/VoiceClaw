---
name: voiceclaw
description: "Local voice I/O for OpenClaw agents. Transcribe inbound audio/voice messages using local Whisper (whisper.cpp), and generate voice replies using local Piper TTS. The skill scripts make zero network calls — all STT and TTS inference runs on-device using pre-installed local binaries. One-time model download required during setup only. Use when an agent receives a voice/audio message and should respond in both voice and text, or when any text response should be synthesized and sent as audio. Triggers on: voice messages, audio attachments, respond in voice, send as audio, speak this, voiceclaw."
metadata:
  {
    "openclaw":
      {
        "requires": { "bins": ["whisper", "piper", "ffmpeg"] },
        "network": "none",
        "env":
          [
            { "name": "WHISPER_BIN", "description": "Path to whisper binary (default: auto-detected via which)" },
            { "name": "WHISPER_MODEL", "description": "Path to ggml-base.en.bin model file (default: ~/.cache/whisper/ggml-base.en.bin)" },
            { "name": "PIPER_BIN", "description": "Path to piper binary (default: auto-detected via which)" },
            { "name": "VOICECLAW_VOICES_DIR", "description": "Path to directory containing .onnx voice model files (default: ~/.local/share/piper/voices)" }
          ]
      }
  }
---

# VoiceClaw

Local-only voice I/O for OpenClaw agents.

- **STT:** Whisper (whisper.cpp) — `ggml-base.en.bin` model
- **TTS:** Piper — multiple English voices, runs fully offline
- **Script network calls: none** — `transcribe.sh` and `speak.sh` make zero network requests
- **No cloud APIs, no API keys required**

> ⚠️ **Setup note:** The Whisper model file (~150MB) must be downloaded once before first use. See README.md for instructions. The skill scripts make no network requests.

---

## Required Binaries

| Binary | Purpose | Install |
|---|---|---|
| `whisper` | Speech-to-text (whisper.cpp) | [whisper.cpp releases](https://github.com/ggerganov/whisper.cpp/releases) |
| `piper` | Text-to-speech | `pip install piper-tts` |
| `ffmpeg` | Audio format conversion | `apt install ffmpeg` |

## Required Files

| File | Default path | Override |
|---|---|---|
| Whisper model (`ggml-base.en.bin`) | `~/.cache/whisper/ggml-base.en.bin` | `WHISPER_MODEL=/path/to/model` |
| Piper voice models (`*.onnx`) | `~/.local/share/piper/voices/` | `VOICECLAW_VOICES_DIR=/path/to/voices/` |

## Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `WHISPER_BIN` | auto-detected via `which` | Path to whisper binary |
| `WHISPER_MODEL` | `~/.cache/whisper/ggml-base.en.bin` | Path to Whisper model file |
| `PIPER_BIN` | auto-detected via `which` | Path to piper binary |
| `VOICECLAW_VOICES_DIR` | `~/.local/share/piper/voices` | Directory containing `.onnx` voice model files |

---

## Setup Check

```bash
which whisper && echo "STT binary: OK"
which piper && echo "TTS binary: OK"
which ffmpeg && echo "ffmpeg: OK"
ls "${WHISPER_MODEL:-$HOME/.cache/whisper/ggml-base.en.bin}" && echo "STT model: OK"
ls "${VOICECLAW_VOICES_DIR:-$HOME/.local/share/piper/voices}"/*.onnx 2>/dev/null | head -1 && echo "TTS voices: OK"
```

## First-time Setup

Before using this skill, ensure the Whisper model file exists at `$WHISPER_MODEL` (default: `~/.cache/whisper/ggml-base.en.bin`) and Piper voice models exist at `$VOICECLAW_VOICES_DIR` (default: `~/.local/share/piper/voices/`).

See **README.md** for one-time download instructions. The skill scripts themselves make no network requests.

---

## Inbound Voice: Transcribe

```bash
# Transcribe audio → text (supports ogg, mp3, m4a, wav, flac)
TRANSCRIPT=$(bash scripts/transcribe.sh /path/to/audio.ogg)
```

Set `WHISPER_MODEL` if your model is not at the default path:
```bash
WHISPER_MODEL=/custom/path/ggml-base.en.bin bash scripts/transcribe.sh audio.ogg
```

---

## Outbound Voice: Speak

```bash
# Step 1: Generate WAV
WAV=$(bash scripts/speak.sh "Your response here." /tmp/reply.wav en_US-lessac-medium)

# Step 2: Convert to OGG Opus (required for Telegram)
ffmpeg -i "$WAV" -c:a libopus -b:a 32k /tmp/reply.ogg -y -loglevel error

# Step 3: Send via message tool (filePath=/tmp/reply.ogg)
```

Set `VOICECLAW_VOICES_DIR` if your voices are not at the default path:
```bash
VOICECLAW_VOICES_DIR=/custom/path/to/voices bash scripts/speak.sh "Hello." /tmp/reply.wav
```

---

## Available Voices

| Voice | Style |
|---|---|
| `en_US-lessac-medium` | Neutral American (default) |
| `en_US-amy-medium` | Warm American female |
| `en_US-joe-medium` | American male |
| `en_US-kusal-medium` | Expressive American male |
| `en_US-danny-low` | Deep American male (fast) |
| `en_GB-alba-medium` | British female |
| `en_GB-northern_english_male-medium` | Northern British male |

---

## Agent Behavior Rules

1. **Voice in → Voice + Text out.** If you receive a voice message, always respond with both a voice reply and a text reply.
2. **Include the transcript.** Always show: *"🎙️ I heard: [transcript]"* at the top of your text reply.
3. **Keep voice responses concise.** Piper TTS works best under ~200 words. Summarize for voice; include full detail in text.
4. **Local only.** Never use a cloud TTS/STT API — only local `whisper` + `piper` binaries.
5. **Send voice before text.** Send the audio file first, then the text reply.

---

## Full Example (Telegram)

```bash
# 1. Transcribe inbound voice (WHISPER_MODEL set via env if non-default path)
TRANSCRIPT=$(bash path/to/voiceclaw/scripts/transcribe.sh /path/to/voice.ogg)

# 2. Compose + speak reply
RESPONSE="Deployment complete. All checks passed."
WAV=$(bash path/to/voiceclaw/scripts/speak.sh "$RESPONSE" /tmp/reply_$$.wav)
ffmpeg -i "$WAV" -c:a libopus -b:a 32k /tmp/reply_$$.ogg -y -loglevel error

# 3. Send voice + text
# message(action=send, filePath=/tmp/reply_$$.ogg, ...)
# reply: "🎙️ I heard: $TRANSCRIPT\n\n$RESPONSE"
```

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `whisper: command not found` | Install whisper.cpp binary, add to PATH |
| Whisper model not found | Set `WHISPER_MODEL=/path/to/ggml-base.en.bin` |
| `piper: command not found` | `pip install piper-tts` or check `~/.local/bin/piper` |
| Voice model missing | Set `VOICECLAW_VOICES_DIR=/path/to/voices/` |
| OGG won't play on Telegram | Ensure `-c:a libopus` in ffmpeg conversion |

---

## Roadmap

### v1.1 (planned)
- Configurable default voice via `VOICECLAW_DEFAULT_VOICE` env var

---
name: voiceclaw
description: "Local voice I/O for OpenClaw agents. Transcribe inbound audio/voice messages using local Whisper (whisper.cpp), and generate voice replies using local Piper TTS — no cloud, no API keys, no network calls during operation. Use when an agent receives a voice/audio message and should respond in both voice and text, or when any text response should be synthesized and sent as audio. Triggers on: voice messages, audio attachments, respond in voice, send as audio, speak this, voiceclaw."
requires:
  binaries:
    - whisper
    - piper
    - ffmpeg
  files:
    - description: "Whisper STT model (ggml-base.en.bin)"
      path: "$WHISPER_MODEL or ~/.cache/whisper/ggml-base.en.bin"
      download: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
    - description: "Piper voice models (*.onnx)"
      path: "$VOICECLAW_VOICES_DIR or ~/.local/share/piper/voices/"
network: none
---

# VoiceClaw

Local-only voice I/O for OpenClaw agents. **Zero network calls during operation** — all STT and TTS inference runs on-device using pre-installed binaries.

- **STT:** Whisper (whisper.cpp) — `ggml-base.en.bin` model
- **TTS:** Piper — multiple English voices, runs fully offline
- **No cloud, no paid APIs, no API keys required**

---

## Requirements

This skill requires three binaries installed on the system:

| Binary | Purpose | Install |
|---|---|---|
| `whisper` | Speech-to-text (whisper.cpp) | [whisper.cpp releases](https://github.com/ggerganov/whisper.cpp/releases) |
| `piper` | Text-to-speech | `pip install piper-tts` |
| `ffmpeg` | Audio format conversion | `apt install ffmpeg` |

Plus model files:
- **Whisper model:** `ggml-base.en.bin` — set `WHISPER_MODEL=/path/to/ggml-base.en.bin`
- **Piper voices:** `.onnx` files — set `VOICECLAW_VOICES_DIR=/path/to/voices/`

### Setup Check

```bash
which whisper && echo "STT binary: OK"
which piper && echo "TTS binary: OK"
which ffmpeg && echo "ffmpeg: OK"
ls "${WHISPER_MODEL:-$HOME/.cache/whisper/ggml-base.en.bin}" && echo "STT model: OK"
ls "${VOICECLAW_VOICES_DIR:-$HOME/.local/share/piper/voices/}"/*.onnx 2>/dev/null | head -1 && echo "TTS voices: OK"
```

### One-time model download (if missing)

```bash
# Whisper model (~150MB, downloaded once — not used during normal operation)
mkdir -p "$HOME/.cache/whisper"
curl -L -o "$HOME/.cache/whisper/ggml-base.en.bin" \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
```

> ⚠️ The `curl` above is a **one-time setup step only**. The skill scripts (`transcribe.sh`, `speak.sh`) make **zero network calls** during operation.

---

## Inbound Voice: Transcribe

When you receive an audio/voice message attachment:

```bash
# Transcribe (supports ogg, mp3, m4a, wav, flac)
TRANSCRIPT=$(bash scripts/transcribe.sh /path/to/inbound/audio.ogg)
echo "$TRANSCRIPT"
```

Then process `$TRANSCRIPT` as if it were a text message. Always include the transcript in your text reply so the user sees what was heard.

---

## Outbound Voice: Speak

Generate a voice reply and send it alongside your text response:

```bash
# Step 1: Generate WAV (no network call — local Piper TTS)
WAV=$(bash scripts/speak.sh "Your response text here" /tmp/reply.wav en_US-lessac-medium)

# Step 2: Convert to OGG Opus (required for Telegram voice messages)
ffmpeg -i "$WAV" -c:a libopus -b:a 32k /tmp/reply.ogg -y -loglevel error

# Step 3: Send as voice message (Telegram example)
# Use the message tool: action=send, filePath=/tmp/reply.ogg
```

For other platforms (WhatsApp, Signal), WAV or OGG both work — check platform requirements.

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

Voice models default to `$VOICECLAW_VOICES_DIR` (set this env var to override the default path).

---

## Agent Behavior Rules

When VoiceClaw is active, apply these rules to every session:

1. **Voice in → Voice + Text out.** If you receive a voice message, always respond with both a voice reply and the text reply. Never reply text-only to a voice message.

2. **Include the transcript.** Always show what you heard: *"🎙️ I heard: [transcript]"* at the top of your text reply.

3. **Keep voice responses concise.** TTS works best under ~200 words. For long responses, summarize for the voice reply and include full detail in the text.

4. **Local only.** Never use a cloud TTS/STT API. Only `whisper` + `piper` binaries installed on this server.

5. **Send voice before text.** Send the audio file first (as a voice message), then follow with the text reply.

---

## Full Example (Telegram)

```bash
# 1. Receive voice message at /path/to/inbound/voice.ogg

# 2. Transcribe (local whisper — no network)
TRANSCRIPT=$(bash path/to/voiceclaw/scripts/transcribe.sh /path/to/inbound/voice.ogg)

# 3. Generate response text (your normal agent logic)
RESPONSE="Got it. The deployment is complete and all checks passed."

# 4. Speak the response (local piper — no network)
WAV=$(bash path/to/voiceclaw/scripts/speak.sh "$RESPONSE" /tmp/reply_$$.wav)
ffmpeg -i "$WAV" -c:a libopus -b:a 32k /tmp/reply_$$.ogg -y -loglevel error

# 5. Send voice (use message tool)
# message(action=send, filePath=/tmp/reply_$$.ogg, channel=telegram, ...)

# 6. Send text reply (normal reply)
# "🎙️ I heard: $TRANSCRIPT\n\n$RESPONSE"
```

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `whisper: command not found` | Install whisper.cpp binary and add to PATH |
| Whisper model not found | Set `WHISPER_MODEL=/path/to/ggml-base.en.bin` or run one-time download above |
| `piper: command not found` | `pip install piper-tts` or check `~/.local/bin/` |
| Voice model missing | Set `VOICECLAW_VOICES_DIR=/path/to/voices/` and ensure `.onnx` files exist |
| OGG won't play on Telegram | Ensure `-c:a libopus` in ffmpeg conversion |
| Audio too quiet/fast | Add `--volume 1.5` or `--length-scale 1.1` to piper call |

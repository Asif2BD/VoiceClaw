---
name: voiceclaw
description: "Local voice I/O for OpenClaw agents. Transcribe inbound audio/voice messages using local Whisper (whisper.cpp), and generate voice replies using local Piper TTS — no cloud, no API keys. Use when an agent receives a voice/audio message and should respond in both voice and text, or when any text response should be synthesized and sent as audio. Triggers on: voice messages, audio attachments, respond in voice, send as audio, speak this, voiceclaw."
---

# VoiceClaw

Local-only voice I/O for OpenClaw agents.

- **STT:** Whisper (whisper.cpp) — `ggml-base.en.bin` model
- **TTS:** Piper — multiple English voices, runs offline
- **No cloud, no paid APIs, no API keys required**

---

## Setup Check

```bash
which whisper && echo "STT: OK"
ls /root/.cache/whisper/ggml-base.en.bin && echo "Model: OK"
which piper && ls /opt/piper/voices/*.onnx | head -3 && echo "TTS: OK"
```

If Whisper model is missing:
```bash
mkdir -p /root/.cache/whisper
curl -L -o /root/.cache/whisper/ggml-base.en.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
```

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
# Step 1: Generate WAV
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
| `en_US-danny-low` | Deep American male (low quality, fast) |
| `en_GB-alba-medium` | British female |
| `en_GB-northern_english_male-medium` | Northern British male |

Voice models are at `/opt/piper/voices/`.

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
# 1. Receive voice message at /root/.openclaw/media/inbound/voice.ogg

# 2. Transcribe
TRANSCRIPT=$(bash path/to/voiceclaw/scripts/transcribe.sh \
  /root/.openclaw/media/inbound/voice.ogg)

# 3. Generate response text (your normal agent logic)
RESPONSE="Got it. The deployment is complete and all checks passed."

# 4. Speak the response
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
| `whisper: command not found` | `apt install whisper` or check PATH |
| `ggml-base.en.bin not found` | Download model (see Setup Check above) |
| `piper: command not found` | `pip install piper-tts` or check `/root/.local/bin/` |
| Voice model missing | `ls /opt/piper/voices/` — pick an available voice |
| OGG won't play on Telegram | Ensure `-c:a libopus` in ffmpeg conversion |
| Audio too quiet/fast | Add `--volume 1.5` or `--length-scale 1.1` to piper call |

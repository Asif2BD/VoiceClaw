#!/usr/bin/env bash
# transcribe.sh — Convert audio to text using local Whisper (whisper.cpp)
# Usage: transcribe.sh <audio_file> [model_path]
# Output: prints transcript to stdout
# Supports: ogg, mp3, m4a, wav, flac (auto-converts to wav via ffmpeg)

set -euo pipefail

AUDIO_FILE="${1:-}"
MODEL="${2:-/root/.cache/whisper/ggml-base.en.bin}"
WHISPER_BIN="${WHISPER_BIN:-$(which whisper 2>/dev/null || echo whisper)}"
TMP_WAV="/tmp/voicelaw_stt_$$.wav"

if [[ -z "$AUDIO_FILE" ]]; then
  echo "Usage: transcribe.sh <audio_file> [model_path]" >&2
  exit 1
fi

if [[ ! -f "$AUDIO_FILE" ]]; then
  echo "Error: file not found: $AUDIO_FILE" >&2
  exit 1
fi

if [[ ! -f "$MODEL" ]]; then
  echo "Error: Whisper model not found: $MODEL" >&2
  echo "Run: mkdir -p $(dirname $MODEL) && curl -L -o $MODEL https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin" >&2
  exit 1
fi

cleanup() { rm -f "$TMP_WAV"; }
trap cleanup EXIT

# Convert to 16kHz mono WAV (Whisper requirement)
ffmpeg -i "$AUDIO_FILE" -ar 16000 -ac 1 "$TMP_WAV" -y -loglevel error

# Transcribe — extract only the bracketed transcript lines
"$WHISPER_BIN" -m "$MODEL" "$TMP_WAV" 2>/dev/null \
  | grep -E '^\[' \
  | sed 's/\[[0-9:. ->]*\]  *//' \
  | tr '\n' ' ' \
  | sed 's/^[[:space:]]*//' \
  | sed 's/[[:space:]]*$//'

echo  # final newline

#!/usr/bin/env bash
# speak.sh — Convert text to speech using local Piper TTS
# Usage: speak.sh "text to speak" [output_file.wav] [voice]
# Output: writes WAV to output_file (default: /tmp/voicelaw_tts.wav)
# Available voices: en_US-amy-medium, en_US-joe-medium, en_US-lessac-medium,
#                   en_US-kusal-medium, en_US-danny-low,
#                   en_GB-alba-medium, en_GB-northern_english_male-medium

set -euo pipefail

TEXT="${1:-}"
OUTPUT="${2:-/tmp/voicelaw_tts_$$.wav}"
VOICE="${3:-en_US-lessac-medium}"
VOICES_DIR="${VOICELAW_VOICES_DIR:-/opt/piper/voices}"
PIPER_BIN="${PIPER_BIN:-$(which piper 2>/dev/null || echo piper)}"

if [[ -z "$TEXT" ]]; then
  echo "Usage: speak.sh \"text\" [output.wav] [voice]" >&2
  exit 1
fi

MODEL="$VOICES_DIR/$VOICE.onnx"
CONFIG="$VOICES_DIR/$VOICE.onnx.json"

if [[ ! -f "$MODEL" ]]; then
  echo "Error: voice model not found: $MODEL" >&2
  echo "Available voices in $VOICES_DIR:" >&2
  ls "$VOICES_DIR"/*.onnx 2>/dev/null | xargs -n1 basename | sed 's/\.onnx$//' >&2
  exit 1
fi

# Generate WAV
CONFIG_ARGS=()
[[ -f "$CONFIG" ]] && CONFIG_ARGS=(-c "$CONFIG")

echo "$TEXT" | "$PIPER_BIN" -m "$MODEL" "${CONFIG_ARGS[@]}" -f "$OUTPUT" 2>/dev/null

echo "$OUTPUT"

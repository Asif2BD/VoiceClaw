# Security Policy

## Overview

VoiceClaw is a local-only voice I/O skill. It makes **no network requests** and sends **no data to external services**.

## Design Principles

| Property | Detail |
|---|---|
| **Local-only processing** | All STT (Whisper) and TTS (Piper) inference runs on-device |
| **No cloud APIs** | No API keys, no external endpoints, no telemetry |
| **No credential handling** | Scripts accept no passwords or secrets |
| **No eval/exec of untrusted input** | Text is piped to TTS stdin, never executed |
| **Input sanitization** | Voice name parameter sanitized to `[a-zA-Z0-9_-]` to prevent path traversal |
| **Temporary file cleanup** | WAV files in `/tmp` are deleted via bash `trap` on script exit |
| **File existence checks** | All input files and model files are verified before use |

## Dependencies

| Dependency | Source | Risk |
|---|---|---|
| `whisper` (whisper.cpp) | Local binary | Low — no network, runs inference only |
| `ggml-base.en.bin` | Downloaded from HuggingFace on setup | Low — static model file, read-only |
| `piper` | Local binary (pip install piper-tts) | Low — no network, TTS inference only |
| `*.onnx` voice models | Pre-installed at `/opt/piper/voices/` | Low — static model files, read-only |
| `ffmpeg` | System package | Low — used for audio format conversion only |

## Threat Model

### What is protected against
- **Path traversal** via voice name input (`../../../etc/passwd` → sanitized to empty string → rejected)
- **Temp file leakage** — transcription WAV files are deleted on script exit even if the script errors

### What is out of scope
- Malicious audio content (adversarial inputs to Whisper — model-level concern, not script-level)
- Host system security (firewall, user permissions — OpenClaw deployment concern)

## Reporting a Vulnerability

Open an issue on GitHub or contact the maintainers directly. Please do not disclose security issues publicly before they are addressed.

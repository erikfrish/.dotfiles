#!/usr/bin/env python3
"""OpenAI-compatible speech-to-text server backed by NVIDIA Parakeet TDT v3.

Serves POST /v1/audio/transcriptions (multipart form-data) and GET /health.
Runs on CPU via sherpa-onnx; no GPU, no VRAM.

Model files (encoder/decoder/joiner .onnx + tokens.txt) live in
~/.local/share/stt-server/models/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8.
"""

import os
import threading
import wave

import numpy as np
import sherpa_onnx
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import JSONResponse

HOST = os.environ.get("STT_HOST", "127.0.0.1")
PORT = int(os.environ.get("STT_PORT", "8001"))
MODEL_DIR = os.environ.get(
    "STT_MODEL_DIR",
    os.path.expanduser(
        "~/.local/share/stt-server/models/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8"
    ),
)
NUM_THREADS = int(os.environ.get("STT_NUM_THREADS", "8"))

MODEL_ID = "parakeet-tdt-0.6b-v3-int8"

recognizer = sherpa_onnx.OfflineRecognizer.from_transducer(
    encoder=os.path.join(MODEL_DIR, "encoder.int8.onnx"),
    decoder=os.path.join(MODEL_DIR, "decoder.int8.onnx"),
    joiner=os.path.join(MODEL_DIR, "joiner.int8.onnx"),
    tokens=os.path.join(MODEL_DIR, "tokens.txt"),
    num_threads=NUM_THREADS,
    decoding_method="greedy_search",
    model_type="nemo_transducer",
)

_decode_lock = threading.Lock()


def read_wav(data: bytes) -> tuple[np.ndarray, int]:
    import io

    with wave.open(io.BytesIO(data), "rb") as w:
        rate = w.getframerate()
        channels = w.getnchannels()
        width = w.getsampwidth()
        if width != 2:
            raise ValueError(f"Unsupported WAV sample width {width}; expected 16-bit PCM")
        frames = w.getnframes()
        raw = w.readframes(frames)
        samples = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
        if channels > 1:
            samples = samples.reshape(-1, channels).mean(axis=1)
    return samples, rate


def transcribe(data: bytes) -> str:
    samples, rate = read_wav(data)
    if samples.size == 0:
        return ""
    stream = recognizer.create_stream()
    stream.accept_waveform(rate, samples)
    with _decode_lock:
        recognizer.decode_stream(stream)
    return (stream.result.text or "").strip()


app = FastAPI()


@app.get("/health")
def health():
    return JSONResponse({"status": "ok"})


@app.post("/v1/audio/transcriptions")
async def transcriptions(
    file: UploadFile = File(...),
    model: str = Form(MODEL_ID),
    language: str = Form(""),
    response_format: str = Form("json"),
    prompt: str = Form(""),
):
    del model, language, response_format, prompt  # single model; auto-detect language
    audio = await file.read()
    try:
        text = transcribe(audio)
    except ValueError as exc:
        return JSONResponse({"error": str(exc)}, status_code=400)
    return {"text": text}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host=HOST, port=PORT, log_level="info")

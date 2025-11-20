#!/usr/bin/env bash
set -e

# Ensure we are in the project root (one level up from scripts/)
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# Define the submodule path
KOKORO_DIR="external/Kokoro-FastAPI"

# Create virtual environment if it doesn't exist (in the root)
if [ ! -d ".venv-kokoro" ]; then
    echo "Creating virtual environment in .venv-kokoro..."
    uv venv .venv-kokoro
fi

# Activate virtual environment
source .venv-kokoro/bin/activate

# Navigate to the submodule
if [ ! -d "$KOKORO_DIR" ]; then
    echo "Error: Directory $KOKORO_DIR not found!"
    exit 1
fi
cd "$KOKORO_DIR"

# Set environment variables for Kokoro
# The original script used PWD, which is now the submodule dir
export USE_GPU=true
export USE_ONNX=false
export PYTHONPATH=$(pwd):$(pwd)/api
export MODEL_DIR=src/models
export VOICES_DIR=src/voices/v1_0
export WEB_PLAYER_PATH=$(pwd)/web

echo "Installing dependencies..."
uv pip install -e ".[gpu]"

echo "Downloading models..."
python docker/scripts/download_model.py --output api/src/models/v1_0

echo "Starting Kokoro FastAPI..."
uvicorn api.src.main:app --host 0.0.0.0 --port 8880

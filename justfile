# Configuration
cmake_flags := '-DGGML_CUDA=ON -DGGML_BLAS=ON -DGGML_NATIVE=ON -DCMAKE_CUDA_ARCHITECTURES="86"'
build_release := "cmake --build build --config Release -j 24"

# Aliases
alias b := build
alias r := rebuild
alias s := sync
alias c := clean

default:
    @just --list

# ==========================================
# Aggregate Commands
# ==========================================

# Build all projects from scratch
build: build-llama build-ik build-ollama

# Rebuild all projects incrementally
rebuild: rebuild-llama rebuild-ik rebuild-ollama

# Update all repositories (git pull)
sync: sync-llama sync-ik sync-ollama sync-kokoro sync-agent-cli

# Clean all build artifacts
clean: clean-llama clean-ik clean-ollama

# ==========================================
# Agent CLI
# ==========================================

sync-agent-cli:
    cd external/agent-cli && git checkout main && git pull origin main

# ==========================================
# Kokoro TTS
# ==========================================

# Start the Kokoro FastAPI server (GPU)
start-kokoro:
    nix-shell --run ./scripts/start-kokoro.sh

sync-kokoro:
    cd external/Kokoro-FastAPI && git checkout master && git pull origin master

# ==========================================
# Faster Whisper
# ==========================================

# Start the faster-whisper server (GPU)
start-faster-whisper:
    nix-shell --run "uv run --script external/agent-cli/scripts/run_faster_whisper_server.py --device cuda --compute-type float16"

# ==========================================
# llama.cpp
# ==========================================

build-llama:
    cd external/llama.cpp && cmake -B build {{cmake_flags}} && {{build_release}}

rebuild-llama:
    cd external/llama.cpp && {{build_release}}

clean-llama:
    rm -rf external/llama.cpp/build

sync-llama:
    cd external/llama.cpp && git checkout master && git pull origin master

# ==========================================
# ik_llama.cpp
# ==========================================

build-ik:
    cd external/ik_llama.cpp && cmake -B build {{cmake_flags}} && {{build_release}}

rebuild-ik:
    cd external/ik_llama.cpp && {{build_release}}

clean-ik:
    rm -rf external/ik_llama.cpp/build

sync-ik:
    cd external/ik_llama.cpp && git checkout main && git pull origin main

# ==========================================
# Ollama
# ==========================================

build-ollama:
    cd external/ollama && cmake -B build -DGGML_BLAS=ON -DGGML_NATIVE=ON -DCMAKE_CUDA_ARCHITECTURES="86" -DGGML_BLAS_VENDOR=OpenBLAS && {{build_release}} && go build .

rebuild-ollama:
    cd external/ollama && {{build_release}} && go build .

clean-ollama:
    rm -rf external/ollama/build external/ollama/ollama

sync-ollama:
    cd external/ollama && git checkout main && git pull origin main
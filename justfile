# Configuration
cmake_flags := '-DGGML_CUDA=ON -DGGML_BLAS=ON -DGGML_NATIVE=ON -DCMAKE_CUDA_ARCHITECTURES="86"'
build_release := "cmake --build build --config Release -j 24"

# Aliases
alias b := build
alias r := rebuild
alias s := sync
alias c := clean
alias cs := commit-submodules

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

# Commit submodule updates after sync
commit-submodules:
    #!/usr/bin/env bash
    set -euo pipefail
    if git diff --cached --quiet && git diff-files --quiet external/; then
        echo "No submodule changes to commit"
        exit 0
    fi
    git add external/
    updated_modules=$(git diff --cached --name-only | grep '^external/' | cut -d'/' -f2 | sort -u | paste -sd', ')
    # Get info only for updated submodules
    submodule_info=""
    for module in $(echo "$updated_modules" | tr ',' ' '); do
        commit_hash=$(git submodule status "external/$module" | awk '{print substr($1, 1, 8)}')
        submodule_info="${submodule_info}- external/$module @ $commit_hash"$'\n'
    done
    commit_msg=$(cat <<EOF
    chore: update submodules - ${updated_modules}

    Updated submodules to latest versions:
    ${submodule_info}
    EOF
    )
    git commit -m "${commit_msg}"

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
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
build: build-llama build-ik build-ollama install-bin

# Rebuild all projects incrementally
rebuild: rebuild-llama rebuild-ik rebuild-ollama install-bin

# Update all repositories (git pull)
sync: sync-llama sync-ik sync-ollama sync-kokoro sync-agent-cli sync-comfyui

# Clean all build artifacts
clean: clean-llama clean-ik clean-ollama
	rm -rf bin/

# Commit submodule updates after sync
commit-submodules:
    #!/usr/bin/env bash
    set -euo pipefail
    git add external/
    if git diff --cached --quiet -- external/; then
        echo "No submodule changes to commit"
        exit 0
    fi
    modules=$(git diff --cached --name-only -- external/ | xargs -n1 basename | paste -sd, -)
    git commit -m "chore: update submodules - $modules"

# ==========================================
# Helpers
# ==========================================

install-bin:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p bin
    echo "Linking binaries to bin/..."

    # Clean up old binaries/libraries
    rm -rf bin/*

    # Common exclusions for libraries
    EXCLUDE="-E *.so -E *.so.* -E *.dylib -E *.dll -E *.a"

    # Link llama.cpp binaries (standard names)
    fd --type x --absolute-path $EXCLUDE . external/llama.cpp/build/bin --exec ln -sf {} bin/ 2>/dev/null || true

    # Link ik_llama.cpp binaries (prefixed with ik-)
    fd --type x --absolute-path $EXCLUDE . external/ik_llama.cpp/build/bin 2>/dev/null | while read -r file; do
        ln -sf "$file" "bin/ik-$(basename "$file")"
    done || true

    # Link Ollama binary
    fd --type x --absolute-path --max-depth 1 ollama external/ollama --exec ln -sf {} bin/ 2>/dev/null || true


# ==========================================
# Agent CLI
# ==========================================

sync-agent-cli:
    cd external/agent-cli && git checkout main && git pull --ff-only origin main

# ==========================================
# Kokoro TTS
# ==========================================

# Start the Kokoro FastAPI server (GPU)
start-kokoro port="8880":
    nix-shell --run "./scripts/start-kokoro.sh {{port}}"

sync-kokoro:
    cd external/Kokoro-FastAPI && git checkout master && git pull --ff-only origin master

# ==========================================
# Faster Whisper
# ==========================================

# Install the faster-whisper server without changing upstream's lockfile
install-faster-whisper:
    uv venv --allow-existing external/agent-cli/.venv --python 3.12
    uv pip install --python external/agent-cli/.venv/bin/python --upgrade -e 'external/agent-cli[faster-whisper]'

# Start the faster-whisper HTTP server (GPU)
start-faster-whisper port="8811" model="large-v3":
    nix-shell --run "uv run --no-sync --project external/agent-cli agent-cli server whisper --device cuda --compute-type float16 --port {{port}} --model {{model}} --cache-dir external/agent-cli/.venv/model-cache --no-wyoming"

# ==========================================
# llama.cpp
# ==========================================

build-llama:
    cd external/llama.cpp && cmake --fresh -B build {{cmake_flags}} && {{build_release}}

rebuild-llama:
    cd external/llama.cpp && {{build_release}}

clean-llama:
    rm -rf external/llama.cpp/build

sync-llama:
    cd external/llama.cpp && git checkout master && git pull --ff-only origin master

# ==========================================
# ik_llama.cpp
# ==========================================

build-ik:
    cd external/ik_llama.cpp && cmake --fresh -B build {{cmake_flags}} && {{build_release}}

rebuild-ik:
    cd external/ik_llama.cpp && {{build_release}}

clean-ik:
    rm -rf external/ik_llama.cpp/build

sync-ik:
    cd external/ik_llama.cpp && git checkout main && git pull --ff-only origin main

# ==========================================
# Ollama
# ==========================================

build-ollama:
    cd external/ollama && cmake --fresh -B build -DOLLAMA_LLAMA_BACKENDS=cuda_v12 -DCMAKE_CUDA_ARCHITECTURES=86 -DOLLAMA_VERSION="$(git describe --tags --always)" && {{build_release}}

rebuild-ollama:
    cd external/ollama && {{build_release}}

clean-ollama:
    rm -rf external/ollama/build external/ollama/ollama

sync-ollama:
    cd external/ollama && git checkout main && git pull --ff-only origin main

# ==========================================
# ComfyUI
# ==========================================

# Install ComfyUI environment and dependencies
install-comfyui:
    #!/usr/bin/env bash
    set -e
    echo "Installing ComfyUI dependencies..."
    cd external/ComfyUI
    
    # Ensure Manager is present before installing requirements
    if [ ! -d custom_nodes/comfyui-manager ]; then
        echo "Cloning ComfyUI Manager..."
        git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/comfyui-manager
    fi

    if [ ! -d .venv-comfyui ]; then uv venv .venv-comfyui -p 3.12; fi
    source .venv-comfyui/bin/activate
    uv pip install pip  # Ensure pip is installed for nodes that call it via subprocess
    uv pip install huggingface_hub  # Required for authenticated downloads
    uv pip install opencv-python-headless  # Avoid X11 dependencies and runtime reinstalls
    uv pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128
    uv pip install --no-build-isolation sageattention  # Used by ComfyUI-WanVideoWrapper
    uv pip install -r requirements.txt
    uv pip install -r custom_nodes/comfyui-manager/requirements.txt
    echo "ComfyUI installation complete in .venv-comfyui."

# Login to Hugging Face (for downloading restricted models)
login-hf:
    @echo "Please paste your Hugging Face token when prompted."
    @source external/ComfyUI/.venv-comfyui/bin/activate && huggingface-cli login

# Start ComfyUI server
start-comfyui port="8188":
    @echo "Starting ComfyUI..."
    nix-shell --run "cd external/ComfyUI && uv run --no-project --python .venv-comfyui/bin/python python main.py --listen --port {{port}}"

# Update ComfyUI and Manager
sync-comfyui:
    #!/usr/bin/env bash
    set -e
    cd external/ComfyUI
    git checkout master && git pull --ff-only origin master
    if [ -d custom_nodes/comfyui-manager ]; then
        echo "Updating ComfyUI Manager..."
        cd custom_nodes/comfyui-manager && git checkout main && git pull --ff-only origin main
    else
        echo "Cloning ComfyUI Manager..."
        git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/comfyui-manager
    fi

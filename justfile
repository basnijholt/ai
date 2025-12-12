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
    @mkdir -p bin
    @echo "Linking binaries to bin/..."
    # Link C++ binaries (llama.cpp, ik_llama.cpp)
    @fd --type x --absolute-path . external/{llama,ik_llama}.cpp/build/bin --exec ln -sf {} bin/ 2>/dev/null || true
    # Link Ollama binary
    @fd --type x --absolute-path --max-depth 1 ollama external/ollama --exec ln -sf {} bin/ 2>/dev/null || true


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
start-comfyui:
    @echo "Starting ComfyUI..."
    cd external/ComfyUI && source .venv-comfyui/bin/activate && python main.py --listen

# Update ComfyUI and Manager
sync-comfyui:
    #!/usr/bin/env bash
    set -e
    cd external/ComfyUI
    git checkout master && git pull origin master
    if [ -d custom_nodes/comfyui-manager ]; then
        echo "Updating ComfyUI Manager..."
        cd custom_nodes/comfyui-manager && git checkout main && git pull origin main
    else
        echo "Cloning ComfyUI Manager..."
        git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/comfyui-manager
    fi

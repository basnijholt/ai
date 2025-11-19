# AI Lab Workspace

This repository serves as a **meta-workspace** for managing, building, and running various local AI tools and inference engines. It centralizes dependencies using [Nix](https://nixos.org/) and orchestrates tasks using [Just](https://github.com/casey/just).

The goal is to provide a reproducible, one-click setup for compiling high-performance inference backends (like `llama.cpp`) and running services (like TTS and ASR) without managing individual environments for each submodule.

## 📂 Included Projects

All external projects are managed as git submodules in the `external/` directory:

*   **[llama.cpp](https://github.com/ggerganov/llama.cpp):** Inference of LLaMA model in pure C/C++.
*   **[ik_llama.cpp](https://github.com/ikawrakow/ik_llama.cpp):** A fork of llama.cpp with optimizations.
*   **[Ollama](https://github.com/ollama/ollama):** Get up and running with large language models.
*   **[Kokoro-FastAPI](https://github.com/remsky/Kokoro-FastAPI):** A Dockerized/FastAPI wrapper for the Kokoro TTS model.
*   **[agent-cli](https://github.com/basnijholt/agent-cli):** CLI agent tool (used here for its `faster-whisper` server script).

## 🛠️ Prerequisites

*   **[Nix](https://nixos.org/download.html):** Required for the environment.
*   **[Direnv](https://direnv.net/)** (Recommended): Automatically loads the Nix environment when you enter the directory.
*   **Git:** To manage the repository and submodules.

## 🚀 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone --recursive git@github.com:basnijholt/ai.git
    cd ai
    ```

2.  **Enter the environment:**
    If you have `direnv` installed:
    ```bash
    direnv allow
    ```
    Otherwise, drop into the Nix shell manually:
    ```bash
    nix-shell
    ```
    *This provides `cmake`, `gcc`, `go`, `cuda`, `python`, `uv`, and `just` configured specifically for these projects.*

3.  **Build everything:**
    ```bash
    just build
    ```

## 🤖 Commands

The `justfile` defines all available commands.

### Global Operations
| Command | Alias | Description |
| :--- | :--- | :--- |
| `just build` | `just b` | Compiles `llama.cpp`, `ik_llama.cpp`, and `ollama` from scratch. |
| `just rebuild` | `just r` | Incrementally recompiles all projects. |
| `just sync` | `just s` | Pulls the latest changes for **all** submodules from their upstream remotes. |
| `just clean` | `just c` | Removes build artifacts for all projects. |

### Running Services
| Command | Description |
| :--- | :--- |
| `just start-kokoro` | Starts the **Kokoro TTS** server (GPU accelerated). <br> *Automatically handles python venv and model downloads.* |
| `just start-faster-whisper` | Starts the **Faster Whisper** ASR server on port 8811 (CUDA, float16). |

### Individual Project Commands
You can also target specific projects:

*   **llama.cpp:** `build-llama`, `rebuild-llama`, `clean-llama`, `sync-llama`
*   **ik_llama.cpp:** `build-ik`, `rebuild-ik`, `clean-ik`, `sync-ik`
*   **Ollama:** `build-ollama`, `rebuild-ollama`, `clean-ollama`, `sync-ollama`
*   **Kokoro:** `sync-kokoro`
*   **Agent CLI:** `sync-agent-cli`

## ⚙️ Configuration

> [!NOTE]
> This setup is specifically tailored for a machine with **NVIDIA CUDA-compatible hardware**.

*   **Build Flags:** Configured in `justfile`. These include flags for CUDA support and hardware-specific architectures (e.g., targeting NVIDIA GPUs).
*   **Environment:** Defined in `shell.nix`. It ensures `LD_LIBRARY_PATH` includes necessary CUDA and C++ libraries for Python extensions.

## 🖥️ System Configuration

My complete NixOS configuration, which powers this setup, can be found in my [dotfiles](https://github.com/basnijholt/dotfiles).

## 📝 License

This meta-repository is for personal organization. Each submodule retains its own license.

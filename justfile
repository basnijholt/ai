default:
    @just --list

# --- All ---

build: build-llama-cpp build-ik build-ollama
rebuild: rebuild-llama-cpp rebuild-ik rebuild-ollama
sync: sync-llama-cpp sync-ik sync-ollama
clean: clean-llama-cpp clean-ik clean-ollama

# --- llama.cpp ---

build-llama-cpp:
    cd llama.cpp && cmake -B build -DGGML_CUDA=ON -DGGML_BLAS=ON -DGGML_NATIVE=ON -DCMAKE_CUDA_ARCHITECTURES="86" && cmake --build build --config Release -j 24

rebuild-llama-cpp:
    cd llama.cpp && cmake --build build --config Release -j 24

clean-llama-cpp:
    rm -rf llama.cpp/build

sync-llama-cpp:
    cd llama.cpp && git checkout master && git pull origin master

# --- ik_llama.cpp ---

build-ik:
    cd ik_llama.cpp && cmake -B build -DGGML_CUDA=ON -DGGML_BLAS=ON -DGGML_NATIVE=ON -DCMAKE_CUDA_ARCHITECTURES="86" && cmake --build build --config Release -j 24

rebuild-ik:
    cd ik_llama.cpp && cmake --build build --config Release -j 24

clean-ik:
    rm -rf ik_llama.cpp/build

sync-ik:
    cd ik_llama.cpp && git checkout main && git pull origin main

# --- Ollama ---

build-ollama:
    cd ollama && cmake -B build -DGGML_CUDA=ON -DGGML_BLAS=ON -DGGML_NATIVE=ON -DCMAKE_CUDA_ARCHITECTURES="86" && cmake --build build --config Release -j 24 && go build .

rebuild-ollama:
    cd ollama && cmake --build build --config Release -j 24 && go build .

clean-ollama:
    rm -rf ollama/build ollama/ollama

sync-ollama:
    cd ollama && git checkout main && git pull origin main

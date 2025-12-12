{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

pkgs.mkShell {
  name = "ai-lab-env";
  
  # Allow building with -march=native
  NIX_ENFORCE_NO_NATIVE = "0";

  buildInputs = with pkgs; [
    # Build tools
    cmake
    ninja
    pkg-config
    just

    # Compilers
    gcc
    go

    # Python & Tools
    python312
    uv
    cacert
    espeak-ng  # Required for Kokoro TTS

    # CUDA packages
    cudaPackages.cudatoolkit
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
    cudaPackages.libcublas
    cudaPackages.cudnn

    # System libraries (ComfyUI & others)
    stdenv.cc.cc.lib
    zlib
    libGL
    glib
    openssl
    glibc.bin  # Provides ldconfig for Triton

    # Optional dependencies
    curl
    openblas
    ccache
    fd
    ripgrep
  ];

  shellHook = ''
    # CUDA Environment
    export CUDA_PATH="${pkgs.cudaPackages.cudatoolkit}"
    export CUDA_HOME="${pkgs.cudaPackages.cudatoolkit}"
    export CUDA_TOOLKIT_ROOT_DIR="${pkgs.cudaPackages.cudatoolkit}"
    export CMAKE_CUDA_COMPILER="${pkgs.cudaPackages.cuda_nvcc}/bin/nvcc"
    
    # Setup library paths
    export LD_LIBRARY_PATH=${
      pkgs.lib.makeLibraryPath [
        "/run/opengl-driver"
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.cudaPackages.cudatoolkit
        pkgs.cudaPackages.cuda_cudart
        pkgs.cudaPackages.cudnn
        pkgs.libGL
        pkgs.glib.out
        pkgs.xorg.libX11
        pkgs.xorg.libXext
        pkgs.xorg.libXrender
        pkgs.xorg.libICE
        pkgs.xorg.libSM
        pkgs.openssl
      ]
    }:$LD_LIBRARY_PATH

    export LIBRARY_PATH=${
      pkgs.lib.makeLibraryPath [
        pkgs.cudaPackages.cudatoolkit
        pkgs.cudaPackages.cuda_cudart
        pkgs.zlib
        pkgs.openssl
      ]
    }:/run/opengl-driver/lib:$LIBRARY_PATH

    export PATH="${pkgs.cudaPackages.cuda_nvcc}/bin:${pkgs.glibc.bin}/bin:$PATH"

    # SSL Certificate for Python/uv
    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

    # Tell Triton where to find libcuda.so (avoids calling /sbin/ldconfig on NixOS)
    export TRITON_LIBCUDA_PATH=/run/opengl-driver/lib

    echo "Environment loaded. Use 'just' to run commands."
    echo "TRITON_LIBCUDA_PATH: $TRITON_LIBCUDA_PATH"
  '';
}
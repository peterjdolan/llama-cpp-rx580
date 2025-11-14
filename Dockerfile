# === STAGE 1: The Builder ===
# Use a minimal, stable Debian release
FROM debian:bookworm-slim AS builder

# 1. Install all build dependencies
# --- ADDED shaderc ---
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    cmake \
    curl \
    libcurl4-openssl-dev \
    libvulkan-dev \
    libshaderc-dev \
    glslc \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. Clone and compile llama.cpp with Vulkan enabled
WORKDIR /app
RUN git clone https://github.com/ggml-org/llama.cpp . && \
    mkdir build && \
    cd build && \
    cmake .. -DGGML_VULKAN=ON -DCMAKE_BUILD_TYPE=Release && \
    cmake --build . --config Release -j $(nproc)

# 3. Download the model
WORKDIR /models

# Qwen-VL model (text-only mode, no vision capabilities)
RUN curl -L -f -O https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF/resolve/main/Qwen3VL-8B-Instruct-Q4_K_M.gguf

# === STAGE 2: The Final Image ===
# Start from the same minimal Debian base
FROM debian:bookworm-slim

# 1. Install *only* the runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libvulkan1 \
    mesa-vulkan-drivers \
    libcurl4 \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy the compiled binaries from the builder stage
COPY --from=builder /app/build/bin /app/bin

# 3. Set library path so binaries can find the shared libraries
ENV LD_LIBRARY_PATH=/app/bin

# 4. Copy all downloaded models from the builder stage
COPY --from=builder /models /models

# 5. Set the working directory
WORKDIR /app

# 6. Expose the server port
EXPOSE 8080

# 7. Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 8. Set the default command to run the llama-server
CMD [ \
    "/app/bin/llama-server", \
    "-m", "/models/Qwen3VL-8B-Instruct-Q4_K_M.gguf", \
    "--ctx-size", "32768", \
    "--n-gpu-layers", "99", \
    "--flash-attn", "on", \
    "--metrics", \
    "--jinja", \
    "--batch-size", "1024", \
    "--ubatch-size", "512", \
    "--host", "0.0.0.0", \
    "--port", "8080" \
]
ARG PYTHON_VERSION=3.11
ARG CUDA_VERSION=12.9.0

# ==================================================================================================
# Builder Stage
# ==================================================================================================
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu22.04 AS builder

ARG PYTHON_VERSION
ENV DEBIAN_FRONTEND=noninteractive

# Install build-time dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
    build-essential \
    pkg-config \
    cmake \
    ninja-build \
    libopenblas-dev \
    liblapack-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set Python version
RUN ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python && \
    ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3

WORKDIR /app

# Clone ComfyUI first, into the current directory
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# Create and activate virtual environment inside the app directory
RUN python -m venv venv
ENV PATH="/app/venv/bin:$PATH"

# Upgrade pip inside the venv
RUN pip install --upgrade pip

# Copy custom node list and installation scripts
COPY custom_nodes.txt /app/
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Clone custom nodes
RUN /app/scripts/install_custom_nodes.sh /app/custom_nodes.txt

# Generate and install requirements
# Note: gather_requirements.py should be run from the /app directory
RUN python /app/scripts/gather_requirements.py

# Install Torch, xformers and other dependencies
# Using venv's pip
RUN pip install --no-cache-dir torch==2.6.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 --extra-index-url https://pypi.org/simple
RUN pip install --no-cache-dir xformers==0.0.29.post3
RUN /app/scripts/install_packages.sh


# ==================================================================================================
# Runtime Stage
# ==================================================================================================
FROM nvidia/cuda:${CUDA_VERSION}-base-ubuntu22.04

ARG PYTHON_VERSION
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    wget \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-venv \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the application with the venv from the builder stage
COPY --from=builder /app /app

# Copy the entrypoint script
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# Set environment variables
ENV PATH="/app/venv/bin:$PATH"

# Create directories for models and outputs
RUN mkdir -p /app/models /app/output

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Default port
EXPOSE 8188

# Command to run ComfyUI
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--enable-cors-header"] 
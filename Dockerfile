ARG PYTHON_VERSION=3.11
ARG CUDA_VERSION=12.9.0
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu22.04

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    python3-setuptools \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    ffmpeg \
    build-essential \
    pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set Python version
RUN ln -sf /usr/bin/python3.11 /usr/bin/python && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3

# Set working directory
WORKDIR /app

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app

# Clone required custom nodes
RUN mkdir -p /app/custom_nodes && \
    cd /app/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone https://github.com/cubiq/ComfyUI_essentials.git && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    git clone https://github.com/rgthree/rgthree-comfy.git

# Copy scripts
COPY scripts/gather_requirements.py /app/scripts/
RUN mkdir -p /app/scripts

# Run the requirement gathering script
RUN cd /app && python3.11 /app/scripts/gather_requirements.py

# Install Python dependencies
RUN python3.11 -m pip install --no-cache-dir -r /app/requirements.txt

# Install Torch with CUDA support and xformers
RUN python3.11 -m pip install --no-cache-dir xformers==0.0.29.post3 torch==2.6.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 --extra-index-url https://pypi.org/simple

# Set environment variables
ENV PYTHONPATH=/app
ENV PATH="/app:${PATH}"

# Copy the entrypoint script
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# Create directories for models and outputs
RUN mkdir -p /app/models /app/output

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Default port
EXPOSE 8188

# Command
CMD ["python3.11", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--enable-cors-header"] 
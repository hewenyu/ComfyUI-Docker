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
    cmake \
    ninja-build \
    libopenblas-dev \
    liblapack-dev \
    libx11-dev \
    libgtk-3-dev \
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
    git clone https://github.com/rgthree/rgthree-comfy.git && \
    git clone https://github.com/crystian/ComfyUI-Crystools.git && \
    git clone https://github.com/cubiq/ComfyUI_FaceAnalysis.git && \
    git clone https://github.com/cubiq/ComfyUI_InstantID.git && \
    git clone https://github.com/cubiq/PuLID_ComfyUI.git && \
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && \
    git clone https://github.com/FizzleDorf/ComfyUI_FizzNodes.git && \
    git clone https://github.com/Gourieff/ComfyUI-ReActor.git && \
    git clone https://github.com/huchenlei/ComfyUI-layerdiffuse.git && \
    git clone https://github.com/jags111/efficiency-nodes-comfyui.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git && \
    git clone https://github.com/melMass/comfy_mtb.git && \
    git clone https://github.com/storyicon/comfyui_segment_anything.git && \
    git clone https://github.com/WASasquatch/was-node-suite-comfyui.git && \
    git clone https://github.com/chflame163/ComfyUI_LayerStyle.git && \
    git clone https://github.com/chflame163/ComfyUI_LayerStyle_Advance.git && \
    git clone https://github.com/shadowcz007/comfyui-mixlab-nodes.git && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone https://github.com/kijai/ComfyUI-IC-Light.git && \
    git clone https://github.com/siliconflow/BizyAir.git && \
    git clone https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch.git && \
    git clone https://github.com/lldacing/comfyui-easyapi-nodes.git

# Copy scripts
COPY scripts/gather_requirements.py /app/scripts/
COPY scripts/problematic_requirements.txt /app/scripts/
COPY scripts/install_packages.sh /app/scripts/
RUN mkdir -p /app/scripts && chmod +x /app/scripts/install_packages.sh

# Run the requirement gathering script
RUN cd /app && python3.11 /app/scripts/gather_requirements.py

# Install Torch with CUDA support and xformers first
RUN python3.11 -m pip install --no-cache-dir torch==2.6.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 --extra-index-url https://pypi.org/simple && \
    python3.11 -m pip install --no-cache-dir xformers==0.0.29.post3

# Install Python dependencies using the installation script
RUN /app/scripts/install_packages.sh

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
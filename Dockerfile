ARG PYTHON_VERSION=3.11
ARG CUDA_VERSION=12.9.0
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu22.04

# 设置非交互式安装
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONPATH=/app
ENV PATH="/app:${PATH}"

# 单层安装所有依赖
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

# 复制所有脚本到容器中
COPY scripts/ /app/scripts/
COPY entrypoint.sh /app/

# 设置脚本可执行权限并执行 debian 环境设置脚本
RUN chmod +x /app/scripts/*.sh /app/entrypoint.sh \
    && /app/scripts/debian_environment_setup.sh

# 默认端口
EXPOSE 8188

# 入口点和命令
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["python3.11", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--enable-cors-header"] 
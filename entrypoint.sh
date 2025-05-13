#!/bin/bash
set -e

# 环境变量默认值
: "${UPDATE_REPOSITORIES:=false}"
: "${DOWNLOAD_EXAMPLE_MODELS:=false}"
: "${FORCE_DOWNLOAD_MODELS:=false}"
: "${REGENERATE_REQUIREMENTS:=false}"
: "${FIX_PERMISSIONS:=true}"

# 确保脚本目录存在
mkdir -p /app/scripts

# 更新仓库函数
update_repositories() {
    echo "更新 ComfyUI..."
    cd /app && git pull

    echo "更新自定义节点..."
    find /app/custom_nodes -maxdepth 1 -mindepth 1 -type d -exec bash -c '
        if [ -d "$0/.git" ]; then
            echo "更新 $(basename $0)..."
            cd "$0" && git pull
        fi
    ' {} \;
}

# 下载模型函数
download_model() {
    local model_url="$1"
    local output_dir="$2"
    local filename=$(basename "$model_url")
    
    if [ ! -f "$output_dir/$filename" ] || [ "${FORCE_DOWNLOAD_MODELS}" = "true" ]; then
        echo "下载 $filename 到 $output_dir..."
        mkdir -p "$output_dir"
        wget -q --show-progress -O "$output_dir/$filename" "$model_url"
    else
        echo "模型 $filename 已存在，跳过下载。"
    fi
}

# 根据环境变量执行相应操作
if [ "${UPDATE_REPOSITORIES}" = "true" ]; then
    update_repositories
fi

if [ "${DOWNLOAD_EXAMPLE_MODELS}" = "true" ]; then
    # SD 1.5 模型
    download_model "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" "/app/models/checkpoints"
    
    # 放大模型
    download_model "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" "/app/models/upscale_models"
    
    # ControlNet 模型
    download_model "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth" "/app/models/controlnet"
    download_model "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_openpose.pth" "/app/models/controlnet"
fi

# 重新生成依赖项
if [ "${REGENERATE_REQUIREMENTS}" = "true" ]; then
    echo "生成 requirements.txt..."
    python3.11 /app/scripts/gather_requirements.py
    python3.11 -m pip install -r /app/requirements.txt
fi

# 运行用户自定义初始化脚本
if [ -f "/app/custom_init.sh" ]; then
    echo "运行自定义初始化脚本..."
    chmod +x /app/custom_init.sh
    /app/custom_init.sh
fi

# 修复文件权限
if [ "${FIX_PERMISSIONS}" = "true" ]; then
    echo "设置适当的权限..."
    find /app -not -user $(id -u) -exec chown -R $(id -u):$(id -g) {} \; 2>/dev/null || true
fi

echo "==================================================="
echo "ComfyUI 正在启动。服务器将在以下地址可用："
echo "http://localhost:8188 (如果端口 8188 已暴露)"
echo "==================================================="

# 执行命令
exec "$@" 
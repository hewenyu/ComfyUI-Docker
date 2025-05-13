#!/bin/bash
set -e

# 环境变量默认值设置
export UPDATE_REPOSITORIES=${UPDATE_REPOSITORIES:-false}
export DOWNLOAD_EXAMPLE_MODELS=${DOWNLOAD_EXAMPLE_MODELS:-false}
export FORCE_DOWNLOAD_MODELS=${FORCE_DOWNLOAD_MODELS:-false}
export REGENERATE_REQUIREMENTS=${REGENERATE_REQUIREMENTS:-false}
export FIX_PERMISSIONS=${FIX_PERMISSIONS:-true}

# 创建必要的目录结构
mkdir -p /app/scripts /app/models /app/output /app/custom_nodes

# 设置 Python 版本
ln -sf /usr/bin/python3.11 /usr/bin/python
ln -sf /usr/bin/python3.11 /usr/bin/python3

echo "开始克隆 ComfyUI 仓库..."
if [ ! -d "/app/.git" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git /app
fi

# 克隆所有自定义节点
echo "克隆自定义节点..."
cd /app/custom_nodes

# 定义要克隆的仓库列表
REPOS=(
    "https://github.com/Comfy-Org/ComfyUI-Manager.git"
    "https://github.com/kijai/ComfyUI-WanVideoWrapper.git"
    "https://github.com/kijai/ComfyUI-KJNodes.git"
    "https://github.com/cubiq/ComfyUI_essentials.git"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git"
    "https://github.com/rgthree/rgthree-comfy.git"
    "https://github.com/crystian/ComfyUI-Crystools.git"
    "https://github.com/cubiq/ComfyUI_FaceAnalysis.git"
    "https://github.com/cubiq/ComfyUI_InstantID.git"
    "https://github.com/cubiq/PuLID_ComfyUI.git"
    "https://github.com/Fannovel16/comfyui_controlnet_aux.git"
    "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git"
    "https://github.com/FizzleDorf/ComfyUI_FizzNodes.git"
    "https://github.com/Gourieff/ComfyUI-ReActor.git"
    "https://github.com/huchenlei/ComfyUI-layerdiffuse.git"
    "https://github.com/jags111/efficiency-nodes-comfyui.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git"
    "https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git"
    "https://github.com/melMass/comfy_mtb.git"
    "https://github.com/storyicon/comfyui_segment_anything.git"
    "https://github.com/WASasquatch/was-node-suite-comfyui.git"
    "https://github.com/chflame163/ComfyUI_LayerStyle.git"
    "https://github.com/chflame163/ComfyUI_LayerStyle_Advance.git"
    "https://github.com/shadowcz007/comfyui-mixlab-nodes.git"
    "https://github.com/yolain/ComfyUI-Easy-Use.git"
    "https://github.com/kijai/ComfyUI-IC-Light.git"
    "https://github.com/siliconflow/BizyAir.git"
    "https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch.git"
    "https://github.com/lldacing/comfyui-easyapi-nodes.git"
)

# 并行克隆仓库以提高效率
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    if [ ! -d "$repo_name" ]; then
        echo "克隆 $repo_name..."
        git clone "$repo" &
    fi
done

# 等待所有后台任务完成
wait
echo "所有自定义节点克隆完成"

# 返回到应用目录
cd /app

# 运行依赖收集脚本
echo "收集依赖项..."
python3.11 /app/scripts/gather_requirements.py

# 安装 PyTorch 和 xformers
echo "安装 PyTorch 和 xformers..."
python3.11 -m pip install --no-cache-dir torch==2.6.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 --extra-index-url https://pypi.org/simple
python3.11 -m pip install --no-cache-dir xformers==0.0.29.post3

# 安装其他 Python 依赖项
echo "安装其他依赖项..."
/app/scripts/install_packages.sh

# 如果需要下载示例模型
if [ "${DOWNLOAD_EXAMPLE_MODELS}" = "true" ]; then
    echo "下载示例模型..."
    
    # 定义下载模型函数
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
    
    # SD 1.5 模型
    download_model "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" "/app/models/checkpoints"
    
    # 放大模型
    download_model "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" "/app/models/upscale_models"
    
    # ControlNet 模型
    download_model "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth" "/app/models/controlnet"
    download_model "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_openpose.pth" "/app/models/controlnet"
fi

# 修复文件权限
if [ "${FIX_PERMISSIONS}" = "true" ]; then
    echo "设置适当的权限..."
    find /app -not -user $(id -u) -exec chown -R $(id -u):$(id -g) {} \; 2>/dev/null || true
fi

echo "Debian 环境设置完成！" 
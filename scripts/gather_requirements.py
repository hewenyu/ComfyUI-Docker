#!/usr/bin/env python3
import os
import re
import sys
import urllib.request
import urllib.error
import tempfile
import pkg_resources

# List of repositories to fetch requirements from
REPO_REQUIREMENTS = [
    "https://github.com/comfyanonymous/ComfyUI/raw/master/requirements.txt",
    "https://github.com/crystian/ComfyUI-Crystools/raw/main/requirements.txt",
    "https://github.com/cubiq/ComfyUI_essentials/raw/main/requirements.txt",
    "https://github.com/cubiq/ComfyUI_FaceAnalysis/raw/main/requirements.txt",
    "https://github.com/cubiq/ComfyUI_InstantID/raw/main/requirements.txt",
    "https://github.com/cubiq/PuLID_ComfyUI/raw/main/requirements.txt",
    "https://github.com/Fannovel16/comfyui_controlnet_aux/raw/main/requirements.txt",
    "https://github.com/Fannovel16/ComfyUI-Frame-Interpolation/raw/main/requirements-no-cupy.txt",
    "https://github.com/FizzleDorf/ComfyUI_FizzNodes/raw/main/requirements.txt",
    "https://github.com/Gourieff/ComfyUI-ReActor/raw/main/requirements.txt",
    "https://github.com/huchenlei/ComfyUI-layerdiffuse/raw/main/requirements.txt",
    "https://github.com/jags111/efficiency-nodes-comfyui/raw/main/requirements.txt",
    "https://github.com/kijai/ComfyUI-KJNodes/raw/main/requirements.txt",
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite/raw/main/requirements.txt",
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack/raw/Main/requirements.txt",
    "https://github.com/ltdrdata/ComfyUI-Impact-Subpack/raw/main/requirements.txt",
    "https://github.com/ltdrdata/ComfyUI-Inspire-Pack/raw/main/requirements.txt",
    "https://github.com/ltdrdata/ComfyUI-Manager/raw/main/requirements.txt",
    "https://github.com/melMass/comfy_mtb/raw/main/requirements.txt",
    "https://github.com/storyicon/comfyui_segment_anything/raw/main/requirements.txt",
    "https://github.com/WASasquatch/was-node-suite-comfyui/raw/main/requirements.txt",
    "https://github.com/kijai/ComfyUI-WanVideoWrapper/raw/main/requirements.txt",
    "https://github.com/chflame163/ComfyUI_LayerStyle/raw/main/requirements.txt",
    "https://github.com/chflame163/ComfyUI_LayerStyle_Advance/raw/main/requirements.txt",
    "https://github.com/shadowcz007/comfyui-mixlab-nodes/raw/main/requirements.txt",
    "https://github.com/yolain/ComfyUI-Easy-Use/raw/main/requirements.txt",
    "https://github.com/kijai/ComfyUI-IC-Light/raw/main/requirements.txt",
    "https://github.com/siliconflow/BizyAir/raw/master/requirements.txt",
    "https://github.com/lldacing/comfyui-easyapi-nodes/raw/master/requirements.txt",
    "https://github.com/kijai/ComfyUI-FluxTrainer/raw/main/requirements.txt",
    "https://github.com/giriss/comfy-image-saver/raw/main/requirements.txt",
    "https://github.com/ShmuelRonen/ComfyUI-LatentSyncWrapper/raw/main/requirements.txt",
    "https://github.com/alexgenovese/ComfyUI_HF_Servelress_Inference/raw/main/requirements.txt",
    "https://github.com/alexopus/ComfyUI-Image-Saver/raw/refs/heads/master/requirements.txt",
    "https://github.com/mingsky-ai/ComfyUI-MingNodes/raw/main/requirements.txt",
    "https://github.com/kijai/ComfyUI-SUPIR/raw/main/requirements.txt",
    "https://github.com/ManglerFTW/ComfyI2I/raw/main/requirements.txt",
    "https://github.com/nullquant/ComfyUI-BrushNet/raw/main/requirements.txt",
    "https://github.com/kadirnar/ComfyUI-YOLO/raw/main/requirements.txt",
    "https://github.com/EvilBT/ComfyUI_SLK_joy_caption_two/raw/main/requirements.txt",
    "https://github.com/stormcenter/ComfyUI-AutoSplitGridImage/raw/main/requirements.txt",
    "https://github.com/lldacing/ComfyUI_PuLID_Flux_ll/raw/main/requirements.txt",
    "https://github.com/welltop-cn/ComfyUI-TeaCache/raw/main/requirements.txt",
    "https://github.com/WaveSpeedAI/wavespeed-comfyui/raw/master/requirements.txt",
    "https://github.com/CY-CHENYUE/ComfyUI-Redux-Prompt/raw/master/requirements.txt",
    "https://github.com/evanspearman/ComfyMath/raw/main/requirements.txt",
    "https://github.com/city96/ComfyUI-GGUF/raw/main/requirements.txt",
    "https://github.com/mit-han-lab/ComfyUI-nunchaku/raw/main/requirements.txt",
    "https://github.com/sipherxyz/comfyui-art-venture/raw/main/requirements.txt",
    "https://github.com/cardenluo/ComfyUI-Apt_Preset/raw/main/requirements.txt",
    "https://github.com/ycyy/ComfyUI-YCYY-InSPyReNet/raw/main/requirements.txt",
    "https://github.com/MoonHugo/ComfyUI-FFmpeg/raw/main/requirements.txt",
]

# Additional packages that might be needed
ADDITIONAL_PACKAGES = [
    "torch==2.6.0",
    "torchvision",
    "torchaudio",
    "xformers==0.0.29.post3",
    "opencv-python==4.8.0.76",
    "opencv-contrib-python==4.8.0.76",
    "sageattention==1.0.6",
    "bizyengine==1.2.4",
]

# Packages to exclude (will be installed separately)
EXCLUDED_PACKAGES = [
    "insightface",
    "dlib",
    "fairscale",
]

def parse_requirement(req_str):
    """Parse a requirement string and return (package_name, specs)"""
    req_str = req_str.strip()
    if not req_str or req_str.startswith('#'):
        return None
    
    try:
        req = pkg_resources.Requirement.parse(req_str)
        return req.name.lower(), req
    except Exception:
        print(f"Warning: Could not parse requirement: {req_str}", file=sys.stderr)
        return None

def fetch_requirements(url):
    """Fetch requirements from a URL"""
    print(f"Fetching requirements from {url}...", file=sys.stderr)
    try:
        with urllib.request.urlopen(url, timeout=10) as response:
            content = response.read().decode('utf-8')
            return content.splitlines()
    except urllib.error.HTTPError as e:
        print(f"Warning: Failed to fetch {url}: {e}", file=sys.stderr)
        return []
    except Exception as e:
        print(f"Warning: Error fetching {url}: {e}", file=sys.stderr)
        return []

def main():
    all_requirements = {}
    
    # Fetch requirements from repositories
    for repo_url in REPO_REQUIREMENTS:
        for line in fetch_requirements(repo_url):
            req = parse_requirement(line)
            if req:
                name, requirement = req
                # Skip excluded packages
                if name in EXCLUDED_PACKAGES:
                    continue
                # Keep the most specific version if the package already exists
                if name in all_requirements:
                    # For simplicity, just take the newer requirement
                    # A more sophisticated approach would compare version specs
                    continue
                all_requirements[name] = requirement
    
    # Add additional packages
    for pkg in ADDITIONAL_PACKAGES:
        req = parse_requirement(pkg)
        if req:
            name, requirement = req
            if name not in EXCLUDED_PACKAGES:
                all_requirements[name] = requirement
    
    # Output final requirements
    with open("requirements.txt", "w") as f:
        for name in sorted(all_requirements.keys()):
            f.write(f"{all_requirements[name]}\n")
    
    print(f"Successfully gathered {len(all_requirements)} packages in requirements.txt", file=sys.stderr)

if __name__ == "__main__":
    main() 

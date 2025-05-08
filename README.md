# ComfyUI Docker Build System

This repository contains a GitHub Actions workflow and scripts to automatically build and publish a comprehensive ComfyUI Docker image with various popular custom nodes pre-installed.

## Features

- Uses Debian as the base image
- Python 3.11 and CUDA 12.1 support
- Automatic versioning using ComfyUI's version as the tag
- Installs popular custom nodes:
  - ComfyUI-Manager
  - ComfyUI-WanVideoWrapper
  - ComfyUI-KJNodes
  - ComfyUI_essentials
  - ComfyUI-VideoHelperSuite
  - ComfyUI_Comfyroll_CustomNodes
  - rgthree-comfy
- Automatically detects and installs dependencies from all custom nodes
- Scripts for automatic package deduplication and installation

## Docker Images

The Docker images are published to [Docker Hub](https://hub.docker.com/r/hewenyulucky/comfyui) with the following tags:

- `hewenyulucky/comfyui:latest` - Latest build
- `hewenyulucky/comfyui:<version>` - Specific ComfyUI version

## Usage

### Basic Usage

```bash
docker run -it --gpus all -p 8188:8188 -v /path/to/models:/app/models hewenyulucky/comfyui:latest
```

### With Persistent Storage

```bash
docker run -it --gpus all \
  -p 8188:8188 \
  -v /path/to/models:/app/models \
  -v /path/to/outputs:/app/output \
  hewenyulucky/comfyui:latest
```

### Environment Variables

The container supports the following environment variables:

- `UPDATE_REPOSITORIES` (default: "false") - Update ComfyUI and custom nodes on startup
- `DOWNLOAD_EXAMPLE_MODELS` (default: "false") - Download basic example models if they don't exist
- `FORCE_DOWNLOAD_MODELS` (default: "false") - Force download of example models even if they exist
- `REGENERATE_REQUIREMENTS` (default: "false") - Force regeneration of requirements.txt and reinstall
- `FIX_PERMISSIONS` (default: "true") - Fix permissions of all files on startup

Example:

```bash
docker run -it --gpus all \
  -p 8188:8188 \
  -e UPDATE_REPOSITORIES=true \
  -e DOWNLOAD_EXAMPLE_MODELS=true \
  -v /path/to/models:/app/models \
  hewenyulucky/comfyui:latest
```

## Building Locally

To build the Docker image locally:

```bash
git clone https://github.com/yourusername/ComfyUI-Docker.git
cd ComfyUI-Docker
docker build -t comfyui:local .
```

## GitHub Actions Workflow

The GitHub Actions workflow in this repository will:

1. Trigger on manual dispatch, weekly schedule, or when changes are pushed to the main branch
2. Build the Docker image
3. Get the latest ComfyUI version
4. Push the image to Docker Hub with the ComfyUI version and 'latest' tags

## License

See the [LICENSE](LICENSE) file for details. 
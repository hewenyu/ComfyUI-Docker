# ComfyUI Docker (中文版)

这是一个经过优化的 Docker 项目，用于运行 [ComfyUI](https://github.com/comfyanonymous/ComfyUI)。它通过将自定义节点列表外部化管理，并采用多阶段构建，提供了一个灵活、高效且易于维护的 ComfyUI 环境。

## ✨ 特性

- **动态节点管理**: 只需修改 `custom_nodes.txt` 文件即可轻松添加或移除自定义节点，无需重建整个基础环境。
- **多阶段构建**: 使用 Docker 的多阶段构建功能，分离了构建环境和运行时环境，显著减小了最终镜像的体积。
- **依赖自动解析**: 自动扫描所有自定义节点下的 `requirements.txt` 文件，并整合所有 Python 依赖。
- **配置集中化**: 对"问题依赖包"的管理同样通过 `scripts/problematic_requirements.txt` 文件进行，避免了硬编码。
- **易于部署**: 提供了 `docker-compose.yml`，一键即可启动和管理服务。
- **国内用户优化**: 内置 `HF_ENDPOINT` 环境变量，方便用户切换到 Hugging Face 国内镜像源。

## 🚀 快速开始

我们强烈推荐使用 Docker Compose 来管理此应用。

### 1. 先决条件

- [Docker](https://www.docker.com/get-started)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) (用于 GPU 支持)
- `docker-compose` (通常随 Docker Desktop 一同安装)

### 2. 准备目录

在您的主机上创建 `models` 和 `output` 目录，用于持久化存储数据。

```bash
mkdir models
mkdir output
```

### 3. 配置 (可选)

- **自定义节点**: 编辑 `custom_nodes.txt` 文件，添加或删除您需要的 ComfyUI 自定义节点的 Git 仓库 URL。
- **Hugging Face 镜像**: 如果您在中国大陆，建议创建一个 `.env` 文件来配置 Hugging Face 镜像，以加速模型下载。

  ```bash
  # .env 文件内容
  HF_ENDPOINT=https://hf-mirror.com
  ```
  `docker-compose` 会自动加载此文件。

### 4. 构建并启动

在项目根目录下运行以下命令：

```bash
docker-compose up --build
```

此命令会：
1.  构建 Docker 镜像 (如果尚未构建或有改动)。
2.  创建并启动 `comfyui` 服务容器。
3.  将本地的 `models` 和 `output` 目录挂载到容器中。

服务启动后，您可以通过浏览器访问 `http://localhost:8188` 来使用 ComfyUI。

### 5. 停止服务

```bash
docker-compose down
```

## 📁 目录结构

```
.
├── Dockerfile                  # 核心构建文件
├── docker-compose.yml          # Docker Compose 配置文件
├── custom_nodes.txt            # 自定义节点 Git 仓库列表
├── entrypoint.sh               # 容器入口脚本
├── README.md                   # 本文档
└── scripts/
    ├── gather_requirements.py      # 自动收集 Python 依赖
    ├── install_custom_nodes.sh     # 安装 custom_nodes.txt 中定义的节点
    ├── install_packages.sh         # 安装所有 Python 依赖
    └── problematic_requirements.txt # 需要特殊处理的依赖列表
```

## 🛠️ 手动构建与运行 (不使用 Compose)

### 构建镜像

```bash
docker build -t comfyui-docker .
```

### 运行容器

```bash
docker run -d --gpus all \
  -p 8188:8188 \
  -e HF_ENDPOINT=https://hf-mirror.com \
  -v $(pwd)/models:/app/models \
  -v $(pwd)/output:/app/output \
  --name comfyui-docker \
  comfyui-docker
```

## 环境变量

您可以通过 `docker-compose.yml` 或 `docker run` 的 `-e` 参数来设置以下环境变量：

| 变量                    | 描述                                                               | 默认值                       |
| ----------------------- | ------------------------------------------------------------------ | ---------------------------- |
| `HF_ENDPOINT`           | Hugging Face 端点，可用于配置国内镜像。                            | `https://huggingface.co`     |
| `DOWNLOAD_EXAMPLE_MODELS` | 是否在首次启动时下载官方示例模型。                                 | `true`                       |
| `FORCE_DOWNLOAD_MODELS` | 是否强制重新下载模型，即时本地已存在。                             | `false`                      |
| `FIX_PERMISSIONS`       | 是否在启动时修复 `/app` 目录的文件权限。                           | `true`                       |

## 高级用法

### 自定义启动脚本

如果您有更复杂的启动前准备工作（例如，下载特定模型到特定子目录），可以创建一个 `custom_init.sh` 脚本，然后取消 `docker-compose.yml` 中对应的 volumes 注释。`entrypoint.sh` 会在启动 ComfyUI 主程序前自动执行此脚本。 
#!/bin/bash
set -e

echo "升级 pip 并安装 wheel 和 setuptools..."
python3.11 -m pip install --no-cache-dir --upgrade pip
python3.11 -m pip install --no-cache-dir wheel setuptools

# 安装包的函数，包含多种回退方法
install_package() {
    local package=$1
    local version=$2
    
    echo "尝试安装 $package==$version..."
    
    # 尝试多种安装方法
    for method in \
        "--only-binary=:all:" \
        "--no-build-isolation" \
        "--no-deps"; do
        echo "方法: pip install $method $package==$version"
        if python3.11 -m pip install --no-cache-dir $method "$package==$version"; then
            echo "成功安装 $package==$version"
            return 0
        fi
    done
    
    echo "警告: 无法安装 $package==$version，继续执行..."
    return 0
}

# 读取问题包列表并单独安装
if [ -f "/app/scripts/problematic_requirements.txt" ]; then
    echo "安装问题包..."
    while IFS= read -r line || [[ -n "$line" ]]; do
        # 跳过空行和注释
        [[ -z "$line" || "$line" =~ ^#.*$ ]] && continue
        
        # 解析包名和版本
        if [[ "$line" =~ ([^=]+)==(.+) ]]; then
            package="${BASH_REMATCH[1]}"
            version="${BASH_REMATCH[2]}"
            install_package "$package" "$version"
        fi
    done < "/app/scripts/problematic_requirements.txt"
fi

# 安装主要依赖项
echo "安装主要依赖项..."
if ! python3.11 -m pip install --no-cache-dir -r /app/requirements.txt; then
    echo "主要依赖项安装失败，尝试使用 --ignore-installed 标志..."
    if ! python3.11 -m pip install --no-cache-dir --ignore-installed -r /app/requirements.txt; then
        echo "警告: 某些包安装失败，但我们将继续执行。"
    fi
fi

echo "包安装完成。" 
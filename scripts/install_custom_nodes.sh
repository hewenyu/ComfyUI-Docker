#!/bin/bash
set -e

# This script clones custom nodes from a list of git repositories.

# The list of repositories should be provided in a file, where each line is a git URL.
# Lines starting with # and empty lines are ignored.

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_custom_nodes_list_file>"
    exit 1
fi

NODE_LIST_FILE="$1"
CUSTOM_NODES_DIR="/app/custom_nodes"

mkdir -p "$CUSTOM_NODES_DIR"
cd "$CUSTOM_NODES_DIR"

echo "Cloning custom nodes from $NODE_LIST_FILE..."

while IFS= read -r repo_url || [[ -n "$repo_url" ]]; do
    # Trim leading/trailing whitespace
    repo_url=$(echo "$repo_url" | sed 's/^[ \t]*//;s/[ \t]*$//')

    # Skip empty lines and comments
    if [ -z "$repo_url" ] || [[ "$repo_url" == \#* ]]; then
        continue
    fi

    echo "Cloning repository: $repo_url"
    git clone "$repo_url"
done < "$NODE_LIST_FILE"

echo "All custom nodes cloned." 
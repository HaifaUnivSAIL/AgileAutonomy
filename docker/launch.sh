#!/bin/bash

# Resolve the absolute host path of the repo root
HOST_DIR=$(realpath "$(dirname "$0")/..")  # Parent directory of ./docker

CONTAINER_NAME="agile_autonomy_container"

if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    echo "[+] Container '$CONTAINER_NAME' already exists. Starting it..."
    docker start -ai "$CONTAINER_NAME"
else
    echo "[+] Container '$CONTAINER_NAME' does not exist. Creating and starting it..."
    docker run --gpus all \
        -it \
        --name "$CONTAINER_NAME" \
        -v "${HOST_DIR}:/workspace" \
        -w /workspace \
        --net=host \
        --ipc=host \
        agile_autonomy_base \
        bash
fi


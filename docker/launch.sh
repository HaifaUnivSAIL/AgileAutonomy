#!/bin/bash

# Resolve the absolute host path of the repo root
HOST_DIR=$(realpath "$(dirname "$0")/..")  # Parent directory of ./docker
DATASET_DIR=$(realpath "$(dirname "$0")/../../Datasets")  # Datasets directory

CONTAINER_NAME="agile_autonomy_container"
PYCHARM_VERSION="2025.1.3.1"
PYCHARM_DIR="/opt/pycharm-community-${PYCHARM_VERSION}"
PYCHARM_TAR="pycharm-community-${PYCHARM_VERSION}.tar.gz"
PYCHARM_URL="https://download.jetbrains.com/python/${PYCHARM_TAR}"

# Allow container to access host X server
xhost +local:root

if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    echo "[+] Container '$CONTAINER_NAME' already exists. Starting it..."
    docker start -ai "$CONTAINER_NAME"
else
    echo "[+] Container '$CONTAINER_NAME' does not exist. Creating and starting it..."
    docker run --gpus all \
        -it \
        --name "$CONTAINER_NAME" \
        -v "${HOST_DIR}:/workspace" \
        -v "${DATASET_DIR}:/mnt/dataset" \
        -v /usr/local/cuda-12.4:/usr/local/cuda-12.4 \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -e DISPLAY=$DISPLAY \
        --env QT_X11_NO_MITSHM=1 \
        -w /workspace \
        --net=host \
        --ipc=host \
        agile_autonomy_base \
        bash -c "
            if [ ! -d '${PYCHARM_DIR}' ]; then
                echo '[+] Installing PyCharm Community ${PYCHARM_VERSION}...'
                apt update && apt install -y wget tar openjdk-17-jdk libfuse2
                wget -q ${PYCHARM_URL} -P /tmp || (echo '[!] Download failed. Check version or URL.' && exit 1)
                mkdir -p /opt && tar -xzf /tmp/${PYCHARM_TAR} -C /opt
                echo '[+] PyCharm installed at ${PYCHARM_DIR}'
            fi

            # Add alias inside the container for future runs
            grep -qxF \"alias pycharm='${PYCHARM_DIR}/bin/pycharm.sh &'\" /root/.bashrc || echo \"alias pycharm='${PYCHARM_DIR}/bin/pycharm.sh &'\" >> /root/.bashrc

            echo '[+] To launch PyCharm inside the container, type: pycharm'
            bash
        "
fi


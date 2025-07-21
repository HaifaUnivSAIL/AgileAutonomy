#!/bin/bash

# Resolve the absolute host path of the repo root
HOST_DIR=$(realpath "$(dirname "$0")/..")  # Parent directory of ./docker

# Create local storage directory for /usr/local if it doesn't exist
mkdir -p "${HOST_DIR}/docker_usr_local"
# Create local storage directory for /usr/local/bin if it doesn't exist
mkdir -p "${HOST_DIR}/docker_usr_local/bin"

docker run --gpus all \
  -it --rm \
  --name agile_autonomy_container \
  -v "${HOST_DIR}:/workspace" \
  -v "${HOST_DIR}/docker_usr_local:/usr/local" \
  -v "${HOME}/.ssh:/root/.ssh:rw" \
  -w /workspace \
  --net=host \
  --ipc=host \
  agile_autonomy_base \
  bash

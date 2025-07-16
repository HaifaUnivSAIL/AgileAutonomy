#!/bin/bash

# Resolve the absolute host path of the repo root
HOST_DIR=$(realpath "$(dirname "$0")/..")  # Parent directory of ./docker

docker run --gpus all \
  -it --rm \
  --name agile_autonomy_container \
  -v "${HOST_DIR}:/workspace" \
  -w /workspace \
  --net=host \
  --ipc=host \
  agile_autonomy_base \
  bash


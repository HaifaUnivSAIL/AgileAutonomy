#!/bin/bash

HOST_DIR=/mnt/c/Users/jomul/agile_autonomy  # Make sure this is the root of your project

docker run --gpus all \
  -it --rm \
  --name agile_autonomy_container \
  -v ${HOST_DIR}:/workspace \
  -w /workspace \
  --net=host \
  --ipc=host \
  agile_autonomy_base \
  bash


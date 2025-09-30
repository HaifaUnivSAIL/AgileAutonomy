#!/bin/bash
docker run --rm -it \
  --network=host \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $(pwd)/ardupilot:/home/builder/ardupilot \
  -w /home/builder/ardupilot \
  -u $(id -u):$(id -g) \
  ardupilot-builder \
  bash


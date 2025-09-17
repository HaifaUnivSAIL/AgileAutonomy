#!/bin/bash
set -e

# Clone ArduPilot locally if not already present
if [ ! -d "./ardupilot" ]; then
    git clone --recurse-submodules https://github.com/ArduPilot/ardupilot.git
fi

xhost +local:docker

# Build Docker image
docker build . -t ardupilot-builder --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)
sudo chmod +x ./launch.sh

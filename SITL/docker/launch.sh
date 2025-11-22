#!/bin/bash

# allow X connections from local host
xhost +local:root

docker run --rm -it \
  --gpus all \
  --network host \
  -e DISPLAY=$DISPLAY \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $(pwd)/ardupilot:/home/builder/ardupilot \
  -w /home/builder/ardupilot \
  ardupilot-gz-harmonic-humble /bin/bash -c "\
    source /opt/ros/humble/setup.bash && \
    source /opt/anaconda/etc/profile.d/conda.sh && \
    conda activate ardupilot_env && \
    exec bash"


#!/bin/bash
docker run --rm -it \
  -v $(pwd)/ardupilot:/home/builder/ardupilot \
  -w /home/builder/ardupilot \
  -u $(id -u):$(id -g) \
  ardupilot-builder \
  bash

cd ~/ardupilot

./waf configure --board MatekH743
./waf copter

The first configure command should be called only once or when you want to change a
configuration option. One configuration often used is the `--board` option to
switch from one board to another one. For example we could switch to
SkyViper GPS drone and build again:

./waf configure --board skyviper-v2450
./waf copter


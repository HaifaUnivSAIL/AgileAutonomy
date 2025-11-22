# ---------------------------
# Ubuntu 22.04 Base + ArduPilot + Gazebo Harmonic + ROS2 Humble + Anaconda
# ---------------------------
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ---------------------------
# Basic system dependencies
# ---------------------------
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates wget curl gnupg lsb-release apt-transport-https \
      git sudo locales tzdata build-essential ccache pkg-config \
      python3 python3-pip python3-venv python3-setuptools python3-wheel \
      python3-opencv python3-lxml tzdata software-properties-common \
      python3-dev libtool libxml2-dev libxslt1-dev genromfs \
    && locale-gen en_US.UTF-8 \
    && ln -sf /usr/bin/python3 /usr/bin/python || true \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Add OSRF Gazebo repository
# ---------------------------
RUN curl -sSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/gazebo-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gazebo-archive-keyring.gpg] \
      http://packages.osrfoundation.org/gazebo/ubuntu-stable jammy main" \
      > /etc/apt/sources.list.d/gazebo-stable.list

# ---------------------------
# Add ROS 2 Humble repository
# ---------------------------
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
      http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2.list

# ---------------------------
# Install Gazebo (gz harmonic), ROS2 Humble, ros-ign bridge and Python ROS tools
# ---------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      gz-harmonic \
      libgz-cmake3-dev libgz-math7-dev libgz-msgs10-dev libgz-transport13-dev libgz-sim8-dev \
      ros-humble-desktop \
      ros-humble-ros-ign-bridge \
      python3-colcon-common-extensions python3-vcstool python3-rosdep python3-rosinstall-generator \
      mesa-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Initialize rosdep (safe to run as root in Docker)
RUN rosdep init || true
RUN rosdep update || true

# ---------------------------
# Create builder user (non-root) and add to dialout
# ---------------------------
ARG USERNAME=builder
ARG USER_UID=1016
ARG USER_GID=1016

RUN groupadd --gid ${USER_GID} ${USERNAME} || true && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} || true && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -a -G dialout ${USERNAME} || true

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ---------------------------
# Install Anaconda (system-wide under /opt) as root
# ---------------------------
USER root
WORKDIR /opt
RUN apt-get update && apt-get install -y wget bzip2 ca-certificates && apt-get clean
RUN wget -q https://repo.anaconda.com/archive/Anaconda3-2025.06-1-Linux-x86_64.sh -O /opt/anaconda.sh && \
    bash /opt/anaconda.sh -b -p /opt/anaconda && \
    rm /opt/anaconda.sh

ENV PATH=/opt/anaconda/bin:$PATH

# Accept conda Terms of Service and configure conda non-interactively
# (This avoids CondaToSNonInteractiveError during docker build)
RUN /opt/anaconda/bin/conda init bash && \
    /opt/anaconda/bin/conda config --set always_yes yes --set changeps1 no && \
    /opt/anaconda/bin/conda config --set auto_activate_base false
    

# ---------------------------
# Create ArduPilot conda env & install Python deps (run as non-root user)
# ---------------------------
USER root

# Switch to builder user
USER ${USERNAME}

# Accept TOS as this user (mandatory!)
RUN /opt/anaconda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    /opt/anaconda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# Now create the environment (will work)
RUN /opt/anaconda/bin/conda create -n ardupilot_env python=3.10 -y && \
    /opt/anaconda/bin/conda run -n ardupilot_env pip install --upgrade pip && \
    /opt/anaconda/bin/conda run -n ardupilot_env pip install \
        empy==3.3.4 pexpect future pymavlink MAVProxy catkin_pkg

ENV PATH=/opt/anaconda/envs/ardupilot_env/bin:$PATH

# ---------------------------
# Install ARM toolchain & GCC 12 (root)
# ---------------------------
USER root
RUN apt-get update && apt-get install -y \
      gcc-arm-none-eabi binutils-arm-none-eabi gdb-multiarch \
      software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
    && apt-get update && apt-get install -y gcc-12 g++-12 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------
# GUI helpers and dev deps (root)
# ---------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      x11-apps python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-osmgpsmap-1.0 \
      libgirepository1.0-dev gobject-introspection pkg-config libcairo2-dev \
      python3-tk python3-pil.imagetk protobuf-compiler libprotobuf-dev libprotoc-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Switch to builder to clone and build ArduPilot
# ---------------------------
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Clone ArduPilot (recursive submodules)
RUN git clone --recursive https://github.com/ArduPilot/ardupilot.git || (cd ardupilot && git pull && git submodule update --init --recursive)

# Build SITL (may take a while)
# note: waf uses python in PATH; ensure conda env path is in PATH for build:
#ENV PATH=/opt/anaconda/envs/ardupilot_env/bin:$PATH

#RUN cd /home/${USERNAME}/ardupilot && \
#    ./waf configure --board sitl && \
#    ./waf copter && \
#    ./waf plane && \
#    ./waf rover
WORKDIR /home/${USERNAME}/ardupilot
RUN /opt/anaconda/bin/conda run -n ardupilot_env ./waf configure --board sitl && \
    /opt/anaconda/bin/conda run -n ardupilot_env ./waf copter && \
    /opt/anaconda/bin/conda run -n ardupilot_env ./waf plane && \
    /opt/anaconda/bin/conda run -n ardupilot_env ./waf rover


# Build ArduPilot Gazebo Plugin (Tools/Gazebo)
RUN cd /home/${USERNAME}/ardupilot/Tools/Gazebo && \
    make -j$(nproc) || make || true

# ---------------------------
# Add run_sim.sh and run_ros_gz.sh automation scripts
# ---------------------------
# run_sim.sh: menu to simulate Iris / Rover / Plane
# run_ros_gz.sh: helper that starts gz sim and shows/attempts a ros<->gz bridge command
RUN mkdir -p /home/${USERNAME}/bin

RUN cat > /home/${USERNAME}/bin/run_sim.sh <<'EOF'
#!/bin/bash
# Menu-based simulator launcher (ArduPilot SITL + Gazebo)
# Ensure conda env and ROS are sourced prior to running this script (the Dockerfile adds these to .bashrc).
source /opt/anaconda/etc/profile.d/conda.sh
conda activate ardupilot_env

glxinfo | grep "OpenGL renderer" || true

echo "=============================="
echo "   ArduPilot Simulation Menu"
echo "=============================="
echo "1) Iris Quadcopter"
echo "2) Rover"
echo "3) Plane"
echo "4) Quit"
echo "=============================="
read -p "Choose option: " choice

case $choice in
  1) sim_vehicle.py -v ArduCopter -f gazebo-iris --console --map ;;
  2) sim_vehicle.py -v Rover -f gazebo-rover --console --map ;;
  3) sim_vehicle.py -v ArduPlane -f gazebo-plane --console --map ;;
  4) exit 0 ;;
  *) echo "Invalid option"; exit 1 ;;
esac
EOF
RUN chmod +x /home/${USERNAME}/bin/run_sim.sh

RUN cat > /home/${USERNAME}/bin/run_ros_gz.sh <<'EOF'
#!/bin/bash
# Helper to start gz sim and give guidance / attempt to run a basic ROS2<->Ign bridge
# Usage: ./run_ros_gz.sh [world.sdf]
WORLD=${1:-empty.sdf}

# Source conda and ROS
source /opt/anaconda/etc/profile.d/conda.sh
conda activate ardupilot_env
# Source ROS installation (system)
if [ -f /opt/ros/humble/setup.bash ]; then
  source /opt/ros/humble/setup.bash
fi

echo "Starting gz sim (background)..."
# start gz sim in background (non-blocking)
gz sim --verbose ${WORLD} >/tmp/gz_sim.log 2>&1 &

GZ_PID=$!
sleep 3

echo "gz sim started (PID=${GZ_PID}). Log: /tmp/gz_sim.log"
echo
echo "If you want to bridge a topic, example parameter_bridge command (replace topics/types):"
echo "ros2 run ros_ign_bridge parameter_bridge /clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock]"

# If ros_ign_bridge installed, try an example bridging of /clock (best-effort; no failure will stop script)
if ros2 pkg list | grep -q ros_ign_bridge; then
  echo "Attempting example bridge for /clock (best-effort)..."
  # the parameter_bridge terminals typically run in foreground; run it in background for demo:
  ros2 run ros_ign_bridge parameter_bridge /clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock] >/tmp/ros_ign_bridge.log 2>&1 &
  echo "ros_ign_bridge started (see /tmp/ros_ign_bridge.log)."
else
  echo "ros_ign_bridge not present in ROS workspace. Install or run the above command manually when ready."
fi
EOF
RUN chmod +x /home/${USERNAME}/bin/run_ros_gz.sh

# ---------------------------
# Add env vars and bashrc tweaks for builder and root
# ---------------------------
USER ${USERNAME}
RUN echo "source /opt/anaconda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate ardupilot_env" >> ~/.bashrc && \
    echo 'export PATH="$HOME/.local/bin:$PATH:/home/builder/bin"' >> ~/.bashrc && \
    echo 'export GZ_SIM_RESOURCE_PATH=$HOME/ardupilot/Tools/Gazebo' >> ~/.bashrc && \
    echo 'export GZ_SIM_SYSTEM_PLUGIN_PATH=$HOME/ardupilot/Tools/Gazebo/build' >> ~/.bashrc

USER root
RUN echo "source /opt/anaconda/etc/profile.d/conda.sh" >> /root/.bashrc && \
    echo "conda activate ardupilot_env" >> /root/.bashrc

# ---------------------------
# Final defaults
# ---------------------------
USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV PATH=/home/${USERNAME}/bin:$PATH

CMD ["/bin/bash"]


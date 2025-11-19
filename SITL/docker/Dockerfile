# ---------------------------
# Ubuntu 22.04 Base + ArduPilot + Gazebo Harmonic + ROS2 Humble
# ---------------------------
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# ---------------------------
# Basic system dependencies
# ---------------------------
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates wget curl gnupg lsb-release apt-transport-https \
      git sudo locales tzdata build-essential ccache pkg-config \
      python3 python3-pip python3-venv python3-setuptools python3-wheel \
      python3-opencv python3-lxml tzdata software-properties-common \
    && locale-gen en_US.UTF-8 \
    && ln -sf /usr/bin/python3 /usr/bin/python || true \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ---------------------------
# Add OSRF Gazebo repository
# ---------------------------
RUN curl -sSL https://packages.osrfoundation.org/gazebo.gpg \
      -o /usr/share/keyrings/gazebo-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gazebo-archive-keyring.gpg] \
      http://packages.osrfoundation.org/gazebo/ubuntu-stable jammy main" \
      > /etc/apt/sources.list.d/gazebo-stable.list

# ---------------------------
# Add ROS 2 Humble repository
# ---------------------------
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
      -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
      http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2.list

# ---------------------------
# Install Gazebo + ROS 2 + Python ROS tools
# ---------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      gz-harmonic \
      libgz-cmake3-dev libgz-math7-dev libgz-msgs10-dev libgz-transport13-dev libgz-sim8-dev \
      ros-humble-desktop \
      python3-colcon-common-extensions python3-vcstool python3-rosdep python3-rosinstall-generator \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init || true
RUN rosdep update || true

# ---------------------------
# Create builder user
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
# Install Anaconda
# ---------------------------
USER root
WORKDIR /opt
RUN apt-get update && apt-get install -y wget bzip2 && apt-get clean
RUN wget -q https://repo.anaconda.com/archive/Anaconda3-2025.06-1-Linux-x86_64.sh -O /opt/anaconda.sh && \
    bash /opt/anaconda.sh -b -p /opt/anaconda && \
    rm /opt/anaconda.sh

ENV PATH=/opt/anaconda/bin:$PATH

# ---------------------------
# Create ArduPilot conda env & install Python deps
# ---------------------------
USER ${USERNAME}
RUN /opt/anaconda/bin/conda init bash && \
    /opt/anaconda/bin/conda config --set always_yes yes --set changeps1 no && \
    /opt/anaconda/bin/conda config --set auto_activate_base false && \
    /opt/anaconda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    /opt/anaconda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    /opt/anaconda/bin/conda create -n ardupilot_env python=3.10 -y && \
    /opt/anaconda/bin/conda run -n ardupilot_env pip install --upgrade pip && \
    /opt/anaconda/bin/conda run -n ardupilot_env pip install --user \
      empy==3.3.4 pexpect future pymavlink MAVProxy catkin_pkg

ENV PATH=/opt/anaconda/envs/ardupilot_env/bin:$PATH

# ---------------------------
# Install ARM toolchain & GCC 12
# ---------------------------
USER root
RUN apt-get update && apt-get install -y \
      gcc-arm-none-eabi binutils-arm-none-eabi gdb-multiarch \
      software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
    && apt-get update && apt-get install -y gcc-12 g++-12 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100 \
    && apt-get clean

# ---------------------------
# Install GUI & Python GTK deps
# ---------------------------
RUN apt-get update && apt-get install -y \
      x11-apps python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-osmgpsmap-1.0 \
      libgirepository1.0-dev gobject-introspection pkg-config libcairo2-dev python3-tk python3-pil.imagetk mesa-utils \
    && apt-get clean

# ---------------------------
# Setup bashrc for conda & ardupilot_env
# ---------------------------
USER ${USERNAME}
RUN echo "source /opt/anaconda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda config --set changeps1 True" >> ~/.bashrc && \
    echo "conda activate ardupilot_env" >> ~/.bashrc && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

USER root
RUN echo "source /opt/anaconda/etc/profile.d/conda.sh" >> /root/.bashrc && \
    echo "conda activate ardupilot_env" >> /root/.bashrc

# ---------------------------
# Set default working dir & user
# ---------------------------
USER ${USERNAME}
WORKDIR /home/${USERNAME}
CMD ["/bin/bash"]


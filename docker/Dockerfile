FROM ubuntu:20.04

# Set frontend to noninteractive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive
ARG ROS_DISTRO=noetic

# Locale and base tools
RUN apt-get update && apt-get install -y \
    locales \
    lsb-release \
    curl \
    wget \
    gnupg2 \
    git \
    sudo \
    bash-completion \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ROS installation
RUN apt-get update && \
    apt-get install -y curl gnupg2 lsb-release && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | apt-key add - && \
    echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list && \
    apt-get update && \
    apt-get install -y ros-$ROS_DISTRO-desktop-full && \
    rm -rf /var/lib/apt/lists/*

# ROS setup
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /root/.bashrc

# Tools needed for ROS workspace setup
RUN apt-get update && apt-get install -y \
    python3-catkin-tools \
    python3-osrf-pycommon \
    python3-vcstool \
    && rm -rf /var/lib/apt/lists/*

# Install GCC/G++ 7.5
RUN apt-get update && apt-get install -y \
    gcc-7 g++-7 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash"]


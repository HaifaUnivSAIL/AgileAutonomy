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

# Gazebo development libraries and ROS integration packages
RUN apt-get update && apt-get install -y \
    libgazebo11-dev \
    ros-noetic-gazebo-ros \
    ros-noetic-gazebo-plugins \
    ros-noetic-gazebo-ros-control \
    && rm -rf /var/lib/apt/lists/*
    
# Google glog library required for rotors_gazebo_plugins
RUN apt-get update && apt-get install -y \
    libgoogle-glog-dev \
    && rm -rf /var/lib/apt/lists/*
    
# Install GCC/G++ 7.5
RUN apt-get update && apt-get install -y \
    gcc-7 g++-7 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Install system deps for Anaconda
RUN apt update && apt install -y wget bzip2 sudo git

# Download and install full Anaconda 4.8.3 (Python 3.7)
WORKDIR /opt
RUN wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh -O anaconda.sh && \
    bash anaconda.sh -b -p /opt/anaconda && \
    rm anaconda.sh

# Add Anaconda to PATH
ENV PATH="/opt/anaconda/bin:$PATH"

# Create a conda environment named ros_env (Python 3.7)
RUN conda create -n ros_env python=3.7 -y

# Install empy via pip (conda doesn't provide it for this setup)
RUN /opt/anaconda/bin/pip install empy && \
    /opt/anaconda/envs/ros_env/bin/pip install empy

# Ensure conda is initialized and ros_env is activated on container start
RUN echo "source /opt/anaconda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate ros_env" >> ~/.bashrc

CMD ["/bin/bash"]


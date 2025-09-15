FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Basic build tools and prerequisites
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y --no-install-recommends \
      wget curl git ca-certificates sudo build-essential ccache \
      python3 python3-pip python3-venv python3-setuptools python3-wheel python3-future python3-lxml python3-opencv \
      locales tzdata && \
    ln -sf /usr/bin/python3 /usr/bin/python || true && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create builder user
RUN groupadd --gid 1016 builder || true && \
    useradd --uid 1016 --gid 1016 -m builder || true && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


# Switch to builder to run ArduPilot prereqs script
#USER builder
#WORKDIR /home/builder/ardupilot
#RUN Tools/environment_install/install-prereqs-ubuntu.sh -y

# Add builder to dialout group before running script
USER root
RUN usermod -a -G dialout builder

# Switch to builder user for running the prereqs script
USER builder
WORKDIR /home/builder/ardupilot

# Ensure USER env var is correct for script
ENV USER=builder

# Run ArduPilot prerequisites script
RUN sudo -E Tools/environment_install/install-prereqs-ubuntu.sh -y || true


# Switch back to root for system-level configuration
USER root
WORKDIR /home/builder

# Create ccache symlinks for arm compilers (harmless if toolchain not yet present)
RUN mkdir -p /usr/lib/ccache && \
    ln -sf /usr/bin/ccache /usr/lib/ccache/arm-none-eabi-g++ && \
    ln -sf /usr/bin/ccache /usr/lib/ccache/arm-none-eabi-gcc

# Add ArduPilot tools to PATH
ENV PATH=$PATH:/home/builder/ardupilot/Tools/autotest:/usr/lib/ccache

# Default to builder user
USER builder
WORKDIR /home/builder/ardupilot

# Install system deps for Anaconda
RUN sudo apt update && sudo apt install -y wget bzip2 sudo git

# make sure we’re root here
USER root

# Download and install full Anaconda 4.8.3 (Python 3.10)
WORKDIR /opt
RUN wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh -O anaconda.sh && \
    bash anaconda.sh -b -p /opt/anaconda && \
    rm anaconda.sh

# Optional: give builder ownership so he can use conda
#RUN chmod -R a+rX /opt/anaconda
#ENV PATH=/opt/anaconda/bin:$PATH

# Add conda to PATH **before** using it
ENV PATH=/opt/anaconda/bin:$PATH

# switch back to builder
USER builder


# Use bash instead of sh for RUN
SHELL ["/bin/bash", "-c"]

# Create a new Conda environment for SITL (Python 3.10):
# Create conda env + install packages in one step
RUN conda create -n ardupilot_env python=3.10 -y && \
    source /opt/anaconda/etc/profile.d/conda.sh && \
    conda activate ardupilot_env && \
    pip install empy==3.3.4 pexpect future pymavlink

USER root
RUN apt-get update && apt-get install -y \
    gcc-arm-none-eabi \
    binutils-arm-none-eabi \
    gdb-multiarch \
 && apt-get clean
USER builder

# 🔧 Fix: Upgrade GCC in Docker
# You can install a newer GCC via the Ubuntu Toolchain PPA:
USER root
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
    apt-get update && \
    apt-get install -y gcc-12 g++-12 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100 && \
    apt-get clean
USER builder

# Make env the default python path
ENV PATH=/opt/anaconda/envs/ardupilot_env/bin:$PATH
#ENV PATH="/opt/anaconda/bin:$PATH"
    
# Ensure conda is initialized and ardupilot_env is activated on container start
RUN echo "source /opt/anaconda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate ardupilot_env" >> ~/.bashrc


CMD ["/bin/bash"]

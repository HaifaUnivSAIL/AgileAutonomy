FROM ubuntu:20.04

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

CMD ["/bin/bash"]


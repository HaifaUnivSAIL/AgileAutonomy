#!/bin/bash
set -e

echo "=== 🚀 Installing ArduPilot Gazebo Plugin (Garden/Harmonic) ==="

# --- Step 1: Create workspace ---
WORKSPACE_DIR=~/WorkProjects/AgileAutonomy/SITL/docker
AGILE_AUTONOMY=${WORKSPACE_DIR}/ardupilot/Tools/autotest
GZ_WS_DIR="${WORKSPACE_DIR}/gz_ws"
SRC_DIR="${GZ_WS_DIR}/src"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Step 2: Clone the repository ---
if [ ! -d "ardupilot_gazebo" ]; then
    git clone https://github.com/ArduPilot/ardupilot_gazebo.git
else
    echo "Repository already exists, skipping clone."
fi

# --- Step 3: Install dependencies ---
sudo apt update
sudo apt install -y libgz-sim8-dev libopencv-dev rapidjson-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl

# --- Step 4: Detect Gazebo version ---
GZ_VERSION=$(gz sim --version | grep -oE 'version [0-9]+' | awk '{print $2}')
echo "Detected Gazebo version: $GZ_VERSION"
export GZ_VERSION=harmonic  # Change to 'garden' if using Garden
echo "Set GZ_VERSION=$GZ_VERSION"

# --- Step 5: Build the plugin ---
cd ardupilot_gazebo
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j$(nproc)
sudo make install

# --- Step 6: Configure environment variables ---
echo "export GZ_SIM_SYSTEM_PLUGIN_PATH=${SRC_DIR}/ardupilot_gazebo/build:\$GZ_SIM_SYSTEM_PLUGIN_PATH" >> ~/.bashrc
echo "export GZ_SIM_RESOURCE_PATH=${SRC_DIR}/ardupilot_gazebo/models:${SRC_DIR}/ardupilot_gazebo/worlds:\$GZ_SIM_RESOURCE_PATH" >> ~/.bashrc
source ~/.bashrc

echo "=== ✅ ArduPilot Gazebo Plugin installation complete ==="

# --- Step 7: Run example simulations ---
read -p "Run Iris quadcopter example? [y/N]: " RUN_IRIS
if [[ "$RUN_IRIS" =~ ^[Yy]$ ]]; then
    echo "Launching Gazebo Iris world..."
    gz sim -v4 -r iris_runway.sdf &
    GAZ_PID=$!
    sleep 5
    echo "Starting SITL for ArduCopter (Iris)..."
    cd "$WORKSPACE_DIR"
    ${AGILE_AUTONOMY}/sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON --map --console
    kill $GAZ_PID || true
fi

read -p "Run Zephyr delta-wing example? [y/N]: " RUN_ZEPHYR
if [[ "$RUN_ZEPHYR" =~ ^[Yy]$ ]]; then
    echo "Launching Gazebo Zephyr world..."
    gz sim -v4 -r zephyr_runway.sdf &
    GAZ_PID=$!
    sleep 5
    echo "Starting SITL for ArduPlane (Zephyr)..."
    cd "$WORKSPACE_DIR"
    ${AGILE_AUTONOMY}/sim_vehicle.py -v ArduPlane -f gazebo-zephyr --model JSON --map --console
    kill $GAZ_PID || true
fi

echo "=== 🎯 SITL + Gazebo verification complete ==="

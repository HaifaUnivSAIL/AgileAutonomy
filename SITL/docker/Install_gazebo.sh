#!/bin/bash
set -e

echo "=== 🚀 Installing Gazebo for ArduPilot SITL ==="

# --- Step 1: Detect Ubuntu version ---
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_CODENAME=$(lsb_release -cs)
echo "Detected Ubuntu version: $UBUNTU_VERSION ($UBUNTU_CODENAME)"

# --- Step 2: Basic dependencies ---
sudo apt update && sudo apt install -y \
  lsb-release wget gnupg curl build-essential cmake git \
  python3-pip python3-venv \
  libeigen3-dev libopencv-dev qtbase5-dev \
  rapidjson-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-tools \
  gstreamer1.0-plugins-good gstreamer1.0-plugins-base

# --- Step 3: Clean old installations ---
echo "=== 🧹 Cleaning old Gazebo installations ==="
sudo apt remove -y ignition-* gazebo* gz-* || true
sudo apt autoremove -y

# --- Step 4: Add Gazebo repository ---
echo "=== 🧩 Adding Gazebo repository ==="
sudo wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/gazebo-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/gazebo-archive-keyring.gpg] \
http://packages.osrfoundation.org/gazebo/ubuntu-stable ${UBUNTU_CODENAME} main" | \
sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null

sudo apt update

# --- Step 5: Install the correct Gazebo version based on Ubuntu ---
if (( $(echo "$UBUNTU_VERSION < 22.00" | bc -l) )); then
    echo "Installing Gazebo Classic (gazebo11)..."
    sudo apt install -y gazebo11 libgazebo11-dev
    GZ_SETUP="/usr/share/gazebo/setup.sh"
    GZ_PLUGIN_PATH_VAR="GAZEBO_PLUGIN_PATH"
    GZ_MODEL_PATH_VAR="GAZEBO_MODEL_PATH"
    GZ_BINARY="gazebo"
    TEST_CMD="gazebo --verbose worlds/empty.world"

elif (( $(echo "$UBUNTU_VERSION < 24.00" | bc -l) )); then
    echo "Installing Gazebo Garden (gz-garden)..."
    sudo apt install -y gz-garden
    GZ_SETUP="/usr/share/gz-garden/setup.sh"
    GZ_PLUGIN_PATH_VAR="GZ_SIM_SYSTEM_PLUGIN_PATH"
    GZ_MODEL_PATH_VAR="GZ_SIM_RESOURCE_PATH"
    GZ_BINARY="gz sim"
    TEST_CMD="gz sim -v4 -r shapes.sdf"

else
    echo "Installing Gazebo Harmonic (gz-harmonic)..."
    sudo apt install -y gz-harmonic
    GZ_SETUP="/usr/share/gz-harmonic/setup.sh"
    GZ_PLUGIN_PATH_VAR="GZ_SIM_SYSTEM_PLUGIN_PATH"
    GZ_MODEL_PATH_VAR="GZ_SIM_RESOURCE_PATH"
    GZ_BINARY="gz sim"
    TEST_CMD="gz sim -v4 -r shapes.sdf"
fi

# --- Step 6: Source setup in .bashrc if missing ---
if ! grep -q "$GZ_SETUP" ~/.bashrc; then
    echo "source $GZ_SETUP" >> ~/.bashrc
    echo "Added Gazebo setup to .bashrc ✅"
fi

# --- Step 7: Build ArduPilot Gazebo plugin ---
echo "=== 🛠️  Building ArduPilot Gazebo Plugin ==="

WORKSPACE_DIR=$(pwd)
ARDUPILOT_GAZEBO_DIR="${WORKSPACE_DIR}/ardupilot_gazebo"

if [ ! -d "$ARDUPILOT_GAZEBO_DIR" ]; then
    git clone https://github.com/ArduPilot/ardupilot_gazebo.git "$ARDUPILOT_GAZEBO_DIR"
fi

cd "$ARDUPILOT_GAZEBO_DIR"
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j$(nproc)
sudo make install

# --- Step 8: Add plugin & model paths to .bashrc ---
if ! grep -q "ardupilot_gazebo" ~/.bashrc; then
    echo "export ${GZ_PLUGIN_PATH_VAR}=${ARDUPILOT_GAZEBO_DIR}/build:\$$GZ_PLUGIN_PATH_VAR" >> ~/.bashrc
    echo "export ${GZ_MODEL_PATH_VAR}=${ARDUPILOT_GAZEBO_DIR}/models:\$$GZ_MODEL_PATH_VAR" >> ~/.bashrc
    echo "Added ArduPilot Gazebo plugin paths to .bashrc ✅"
fi

# --- Step 9: Reload environment variables for current session ---
source ~/.bashrc || true

# --- Step 10: Verify Gazebo version ---
echo
echo "=== ✅ Installation complete ==="
$GZ_BINARY --version || true

# --- Step 11: Automatic test run ---
echo
echo "=== 🧪 Running a short Gazebo test ==="
echo "Command: $TEST_CMD"
echo "(This will open a Gazebo window briefly to verify installation.)"
sleep 3

$TEST_CMD &
PID=$!
sleep 10
kill $PID >/dev/null 2>&1 || true

echo
echo "=== 🎯 Gazebo installation and test complete! ==="
echo "If no errors appeared, you’re ready to use ArduPilot SITL with Gazebo."
echo
echo "To reload all environment variables, run:"
echo "  source ~/.bashrc"


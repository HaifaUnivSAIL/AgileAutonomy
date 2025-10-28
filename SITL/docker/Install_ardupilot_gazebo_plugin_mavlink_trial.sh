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
    gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl \
    python3-pexpect
    
python3 -m pip install empy==3.3.4
python3 -m pip install future pyserial
pip install MAVProxy[mavproxy-map,mavproxy-adsb]


# Install MAVProxy
pip install MAVProxy
echo "Verify mavproxy installation "
which mavproxy.py
# or
mavproxy.py --version

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

# --- Step 7: Fix SITL permissions safely ---
# Only adjust ownership and write permissions for your user where necessary
sudo chown -R $(whoami):$(whoami) ${WORKSPACE_DIR}/ardupilot
chmod u+w ${WORKSPACE_DIR}/ardupilot/Tools/autotest
chmod u+w ${WORKSPACE_DIR}/ardupilot/modules

echo "=== ✅ ArduPilot Gazebo Plugin installation complete ==="

# --- Step 8: Python automation script for commands ---
PYTHON_SCRIPT=$(mktemp)
cat << 'EOF' > $PYTHON_SCRIPT
import pexpect
import time
import sys
sitl_path = sys.argv[1]

# Start SITL (no --console)
child = pexpect.spawn(f'python3 {sitl_path} -v ArduPlane -f gazebo-zephyr --model JSON --map', encoding='utf-8')
child.logfile = sys.stdout

# Wait for prompt
child.expect('SITL>', timeout=300)  # wait up to 5 minutes
time.sleep(2)

# Send commands
child.sendline('mode fbwa')
child.expect('FBWA>')
time.sleep(1)

child.sendline('arm throttle')
child.expect('FBWA>')
time.sleep(1)

child.sendline('rc 3 1800')  # throttle mid for takeoff
child.expect('FBWA>')
time.sleep(1)

child.sendline('mode circle')
child.expect('CIRCLE>')
time.sleep(1)

# Keep SITL running for a while
time.sleep(15)
child.sendline('exit')
EOF

# --- Step 9: Run Gazebo + SITL + automation ---
echo "Launching Gazebo Zephyr world..."
gz sim -v4 -r zephyr_runway.sdf &
GAZ_PID=$!
sleep 5

echo "Starting SITL and automatic commands..."
python3 $PYTHON_SCRIPT ${AGILE_AUTONOMY}/sim_vehicle.py

kill $GAZ_PID || true
rm $PYTHON_SCRIPT

echo "=== 🎯 SITL + Gazebo automatic test complete ==="


#!/bin/bash

cd /workspace/agile_autonomy_ws/catkin_aa/devel
sudo chmod +x ./setup.bash
./setup.bash

cd /workspace/agile_autonomy_ws/catkin_aa
catkin build planner_learning
source devel/setup.bash
roscd planner_learning

pip install tensorflow
pip install rospkg==1.2.3 pyquaternion open3d opencv-python

## Now download the flightmare standalone available at this link, extract it and put in the flightrender folder:
# Define paths
FLIGHTRENDER_DIR="/workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/flightrender"
DOWNLOAD_URL="https://zenodo.org/record/5517791/files/standalone.tar?download=1"
TAR_NAME="standalone.tar"

# Create flightrender folder if it doesn't exist
mkdir -p "$FLIGHTRENDER_DIR"

# Download Flightmare standalone tar (if not already downloaded)
if [ ! -f "$TAR_NAME" ]; then
    echo "Downloading Flightmare standalone..."
    wget "$DOWNLOAD_URL" -O "$TAR_NAME"
else
    echo "Flightmare standalone archive already downloaded."
fi

# Extract into flightrender folder
echo "Extracting Flightmare standalone into $FLIGHTRENDER_DIR ..."
tar -xf "$TAR_NAME" -C "$FLIGHTRENDER_DIR"

echo "Done."

source /workspace/agile_autonomy_ws/catkin_aa/devel/setup.bash
sudo apt-get install python3-defusedxml
pip install defusedxml
apt update && apt install -y tmux

echo "To test if the installation worked you should see the defusedxml version:"
python -c "import defusedxml; print(defusedxml.__version__)"
roslaunch agile_autonomy simulation.launch

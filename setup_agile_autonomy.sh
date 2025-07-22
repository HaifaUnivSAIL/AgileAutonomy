#!/bin/bash
set -e

export ROS_VERSION=noetic

# Navigate to project root (assuming this script is placed in the project root)
cd "$(dirname "$0")"

mkdir -p agile_autonomy_ws/catkin_aa/src
cd agile_autonomy_ws/catkin_aa

catkin init
catkin config --extend /opt/ros/$ROS_VERSION
catkin config --merge-devel
catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-fdiagnostics-color

cd src

# If agile_autonomy already exists, remove it
if [ -d "agile_autonomy" ]; then
    echo "Removing existing agile_autonomy folder..."
    rm -rf agile_autonomy
fi

echo "Cloning agile_autonomy repository..."

# Clone using HTTPS instead of SSH
git clone https://github.com/uzh-rpg/agile_autonomy.git


echo "Step One...Done"

# Patch dependencies.yaml path
sed -i 's|git@github.com:|https://github.com/|g' agile_autonomy/dependencies.yaml

# Pre-create dependency folders and mark them as safe directories
echo "Pre-creating dependency folders and marking them as safe directories..."

# Check if yq is installed, if not install it
if ! command -v yq &> /dev/null; then
    echo "yq not found — installing yq..."
    sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
    sudo chmod +x /usr/local/bin/yq
fi

yq eval '.repositories | keys | .[]' ./agile_autonomy/dependencies.yaml | while read repo; do
    full_path="$(pwd)/$repo"
    echo "Creating $full_path..."
    mkdir -p "$full_path"
    echo "Marking $full_path as a safe directory..."
    git config --global --add safe.directory "$full_path"
done

# git config --global --get-all safe.directory
echo "Step Two...Done"

# Import dependencies
vcs-import < agile_autonomy/dependencies.yaml

echo "Step Three...Done"

cd rpg_mpl_ros

echo "Marking all nested git repos as safe directories..."
find "$(pwd)" -name ".git" | while read gitdir; do
    repo=$(dirname "$gitdir")
    echo "Marking $repo as safe"
    git config --global --add safe.directory "$repo"
done

git config --global --add safe.directory /workspace/agile_autonomy_ws/catkin_aa/src/rpg_mpl_ros


git submodule update --init --recursive

echo "Step Four...Done"

# Install extra dependencies
sudo apt-get update
sudo apt-get install -y libqglviewer-dev-qt5

echo "Step Five...Done"

# Install external libraries for rpg_flightmare
sudo apt install -y libzmqpp-dev libeigen3-dev libglfw3-dev libglm-dev

echo "Step Six...Done"

# Install dependencies for rpg_flightmare renderer
sudo apt install -y libvulkan1 vulkan-utils gdb

# Add environment variable
echo 'export RPGQ_PARAM_DIR=/workspace/agile_autonomy_ws/catkin_aa/src/rpg_flightmare' >> ~/.bashrc

echo "All steps are Done!!"
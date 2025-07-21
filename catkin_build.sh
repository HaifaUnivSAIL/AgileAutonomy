#!/bin/bash

# Make sure catkin uses the system CMake
catkin config --cmake /usr/bin/cmake

BUILD_OPEN3D=false
FIRST_BUILD=false
for arg in "$@"
do
  case $arg in
    --build-open3d)
      BUILD_OPEN3D=true
      shift
      ;;
    --first-build)
      FIRST_BUILD=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "  --build-open3d    Build and install Open3D from source."
      echo "  --first-build     catkin Build for the first time will generate all of the folders (patch fixing would be called iff not 1st time building otherwise the folders to fix will not exist)."
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Use --help for available options."
      exit 1
      ;;
  esac
done

if [ "$FIRST_BUILD" = true ]; then
  BUILD_OPEN3D=true
fi

if ! cmake --version | grep -q "4.0.3"; then
  echo "Installing CMake 4.0.3"
  # Go to /opt where we'll install it
  cd /opt
  # Download latest CMake v4.0.3 binary release
  wget https://github.com/Kitware/CMake/releases/download/v4.0.3/cmake-4.0.3-linux-x86_64.tar.gz
  # Extract archive
  tar -xzf cmake-4.0.3-linux-x86_64.tar.gz
  # Remove the archive to clean up
  rm cmake-4.0.3-linux-x86_64.tar.gz
  # Add symlinks for cmake and related tools to /usr/local/bin
  ln -sf /opt/cmake-4.0.3-linux-x86_64/bin/* /usr/local/bin/
  # Verify installation
  cmake --version
  cd /workspace
else
  echo "CMake 4.0.3 is already installed"
fi
echo "Step One...Done"

#echo "Installing Necessary packages:"
#pip install pyyaml
#pip install catkin_pkg
#pip install empy==3.3.4
#pip install rospkg
#pip install numpy
#sudo apt-get update
#sudo apt-get install 
echo "Installing Python packages:"
pip install pyyaml
pip install catkin_pkg
pip install empy==3.3.4
pip install rospkg
pip install numpy
echo "Step Two...Done"

echo "Installing system dependencies:"
sudo apt-get update
sudo apt-get install -y \
  ros-noetic-octomap-msgs \
  git \
  build-essential \
  libgl1-mesa-dev \
  libc++-dev \
  libc++abi-dev \
  wayland-protocols \
  libwayland-dev \
  libxkbcommon-dev \
  libzstd-dev \
  libfmt-dev  \
  libglfw3-dev \
  libsdl2-dev #\
  #nvidia-cuda-toolkit


echo "System dependencies installed."
echo "Step Three...Done"


if [ "$BUILD_OPEN3D" = true ]; then
  echo "Installing Open3D:"
  #apt-get update && apt-get install -y git cmake build-essential libgl1-mesa-dev ros-noetic-octomap-msgs

  if [ -d "/workspace/Open3D" ]; then
    echo "Removing existing /workspace/Open3D folder..."
    rm -rf /workspace/Open3D
  fi

  git clone --recursive https://github.com/isl-org/Open3D.git
  cd Open3D
  git config --global --add safe.directory /workspace/Open3D
  git config --global --add safe.directory /workspace/Open3D/build/uvatlas/src/ext_directxmath
  git config --global --add safe.directory /workspace/Open3D/build/uvatlas/src/ext_directxheaders

  sudo chmod u+w /workspace/Open3D/cpp/open3d/CMakeLists.txt
  sudo sed -i '/open3d_link_3rdparty_libraries(Open3D)/a target_link_libraries(Open3D PUBLIC zstd)' /workspace/Open3D/cpp/open3d/CMakeLists.txt


  mkdir build && cd build
  rm -rf *                  # careful — this deletes everything in the build dir
  cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
    -DZSTD_ROOT=/usr \
    -DZSTD_LIBRARY=/usr/lib/x86_64-linux-gnu/libzstd.so \
    -DZSTD_INCLUDE_DIR=/usr/include \
    -DUSE_SYSTEM_ZSTD=ON \
    -DUSE_SYSTEM_FMT=ON
  make -j$(nproc)
  make install
  export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:/usr/local/
  cd /workspace
  echo "Open3D installed."
  # Add this block here
  if [ ! -e /usr/local/include/Open3D ]; then
    echo "Creating symlink /usr/local/include/Open3D -> /usr/local/include/open3d"
    sudo ln -s /usr/local/include/open3d /usr/local/include/Open3D
  else
    echo "/usr/local/include/Open3D already exists"
  fi
else
  echo "Skipping Open3D build."
fi
echo "Step Four...Done"

echo "Patching googletest CMakeLists.txt for CMake 4.x compatibility..."
if grep -q "cmake_minimum_required(VERSION 2" /usr/src/googletest/CMakeLists.txt; then
  find /usr/src/googletest -name "CMakeLists.txt" | while read file; do
    echo "Patching $file"
    sed -i 's/cmake_minimum_required(VERSION [0-9.]\+)/cmake_minimum_required(VERSION 3.5)/' "$file"
  done
  echo "Googletest patch done."
else
  echo "Googletest already patched."
fi
echo "Step Five...Done"

if [ "$BUILD_OPEN3D" = true ]; then
  echo "Building catkin packages:"
  cd /workspace/agile_autonomy_ws/catkin_aa
  catkin build open3d_conversions
  echo "Build complete."
else
  echo "Skipping open3d_conversions build."
fi
echo "Step Six...Done"

echo "Cloning the motion_primitive_library:"
cd /workspace/agile_autonomy_ws/catkin_aa/src
#git clone git@github.com:ethz-asl/motion_primitive_library.git
git clone https://github.com/sikang/motion_primitive_library.git
git clone https://github.com/sikang/DecompUtil.git decomp_util
echo "Step Seven...Done"


#########################
set -e  # exit on error

# Move to the workspace root
cd /workspace/agile_autonomy_ws/catkin_aa

# Remove any old conflicting catkin tools config in parent folders
if [ -d "/workspace/.catkin_tools" ]; then
  echo "Removing stale /workspace/.catkin_tools"
  rm -rf /workspace/.catkin_tools
fi

# Initialize catkin config if not already present
if [ ! -d ".catkin_tools" ]; then
  echo "Initializing catkin workspace config"
  catkin config --init --extend /opt/ros/noetic --workspace $(pwd)
  # Optional: add default CMake args for color diagnostics etc.
  catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-fdiagnostics-color
fi

##########################





echo "Building Catkin:"
cd /workspace/agile_autonomy_ws/catkin_aa/src

#if ! catkin config | grep -q "CMP0000=NEW"; then
#    catkin config --append-args -DCMAKE_POLICY_DEFAULT_CMP0000=NEW
#fi

# Path to your workspace src folder
SRC_DIR="/workspace/agile_autonomy_ws/catkin_aa/src"

# Find all CMakeLists.txt files and update cmake_minimum_required version to 3.5 if less than 3.5
find "$SRC_DIR" -name "CMakeLists.txt" | while read -r cmakefile; do
     # Use sed to update cmake_minimum_required version to 3.5
     # This replaces lines like: cmake_minimum_required(VERSION 2.8) to 3.5
    sed -i -E 's/(cmake_minimum_required\(VERSION )[0-9]+\.[0-9]+/\13.5/' "$cmakefile"
done

# This argument s
if [ "$FIRST_BUILD" = true ]; then
  echo "First time build (installing all of the packages) hence package fixing should only happen from the next build."
else
  echo "After first time build (the packages exists so now we can fixed them)."
  sed -i '73s/2.8.12/3.5/' /workspace/agile_autonomy_ws/catkin_aa/build/gflags_catkin/gflags_src-prefix/src/gflags_src/CMakeLists.txt
  sed -i '37s/cmake_minimum_required( VERSION [0-9]\+\.[0-9]\+ )/cmake_minimum_required( VERSION 3.5 )/' /workspace/agile_autonomy_ws/catkin_aa/build/assimp_catkin/assimp_src-prefix/src/assimp_src/CMakeLists.txt
  sed -i '46s/cmake_minimum_required( *VERSION [0-9]\+\.[0-9]\+ *)/cmake_minimum_required(VERSION 3.5)/' /workspace/agile_autonomy_ws/catkin_aa/build/assimp_catkin/assimp_src-prefix/src/assimp_src/code/CMakeLists.txt
  sed -i 's/cmake_policy(SET CMP0053 OLD)/cmake_policy(SET CMP0053 NEW)/' /workspace/agile_autonomy_ws/catkin_aa/src/glog_catkin/CMakeLists.txt
  sed -i 's/cmake_minimum_required(VERSION 2.8.3)/cmake_minimum_required(VERSION 3.5)/' src/decomp_util/CMakeLists.txt
fi

sudo apt update
sudo apt install ros-noetic-octomap-ros
source /opt/ros/noetic/setup.bash

##################################################
## planning_ros_utils patch:
# Install necessary SDL2 and pkg-config if missing
sudo apt-get update && sudo apt-get install -y libsdl2-dev libsdl2-image-dev pkg-config

# Patch CMakeLists.txt of planning_ros_utils
CMAKE_FILE="/workspace/agile_autonomy_ws/catkin_aa/src/rpg_mpl_ros/planning_ros_utils/CMakeLists.txt"

sed -i '/find_package(SDL REQUIRED)/d' "$CMAKE_FILE"
sed -i '/find_package(SDL_image REQUIRED)/d' "$CMAKE_FILE"

sed -i '/find_package(motion_primitive_library REQUIRED)/a \
find_package(PkgConfig REQUIRED)\n\
pkg_check_modules(SDL2 REQUIRED sdl2)\n\
pkg_check_modules(SDL2_IMAGE REQUIRED SDL2_image)\n\
include_directories(${SDL2_INCLUDE_DIRS} ${SDL2_IMAGE_INCLUDE_DIRS})\n\
link_directories(${SDL2_LIBRARY_DIRS} ${SDL2_IMAGE_LIBRARY_DIRS})' "$CMAKE_FILE"

echo "[INFO] Patched planning_ros_utils CMakeLists.txt for SDL2 via pkg-config"


# Install rpg_flightmare simulator dependencies
sudo apt-get install -y libzmqpp-dev libglm-dev libsdl1.2-dev libsdl-image1.2-dev

# Patch old RViz API usage (Patch planning_ros_utils: comment out old RViz API usage to fix build)
sed -i 's/.*update_nh_\.setCallbackQueue(point_cloud_common_->getCallbackQueue());/\/\/ &/'     /workspace/agile_autonomy_ws/catkin_aa/src/rpg_mpl_ros/planning_ros_utils/src/planning_rviz_plugins/map_display.cpp

# Patch SDL includes from SDL/ to SDL2/ if needed (Patch SDL include paths to match installed SDL2 headers)
find /workspace/agile_autonomy_ws/catkin_aa/src/rpg_mpl_ros/planning_ros_utils/ -type f \( -name "*.hpp" -o -name "*.cpp" \) |   xargs sed -i 's|#include <SDL/|#include <SDL2/|g'

# Patch CMakeLists to link against SDL2 and SDL2_image
sed -i '/cs_add_executable(image_to_map.*/a target_link_libraries(image_to_map ${catkin_LIBRARIES} SDL2 SDL2_image)'   /workspace/agile_autonomy_ws/catkin_aa/src/rpg_mpl_ros/planning_ros_utils/CMakeLists.txt

# Set Open3D include path so it can find KDTreeFlann.h
#export CPLUS_INCLUDE_PATH=/workspace/Open3D/cpp:$CPLUS_INCLUDE_PATH

# Optional: also set LD_LIBRARY_PATH if Open3D built libraries are needed at runtime
#export LD_LIBRARY_PATH=/workspace/Open3D/build/lib:$LD_LIBRARY_PATH

#patch_open3d_includes() {
#  echo "[INFO] Patching CMakeLists.txt files to include Open3D headers path if missing..."

#  find /workspace/agile_autonomy_ws/catkin_aa/src -name CMakeLists.txt | while read cmakefile; do
    # Only patch if include_directories() exists and /workspace/Open3D/cpp not already present
#    if grep -q "include_directories(" "$cmakefile" && ! grep -q "/workspace/Open3D/cpp" "$cmakefile"; then
#      echo "[PATCH] Updating $cmakefile"
#      sed -i '/include_directories(/,/)/ {
#        /\/workspace\/Open3D\/cpp/! {
#          /)/i \
#  /workspace/Open3D/cpp
#        }
#      }' "$cmakefile"
#    fi
#  done
#}


# Call it before catkin build
#patch_open3d_includes

##############Questionable"###
set -e

cd /workspace/agile_autonomy_ws/catkin_aa

if [ -d "/workspace/.catkin_tools" ]; then
  echo "Removing stale /workspace/.catkin_tools"
  rm -rf /workspace/.catkin_tools
fi

if [ ! -d ".catkin_tools" ]; then
  echo "Initializing catkin workspace config"
  catkin config --init --extend /opt/ros/noetic --workspace $(pwd)
fi

# Set CMake build arguments
catkin config --cmake-args \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS=-fdiagnostics-color \
  -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda
##########################
#I have overall 5 packages with Issues (with 4 other packages abended as a result):
# 1. traj_sampler
# 2. mpl_test_node
# 4. rotors_gazebo_plugins (rotors_gazebo, rotors_simulator, rpg_quadrotor_integration_test)
# 5. numpy_eigen (minkindr_python)
# Overall 62/71 Succesfully installed packages (Atm).
#
#!/bin/bash

### Fixing traj_sampler and mpl_test_node:
#!/bin/bash

# File paths
NUMPY_EIGEN_HEADER="/workspace/agile_autonomy_ws/catkin_aa/src/numpy_eigen/src/autogen_module/numpy_eigen_export_module.cpp"
KDTREE_HEADER="/workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/data_generation/traj_sampler/include/traj_sampler/kdtree.h"
ELLIPSOID_UTIL_HEADER="/workspace/agile_autonomy_ws/catkin_aa/src/rpg_mpl_ros/mpl_external_planner/include/mpl_external_planner/ellipsoid_planner/ellipsoid_util.h"

# Replacements
printf "Fixing numpy_eigen..."
sed -i 's#import_array();#if (_import_array() < 0) { PyErr_Print(); PyErr_SetString(PyExc_ImportError, "numpy.core.multiarray failed to import"); return; }#' "$NUMPY_EIGEN_HEADER"
echo "Done"

sed -i 's#<Open3D/Geometry/KDTreeFlann.h>#<Open3D/geometry/KDTreeFlann.h>#g' "$KDTREE_HEADER"
sed -i 's#<Open3D/Geometry/PointCloud.h>#<Open3D/geometry/PointCloud.h>#g' "$KDTREE_HEADER"
sed -i 's#<Open3D/IO/ClassIO/PointCloudIO.h>#<Open3D/io/PointCloudIO.h>#g' "$KDTREE_HEADER"
sed -i 's#<Open3D/Geometry/KDTreeFlann.h>#<Open3D/geometry/KDTreeFlann.h>#g' "$ELLIPSOID_UTIL_HEADER"
sed -i 's#<Open3D/Geometry/PointCloud.h>#<Open3D/geometry/PointCloud.h>#g' "$ELLIPSOID_UTIL_HEADER"

echo "Patching gazebo_noisydepth_plugin.h to remove dynamic_reconfigure include..."
sed -i '/#include <dynamic_reconfigure\/server.h>/d' \
    src/rotors_simulator/rotors_gazebo_plugins/include/rotors_gazebo_plugins/gazebo_noisydepth_plugin.h
echo "Patching rotors_gazebo_plugins/CMakeLists.txt to include CXX_STANDARD 14"
sed -i '/add_definitions(-std=c++11)/i \
# Specify C++14 standard (fix for placement-new errors)\n\
set(CMAKE_CXX_STANDARD 14)\n\
set(CMAKE_CXX_STANDARD_REQUIRED ON)\n\
set(CMAKE_CXX_EXTENSIONS OFF)
' src/rotors_simulator/rotors_gazebo_plugins/CMakeLists.txt
sed -i '/add_definitions(-std=c++11)/d' \
src/rotors_simulator/rotors_gazebo_plugins/CMakeLists.txt

    
# Optional: confirm what was changed
echo "Patched includes in:"
echo " - $KDTREE_HEADER"
echo " - $ELLIPSOID_UTIL_HEADER"


# Now continue with catkin build
catkin build  --summary --continue-on-failure "$@"

#catkin clean -y
#catkin build
echo "Step Eight...Done"
echo "All steps are Done"

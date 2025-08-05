# 🐳 Docker Installation & Catkin Build Instructions

Follow the steps below to install Docker, set up the container environment, and build the Catkin workspace for this project.

---

## 🔧 From the Host Shell

1. **Build the Docker container**:
   ```bash
   ./docker/build.sh

2. **Launch the Docker container**:
   ```bash
    ./docker/launch.sh

## 🧱 Inside the Docker Container

3. **Install preliminary dependencies (e.g., open3D, open3D_conversions)**:
   ```bash
    ./setup_agile_autonomy.sh

4. **Perform the initial Catkin build (this also builds open3D)**:
   ```bash
    ./catkin_build.sh --first-build

5. **Run a second build to fix any remaining packages**:
   ```bash
    ./catkin_build.sh

6. **Run after the second call to catkin_build.sh to run everything up to the single terminal simulation**:
   ```bash
    ./final_touch.sh

📝 Notes

1. **💡 To rebuild Open3D later at any point**:
   ```bash
    ./catkin_build.sh --build_open3d

2. **🧹 To clean everything (containers, volumes, and build folders)**:
   ```bash
    ./remove_everything.sh
    
3. **💡 To run Pycharm from within the docker just type**:
   ```bash
    pycharm

##  Dataset location

**Host computer location**:
Place your data in the "datasets" folder (if doesnt exist create one). 

Note: The "datasets" folder should reside at the same folder as the project's folder "AgileAutonomy" is (i.e youll see AgileAutonomy/docker/ or AgileAutonomy/setup_agile_autonomy.sh).

**Inside the docker container location**:
You'll see it  under the "/mnt/dataset" path.

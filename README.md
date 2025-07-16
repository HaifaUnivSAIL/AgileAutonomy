# 🐳 Docker Installation & Catkin Build Instructions

Follow the steps below to install Docker, set up the container environment, and build the Catkin workspace for this project.

---

## 🔧 From the Host Shell

1. **Build the Docker container**:
   ```bash
   ./docker/build.sh

    Launch the Docker container:

    ./docker/launch.sh

🧱 Inside the Docker Container

    Install preliminary dependencies (e.g., open3D, open3D_conversions):

./setup_agile_autonomy.sh

Perform the initial Catkin build (this also builds open3D):

./catkin_build.sh --first-build

Run a second build to fix any remaining packages:

    ./catkin_build.sh

📝 Notes

    💡 To rebuild Open3D later at any point:

./catkin_build.sh --build_open3d

🧹 To clean everything (containers, volumes, and build folders):

./remove_everything.sh

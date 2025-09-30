# 🐳 Docker Installation & Catkin Build Instructions

Follow the steps below to run SITL & Mission planner

---

## 1. 1st terminal with SITL and drone simulator: 

**1. Launch the Docker container:**:
   ```bash
    ./launch.sh

**1. Run the following command:**:
   ```bash
    ./sim_vehicle.py -v ArduCopter --console --map --out udp:127.0.0.1:14550


##2. 2st terminal with Mission planner: 

**Go to MP and run Mission planner using MONO**:
   ```bash
    ./mono ./MP/MissionPlanner.exe

##3. Inside the ArduPilot:
**At the upper right corner of the screen:**
**Choose UDP.**
**press the CONNECT icon.**
**In the "Enter Local port" option type 14550**

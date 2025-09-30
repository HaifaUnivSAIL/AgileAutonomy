# 🐳 Docker Installation & Mission Planner Instructions

Follow the steps below to Install the SITL docker & Mission planner

---

## 1st Terminal with SITL and drone simulator: 
1. **Build the Docker container**:
   ```bash
    ./build.sh

2. **Launch the Docker container**:
   ```bash
    ./launch.sh

3. **Run the following command:**
   ```bash
    ./sim_vehicle.py -v ArduCopter --console --map --out udp:127.0.0.1:14550

## 2nd terminal with Mission planner: 

1. **Go inside the MP directory and run Mission planner using MONO**:
   ```bash
    ./mono ./MP/MissionPlanner.exe

## Inside the ArduPilot:
**At the upper right corner of the screen:**<br>
**Choose UDP.**<br>
**press the CONNECT icon.**<br>
**In the "Enter Local port" option type 14550**<br>

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
pip install PySide2
apt update && apt install -y tmux

echo "To test if the installation worked you should see the defusedxml version:"
python -c "import defusedxml; print(defusedxml.__version__)"

## Changing code errors for running the command "python test_trajectories.py --settings_file=config/test_settings.yaml" successfully: 
# 1. Replace the usage in the code
sed -i '/from tensorflow\.python\.keras\.applications import mobilenet/ {
    s/^/# /
    a\
from tensorflow.keras.applications import mobilenet
}' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/nets.py

# 2. Replace the usage in the code
sed -i 's/self\.learning_rate_fn = tf\.keras\.experimental\.CosineDecayRestarts(/self.learning_rate_fn = CosineDecayRestarts(/' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

# 3. Add the import on line 6
sed -i '6a from tensorflow.keras.optimizers.schedules import CosineDecayRestarts' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

# 4. Comment out the deprecated set_learning_phase(0) command that is also irrelavent in Inference
sed -i 's/^\s*tf\.keras\.backend\.set_learning_phase(0)/#&/' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/PlannerLearning.py

# 5. Fixing the plan_learner.py file
sed -i '76s|.*|            if self.config.freeze_backbone:\n                predictions = self.network(inputs, training=False)\n            else:\n                predictions = self.network(inputs, training=True)|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '96s|.*|        predictions = self.network(inputs, training=False)|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '157,160s|^|#|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '169s|^|#|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '208s|^|#|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '242s|.*|        predictions = self.network(inputs, training=False)|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '142s|.*|            self.train_space_loss.reset_state()|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '143s|.*|            self.val_space_loss.reset_state()|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '166s|.*|                    self.train_space_loss.reset_state()|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '167s|.*|                    self.train_cost_loss.reset_state()|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '181s|.*|            self.val_space_loss.reset_state()|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '182s|.*|            self.val_cost_loss.reset_state()|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '214s|.*|            self.val_space_loss.reset_state()|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

sed -i '215s|.*|            self.val_cost_loss.reset_state()|' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/src/PlannerLearning/models/plan_learner.py

roslaunch agile_autonomy simulation.launch

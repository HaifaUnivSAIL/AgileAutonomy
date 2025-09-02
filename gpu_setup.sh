#!/bin/bash
# ============================================================
# finalization.sh
# Script to finalize CUDA + TensorFlow GPU environment setup
# Ensures consistent GPU memory growth and correct XLA libdevice path
# ============================================================

set -e

echo "[INFO] Finalizing TensorFlow GPU environment..."

# ------------------------------------------------------------
# 0. Backing up old nvcc & symlinking to cuda12.4
# ------------------------------------------------------------
# Backup old nvcc
mv /usr/bin/nvcc /root/old_nvcc

# Add symlink to CUDA 12.4
ln -s /usr/local/cuda-12.4/bin/nvcc /usr/bin/nvcc


# ------------------------------------------------------------
# 1. Ensure CUDA path is exported
# ------------------------------------------------------------
export CUDA_HOME=/usr/local/cuda-12.4
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# ------------------------------------------------------------
# 2. Installing the appropriate Cudnn & the matching tensorflow
# ------------------------------------------------------------
conda install nvidia::cudnn cuda-version=12
export CUDA_HOME=$CONDA_PREFIX
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib:$LD_LIBRARY_PATH

pip install --upgrade tensorflow

export CUDA_HOME=/opt/anaconda/envs/ros_env
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib:$LD_LIBRARY_PATH
export TF_CPP_MIN_LOG_LEVEL=0

echo 'export CUDA_HOME=/opt/anaconda/envs/ros_env' >> ~/.bashrc
echo 'export PATH=$CUDA_HOME/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=$CUDA_HOME/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export TF_CPP_MIN_LOG_LEVEL=0' >> ~/.bashrc



# ------------------------------------------------------------
# 3. Fix TensorFlow XLA libdevice path
# ------------------------------------------------------------

# Temporary fix:
export XLA_FLAGS="--xla_gpu_cuda_data_dir=${CUDA_HOME}"
# Permanent fix:
echo 'export XLA_FLAGS="--xla_gpu_cuda_data_dir=/usr/local/cuda-12.4"' >> /opt/anaconda/envs/ros_env/etc/conda/activate.d/env_vars.sh


# ------------------------------------------------------------
# 4. Configure TensorFlow GPU memory growth (all GPUs)
# This will create a python helper script to set memory growth
# ------------------------------------------------------------
sed -i '/from config.settings import create_settings/a\
\n#######> Jonny added these lines\nimport tensorflow as tf\n\ngpus = tf.config.list_physical_devices('"'"'GPU'"'"')\nif gpus:\n    for gpu in gpus:\n        tf.config.experimental.set_memory_growth(gpu, True)\n\n#######<\n' /workspace/agile_autonomy_ws/catkin_aa/src/agile_autonomy/planner_learning/train.py


TF_MEMORY_GROWTH_SCRIPT=/tmp/tf_memory_growth.py

cat << 'EOF' > $TF_MEMORY_GROWTH_SCRIPT
import tensorflow as tf

gpus = tf.config.list_physical_devices('GPU')
if gpus:
    try:
        # Enable memory growth on all GPUs
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
        logical_gpus = tf.config.list_logical_devices('GPU')
        print(len(gpus), "Physical GPUs,", len(logical_gpus), "Logical GPUs")
    except RuntimeError as e:
        # Memory growth must be set before GPUs have been initialized
        print(e)

EOF

python $TF_MEMORY_GROWTH_SCRIPT

# ------------------------------------------------------------
# 5. Show GPU devices recognized by TensorFlow
# ------------------------------------------------------------
python -c "import tensorflow as tf; print('[INFO] TF GPUs:', tf.config.list_physical_devices('GPU'))"

echo "[INFO] Finalization complete. TensorFlow should now run with CUDA-12.4 GPUs without mismatch issues."


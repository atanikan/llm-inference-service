#!/bin/bash -l
#PBS -l select=8:system=polaris
#PBS -l place=scatter
#PBS -l walltime=00:60:00
#PBS -l filesystems=home:eagle
#PBS -q debug
#PBS -A datascience

# This script is the master controller for the job.
# It sets up the environment, uses one Python script to manage the Ray cluster,
# and a second Python script to launch the VLLM server.

set -e # Exit immediately if a command exits with a non-zero status.

#echo "Working directory: $PBS_O_WORKDIR"
#cd "$PBS_O_WORKDIR" || exit

echo "Job ID: $PBS_JOBID"
echo "Running on: $(hostname)"

# --- Environment and Script Setup ---
# The setup script handles all environment variable exports and conda activation.
export SETUP_SCRIPT_PATH="${PWD}/setup_env.sh"
source "$SETUP_SCRIPT_PATH"

export RAY_SCRIPT_PATH="${PWD}/start_ray_cluster.py"
export VLLM_SCRIPT_PATH="${PWD}/start_vllm.py"
export VLLM_TEST_SCRIPT_PATH="${PWD}/vllm_test_client.py"

# --- Ray Cluster Management ---
# Start the Ray cluster. The script will print the head node's IP to stdout.
echo "Starting Ray cluster with Python script..."
vllm_host_ip=$(python3 "$RAY_SCRIPT_PATH" --command start --setup-script "$SETUP_SCRIPT_PATH")
if [ -z "$vllm_host_ip" ]; then
    echo "Failed to get Ray head node IP. Exiting."
    exit 1
fi
echo "Ray cluster setup appears successful. Head node IP: $vllm_host_ip"

# --- Start VLLM Server in Background ---
echo "Attempting to start VLLM server in the background on $vllm_host_ip..."
python3 "$VLLM_SCRIPT_PATH" \
    --setup-script "$SETUP_SCRIPT_PATH" \
    --model-name "meta-llama/Meta-Llama-3.1-8B-Instruct" \
    --host "$vllm_host_ip" \
    --port 8000 \
    --tensor-parallel-size 4 \
    --pipeline-parallel-size 2 \
    --log-file "$PWD/vllm_server_$(hostname).log" &

# --- Verify VLLM Server ---
echo "Waiting for VLLM server to initialize..."
sleep 60 # Give the server ample time to start up before testing.

echo "Verifying VLLM server..."
# The test script will now log success or failure but will not cause the job to exit.
python3 "$VLLM_TEST_SCRIPT_PATH" --host "$vllm_host_ip" --port 8000

echo "VLLM server is running. Check logs for verification status."
echo "The job will now sleep indefinitely. You can connect to the VLLM server at http://$vllm_host_ip:8000"

# --- Cleanup ---
# The trap will run when the job is terminated (e.g., walltime limit).
# It ensures the Ray cluster is shut down cleanly.
trap "echo 'Job terminating. Stopping Ray cluster...'; python3 '$RAY_SCRIPT_PATH' --command stop --setup-script '$SETUP_SCRIPT_PATH'; exit" SIGINT SIGTERM

sleep infinity


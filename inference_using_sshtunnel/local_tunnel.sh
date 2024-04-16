#!/bin/bash

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <remote_user> <remote_host> <path_to_envs> <path_to_repo>"
    exit 1
fi

REMOTE_USER="$1"
REMOTE_HOST="$2"
PATH_TO_ENVS="$3"
PATH_TO_REPO="$4"
PATH_TO_TUNNEL="$PATH_TO_REPO/vllm_serve/tunnel.sh"
PATH_TO_WEBSERVER="$PATH_TO_REPO/vllm_serve/gradio_webserver.py"


# Check if there's an existing SSH tunnel running and kill it
existing_tunnel_pid=$(ps aux | grep "ssh -L 8001:localhost:8001 $REMOTE_USER@$REMOTE_HOST" | grep -v grep | awk '{print $2}')
if [[ ! -z "$existing_tunnel_pid" ]]; then
    echo "Killing existing SSH tunnel with PID $existing_tunnel_pid..."
    kill -9 "$existing_tunnel_pid"
fi

# Commands to be run on the remote host
REMOTE_COMMANDS="
if lsof -ti:8001; then
    echo 'Found process on port 8001, killing it...';
    lsof -ti:8001 | xargs kill -9;
else
    echo 'No process found on port 8001';
fi && \
echo 'establish ssh tunnel to compute' && \
bash $PATH_TO_TUNNEL && \
module load conda && \
conda activate $PATH_TO_ENVS && \
echo 'Running webserver' && \
nohup python3 $PATH_TO_WEBSERVER > /dev/null 2>&1 &
"

# Establish the SSH tunnel and execute commands on the remote host
ssh -L 8001:localhost:8001 "$REMOTE_USER@$REMOTE_HOST" "$REMOTE_COMMANDS"
if [[ $? -eq 0 ]]; then
    echo "SSH tunnel established successfully and remote commands executed."
else
   echo "Closed SSH tunnel"
fi
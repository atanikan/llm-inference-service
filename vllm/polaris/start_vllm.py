#!/usr/bin/env python3
import argparse
import subprocess
import time
import os
import sys
from hpc_utils import log

def cleanup_python_processes():
    """Finds and terminates specific Python processes to ensure a clean start."""
    log("Cleaning up existing Python processes...")
    patterns = ["vllm.entrypoints.api_server", "multiprocessing.spawn", "multiprocessing.resource_tracker"]
    for pattern in patterns:
        try:
            # Find processes matching the pattern
            result = subprocess.run(['pgrep', '-f', pattern], capture_output=True, text=True)
            if result.stdout:
                pids = result.stdout.strip().split('\n')
                log(f"Found PIDs for '{pattern}': {', '.join(pids)}. Terminating...")
                # Kill the found processes
                subprocess.run(['kill', '-9'] + pids, check=True)
        except subprocess.CalledProcessError as e:
            log(f"Could not kill processes for pattern '{pattern}': {e}. They might not be running.")
        except Exception as e:
            log(f"An unexpected error occurred during cleanup for '{pattern}': {e}")
    log("Cleanup complete.")

def start_vllm_server(args):
    """
    Constructs and runs the VLLM server command, with retry logic.
    """
    # The VLLM command arguments.
    vllm_command_args = [
        "vllm", "serve", args.model_name,
        "--host", args.host,
        "--port", str(args.port),
        "--tensor-parallel-size", str(args.tensor_parallel_size),
        "--pipeline-parallel-size", str(args.pipeline_parallel_size),
        "--gpu-memory-utilization", str(args.gpu_memory_utilization),
        "--disable-log-stats",
        "--enable-chunked-prefill",
        "--trust-remote-code",
        "--disable-log-requests"
    ]

    # This is the most reliable way to run the command: start a shell,
    # source the setup script, and then execute the command.
    full_shell_command = (
        f"source {args.setup_script} && "
        f"exec {' '.join(vllm_command_args)}"
    )
    
    log_dir = os.path.dirname(args.log_file)
    if log_dir:
        os.makedirs(log_dir, exist_ok=True)
    
    # Clear the log file before starting
    with open(args.log_file, 'w') as f:
        pass

    attempt = 0
    while attempt < args.max_retries:
        attempt += 1
        log(f"Starting VLLM server (Attempt {attempt}/{args.max_retries})...")
        log(f"Log file: {args.log_file}")
        log(f"Shell Command: {full_shell_command}")

        # Clean up any lingering processes before starting
        cleanup_python_processes()

        # Start the VLLM server in the background using a shell
        with open(args.log_file, 'a') as logfile:
            process = subprocess.Popen(full_shell_command, shell=True, executable='/bin/bash', stdout=logfile, stderr=subprocess.STDOUT)

        start_time = time.time()
        while time.time() - start_time < args.timeout:
            if os.path.exists(args.log_file):
                with open(args.log_file, 'r') as f:
                    # Check for both Uvicorn startup and VLLM application readiness
                    log_content = f.read()
                    if "Uvicorn running on" in log_content and "Application startup complete" in log_content:
                        log("VLLM server started successfully!")
                        return process
            time.sleep(5) # Check every 5 seconds

        log(f"Timeout reached for VLLM server. Killing process {process.pid}.")
        process.kill()
        process.wait()
        log("Process killed.")

    log(f"Failed to start VLLM server after {args.max_retries} attempts.")
    return None

def main():
    parser = argparse.ArgumentParser(description="Start the VLLM server with retry logic.")
    parser.add_argument("--setup-script", type=str, required=True, help="Path to the environment setup script (setup_env.sh).")
    parser.add_argument("--model-name", type=str, required=True, help="Name of the model to serve.")
    parser.add_argument("--host", type=str, required=True, help="Host IP for the VLLM server.")
    parser.add_argument("--port", type=int, default=8000, help="Port for the VLLM server.")
    parser.add_argument("--tensor-parallel-size", type=int, required=True)
    parser.add_argument("--pipeline-parallel-size", type=int, required=True)
    parser.add_argument("--gpu-memory-utilization", type=float, default=0.95)
    parser.add_argument("--log-file", type=str, required=True, help="Path to the log file.")
    parser.add_argument("--max-retries", type=int, default=3, help="Maximum number of startup retries.")
    parser.add_argument("--timeout", type=int, default=3600, help="Timeout in seconds for each startup attempt.")
    
    args = parser.parse_args()

    vllm_process = start_vllm_server(args)

    if vllm_process:
        log(f"VLLM server launched successfully as a background process with PID: {vllm_process.pid}.")
        # The script will now exit, leaving the server running.
        sys.exit(0)
    else:
        log("Exiting due to VLLM startup failure.")
        sys.exit(1)

if __name__ == "__main__":
    main() 
#!/usr/bin/env python3
import sys
import time
import re
import argparse
from hpc_utils import log, run_remote_cmd, get_node_ip, get_nodes

def start_cluster(setup_script):
    """Starts the Ray cluster and prints the head node IP."""
    nodes = get_nodes()
    head_node = nodes[0]
    worker_nodes = nodes[1:]

    log(f"Found {len(nodes)} nodes. Head: {head_node}, Workers: {', '.join(worker_nodes) if worker_nodes else 'None'}")

    log("Stopping any old Ray services...")
    for node in nodes:
        run_remote_cmd(node, "ray stop -f", setup_script, ignore_errors=True)
    
    log("Starting Ray head node...")
    head_ip = get_node_ip(head_node, setup_script)
    log(f"Head node IP (hsn0): {head_ip}")

    head_cmd = f"ray start --head --port=6379 --node-ip-address='{head_ip}' --redis-password='ray' --num-cpus=64 --num-gpus=4"
    run_remote_cmd(head_node, head_cmd, setup_script)
    
    log("Waiting for the head node to be ready...")
    time.sleep(10)

    if worker_nodes:
        log("Starting Ray worker nodes...")
        for worker_node in worker_nodes:
            worker_ip = get_node_ip(worker_node, setup_script)
            log(f"Worker {worker_node} IP (hsn0): {worker_ip}")
            worker_cmd = f"ray start --address='{head_ip}:6379' --redis-password='ray' --node-ip-address='{worker_ip}' --num-cpus=64 --num-gpus=4"
            run_remote_cmd(worker_node, worker_cmd, setup_script)

    log("Waiting for workers to connect...")
    time.sleep(15)

    check_status(setup_script)

    # Print the head IP for the master script to capture
    print(head_ip)


def stop_cluster(setup_script):
    """Stops the Ray cluster."""
    nodes = get_nodes()
    log("Stopping Ray on all nodes...")
    for node in nodes:
        run_remote_cmd(node, "ray stop -f", setup_script, ignore_errors=True)
    log("Ray cluster stopped.")

def check_status(setup_script):
    """Checks the status of the Ray cluster."""
    nodes = get_nodes()
    head_node = nodes[0]
    log("Checking Ray cluster status from the head node...")
    stdout, _ = run_remote_cmd(head_node, "ray status", setup_script)
    print("\n--- Ray Status ---")
    print(stdout)
    print("------------------\n")
    
    # Correctly parse the number of active nodes from the 'ray status' output.
    active_section = False
    num_active_nodes = 0
    for line in stdout.split('\n'):
        if line.strip() == "Active:":
            active_section = True
        elif active_section and (line.strip().startswith("Pending:") or line.strip().startswith("Recent failures:") or not line.strip()):
            active_section = False
        elif active_section and "node_" in line:
            num_active_nodes += 1
            
    # Also parse GPU count for an additional check
    actual_gpus = 0.0
    match = re.search(r'(\d+\.\d+)/(\d+\.\d+)\s+GPU', stdout)
    if match:
        actual_gpus = float(match.group(2))
        
    expected_gpus_per_node = 4 # As specified in the start command
    expected_gpus = len(nodes) * expected_gpus_per_node

    node_check_success = (num_active_nodes == len(nodes))
    gpu_check_success = (actual_gpus == expected_gpus)

    if node_check_success:
        log(f"SUCCESS: Cluster node count is correct ({num_active_nodes}/{len(nodes)}).")
    else:
        log(f"WARNING: Cluster node count is incorrect ({num_active_nodes}/{len(nodes)}).")

    if gpu_check_success:
        log(f"SUCCESS: Cluster GPU count is correct ({int(actual_gpus)}/{int(expected_gpus)}).")
    else:
        log(f"WARNING: Cluster GPU count is incorrect ({int(actual_gpus)}/{int(expected_gpus)}).")


def main():
    parser = argparse.ArgumentParser(description="Manage the Ray cluster on an HPC system.")
    parser.add_argument("--command", choices=['start', 'stop', 'status'], required=True, help="The action to perform.")
    parser.add_argument("--setup-script", type=str, required=True, help="Path to the environment setup script (setup_env.sh).")
    
    args = parser.parse_args()
        
    if args.command == "start":
        start_cluster(args.setup_script)
    elif args.command == "stop":
        stop_cluster(args.setup_script)
    elif args.command == "status":
        check_status(args.setup_script)
    else:
        log(f"Unknown command: {args.command}")
        sys.exit(1)

if __name__ == "__main__":
    main() 
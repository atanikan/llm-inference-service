#!/usr/bin/env python3
import os
import subprocess
import sys
from datetime import datetime

def log(message):
    """Prints a message with a timestamp to stderr."""
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {message}", file=sys.stderr, flush=True)

def run_remote_cmd(node, command, setup_script, ignore_errors=False):
    """
    Runs a command on a remote node via SSH after sourcing the setup script.
    The setup_script is expected to handle all environment setup, including conda activation.
    """
    ssh_command = [
        "ssh",
        node,
        (
            f"bash -l -c \"source {setup_script} && {command}\""
        ),
    ]
    
    log(f"Executing on {node}: {command}")
    
    result = subprocess.run(ssh_command, capture_output=True, text=True)
    
    if result.returncode != 0 and not ignore_errors:
        log(f"Error on {node} running command: {command}")
        log(f"  STDOUT: {result.stdout.strip()}")
        log(f"  STDERR: {result.stderr.strip()}")
        sys.exit(1)
        
    return result.stdout.strip(), result.stderr.strip()

def get_node_ip(node, setup_script):
    """Gets the hsn0 IP address of a node."""
    ip_cmd = "ip -4 addr show hsn0 | grep inet | awk '{print \\$2}' | cut -d'/' -f1"
    stdout, _ = run_remote_cmd(node, ip_cmd, setup_script)
    if not stdout:
        log(f"Could not get hsn0 IP for {node}. Aborting.")
        sys.exit(1)
    return stdout

def get_nodes():
    """Gets the list of unique nodes from PBS_NODEFILE."""
    node_file = os.environ.get("PBS_NODEFILE")
    if not node_file:
        log("Error: PBS_NODEFILE environment variable not set.")
        sys.exit(1)
    
    try:
        with open(node_file, 'r') as f:
            nodes = [line.strip().split('.')[0] for line in f.readlines()]
        unique_nodes = sorted(list(set(nodes)))
        if not unique_nodes:
            log("Error: No nodes found in PBS_NODEFILE.")
            sys.exit(1)
        return unique_nodes
    except FileNotFoundError:
        log(f"Error: PBS_NODEFILE not found at {node_file}")
        sys.exit(1) 
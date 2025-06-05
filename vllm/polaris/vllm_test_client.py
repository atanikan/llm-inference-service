#!/usr/bin/env python3
import requests
import argparse
import sys
from hpc_utils import log

def run_vllm_test(host, port):
    """
    Sends a sample request to the VLLM server to verify it is running.
    """
    server_url = f"http://{host}:{port}/v1/completions"
    log(f"Testing VLLM server at: {server_url}")

    request_payload = {
        "model": "meta-llama/Meta-Llama-3.1-8B-Instruct",
        "prompt": "San Francisco is a",
        "max_tokens": 7,
        "temperature": 0
    }

    try:
        response = requests.post(server_url, json=request_payload, timeout=30)
        response.raise_for_status()  # Raise an exception for bad status codes (4xx or 5xx)
        
        log("VLLM server responded successfully!")
        log(f"Response: {response.json()}")
        return True

    except requests.exceptions.RequestException as e:
        log(f"Error connecting to VLLM server: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Test client for VLLM server.")
    parser.add_argument("--host", type=str, required=True, help="Host IP of the VLLM server.")
    parser.add_argument("--port", type=int, default=8000, help="Port of the VLLM server.")
    args = parser.parse_args()

    if run_vllm_test(args.host, args.port):
        log("VLLM server verification PASSED.")
    else:
        log("VLLM server verification FAILED. The job will continue to run for debugging.")

if __name__ == "__main__":
    main() 
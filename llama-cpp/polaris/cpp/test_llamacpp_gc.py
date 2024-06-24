import time
from typing import List, Dict
from globus_compute_sdk import Executor


def _llamacpp_inference(**kwargs):
    """
    Function to make an inference request to the LlamaCpp API.

    Args:
        **kwargs: Keyword arguments containing the prompt and any other parameters
            to be passed to the API.

    Returns:
        str: The JSON response from the API.

    Raises:
        ValueError: If the OpenAI API key is not set.
    """
    import socket
    import json
    import os
    import time
    import requests
    
    # Determine the hostname
    hostname = socket.gethostname()
    os.environ['no_proxy'] = hostname
    # Construct the base_url
    base_url = f"http://{hostname}:8080/v1"
    
    # Get the API key from environment variable
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        api_key="random_api_key"
        raise ValueError("Missing OpenAI API key")


    # Initialize the OpenAI client with the base URL and API key
    client = openai.OpenAI(base_url=base_url, api_key=api_key)

    start_time = time.time()

    try:
        # Send a request to the chat completions endpoint
        response = client.chat.completions.create(
            model="mistral-7b",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": kwargs.get('prompt', '')}
            ],
            **kwargs  # Pass all other keyword arguments to the API
        )
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

    end_time = time.time()

    response_time = end_time - start_time
        
    response_dict = response.to_dict()  # This converts the response to a dictionary
    
    response_dict['response_time'] = response_time
    
    # Convert the response to a JSON-formatted string
    
    json_response = json.dumps(response_dict, indent=4)
    # Print the JSON response for debugging
    print(json_response)
    return json_response

def run_llamacpp_inference():
    """Client side function."""

    # TODO: The vllm endpoint UUID on Polaris
    endpoint = "067537cf-a50d-40c5-aad7-806e4ecde6c2"
    
    # Initialize the compute executor
    gce = Executor(endpoint_id=endpoint)

    # Sample prompts.
    prompts = [
        "Hello, my name is",
        "The president of the United States is",
        "The capital of France is",
        "The future of AI is",
    ]

    # Submit the remote procedure call
    fut = gce.submit(_llamacpp_inference, prompt=prompts[0])

    print("Running function", fut)

    # Collect the return result
    result = fut.result()

    return result

if __name__ == "__main__":
    results = run_llamacpp_inference()
    for result in results:
        print(result)

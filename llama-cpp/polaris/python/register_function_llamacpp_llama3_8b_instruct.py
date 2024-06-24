# Import packages
import globus_compute_sdk

# Define Globus Compute function
def llamacpp_inference (**kwargs):
    import openai
    import socket
    import json
    import os
    
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

    try:
        # Send a request to the chat completions endpoint
        response = client.chat.completions.create(
            model="Meta-Llama-3-8B-Instruct-Q8_0.gguf",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": kwargs.get('prompt', '')}
            ],
            **kwargs  # Pass all other keyword arguments to the API
        )
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

    return response
    
    
    response_dict = response.to_dict()  # This converts the response to a dictionary
    
    
    # Convert the response to a JSON-formatted string
    
    json_response = json.dumps(response_dict, indent=4)
    print(json_response)
    
    # Convert JSON string back to a Python dictionary
    response_dict = json.loads(json_response)
    
    # Access the content of the assistant's message
    assistant_content = response_dict['choices'][0]['message']['content']
    
    print("Assistant's Response Content:")
    print(assistant_content)
    return json_response

# Creating Globus Compute client
gcc = globus_compute_sdk.Client()

# Register the function
COMPUTE_FUNCTION_ID = gcc.register_function(llamacpp_inference_Llama38B_Instruct)

# Write function UUID in a file
uuid_file_name = "llama_cpp_8b_function_uuid.txt"
with open(uuid_file_name, "w") as file:
    file.write(COMPUTE_FUNCTION_ID)
    file.write("\n")
file.close()

# End of script
print("Function registered with UUID -", COMPUTE_FUNCTION_ID)
print("The UUID is stored in " + uuid_file_name + ".")
print("")
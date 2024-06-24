from openai import OpenAI
import socket
import json
import os




# Determine the hostname
hostname = socket.gethostname()
os.environ['no_proxy'] = hostname
# Construct the base_url
base_url = f"http://{hostname}:8000/v1"

client = OpenAI(
    base_url=base_url,
    api_key="cxvff_xxxx",
)

completion = client.chat.completions.create(
    model="mistralai/Mistral-7B-Instruct-v0.1",
    messages=[
        {
            "role": "user",
            "content": "How do I output all files in a directory using Python?",
        },
    ],
    logprobs=1
)
print(completion)

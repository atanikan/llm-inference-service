from openai import OpenAI

import base64
import socket

def image_to_base64_data_uri(file_path):
    with open(file_path, "rb") as img_file:
        base64_data = base64.b64encode(img_file.read()).decode('utf-8')
        return f"data:image/png;base64,{base64_data}"

# Replace 'file_path.png' with the actual path to your PNG file
file_path = '/grand/datascience/atanikanti/llm-inference-service/llama-cpp/polaris/Emberiza_calandra_and_Emberiza_melanocephala_by_Naumann.jpg'
data_uri = image_to_base64_data_uri(file_path)

# Determine the hostname
hostname = socket.gethostname()
# Construct the base_url
base_url = f"http://{hostname}:8080/v1"

client = OpenAI(base_url=base_url, api_key="cxvff_xxxx")



# response = client.chat.completions.create(
#     model="llava-v1_6-34b.Q5_K_M",
#     messages=[
#         {"role": "system", "content": "You are an assistant who perfectly describes images."},
#         {
#             "role": "user",
#             "content": [
#                 {
#                     "type": "image_url",
#                     "image_url": {
#                         "url": data_uri 
#                         #"url":"https://upload.wikimedia.org/wikipedia/commons/d/d2/Emberiza_calandra_and_Emberiza_melanocephala_by_Naumann.jpg"
#                         }
#                 },
#                 {"type": "text", "text": "What's in this image?"}

#             ]
#         }
#     ],
#     temperature=0.2,
#     logprobs=True

# )

# print(response)


response = client.chat.completions.create(
    model="llama-2-70b-Q8_0",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {
            "role": "user",
            "content": [
                # {
                #     "type": "image_url",
                #     "image_url": {
                #         "url": data_uri 
                #         #"url":"https://upload.wikimedia.org/wikipedia/commons/d/d2/Emberiza_calandra_and_Emberiza_melanocephala_by_Naumann.jpg"
                #         }
                # },
                {"type": "text", "text": "What are the proteins that interact with RAD51?"}

            ]
        }
    ],
    temperature=0.2,
    logprobs=True

)

print(response)
from llama_cpp import Llama
from llama_cpp.llama_chat_format import Llava15ChatHandler
chat_handler = Llava15ChatHandler(clip_model_path="path/to/llava/mmproj.bin")
llm = Llama(
  model_path="./path/to/llava/llama-model.gguf",
  chat_handler=chat_handler,
  n_ctx=2048, # n_ctx should be increased to accommodate the image embedding
)
llm.create_chat_completion(
    messages = [
        {"role": "system", "content": "You are an assistant who perfectly describes images."},
        {
            "role": "user",
            "content": [
                {"type" : "text", "text": "What's in this image?"},
                {"type": "image_url", "image_url": {"url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg" } }
            ]
        }
    ]
)

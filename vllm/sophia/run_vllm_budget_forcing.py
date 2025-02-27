from vllm import LLM, SamplingParams
from transformers import AutoTokenizer

# Decide on a token limit for thinking; As the model's max tokens is 32768, 32000 usually ensures there is enough space for the model to still answer
MAX_TOKENS_THINKING = 32000
# Decide how often to ignore end-of-thinking token
NUM_IGNORE = 1

model = LLM(
    "simplescaling/s1-32B", # s1 originally gets this prompt wrong but with budget forcing it fixes it
    tensor_parallel_size=4,
    gpu_memory_utilization=0.98,
    max_model_len=18352)
tok = AutoTokenizer.from_pretrained(
    "simplescaling/s1-32B"
)

stop_token_ids = tok("<|im_end|>")["input_ids"]
sampling_params = SamplingParams(
    max_tokens=32768,
    min_tokens=0,
    stop_token_ids=stop_token_ids,
    skip_special_tokens=False,
    temperature=0.0,
)

# For the exact raspberry sample in the paper see
prompts = [
    "How many r in raspberry",
]

for i, p in enumerate(prompts):
    prompt = "<|im_start|>system\nYou are Qwen, created by Alibaba Cloud. You are a helpful assistant.<|im_end|>\n<|im_start|>user\n" + p + "<|im_end|>\n<|im_start|>assistant\n"
    stop_token_ids = tok("<|im_start|><|im_end|>")["input_ids"]
    sampling_params = SamplingParams(
        max_tokens=MAX_TOKENS_THINKING,
        min_tokens=0,
        stop_token_ids=stop_token_ids,
        skip_special_tokens=False,
        temperature=0.0,
    )
    prompt += "<|im_start|>think"
    o = model.generate(
        prompt,
        sampling_params=sampling_params
    )
    ignore_str = "Wait"
    max_tokens_thinking_tmp = MAX_TOKENS_THINKING
    if max_tokens_thinking_tmp > 0:
        for i in range(NUM_IGNORE): # Num of times to skip stop token
            max_tokens_thinking_tmp -= len(o[0].outputs[0].token_ids)
            prompt += o[0].outputs[0].text + ignore_str
            sampling_params = SamplingParams(
                max_tokens=max_tokens_thinking_tmp,
                min_tokens=1,
                stop_token_ids=stop_token_ids,
                skip_special_tokens=False,
                temperature=0.0,
            )
            o = model.generate(
                prompt,
                sampling_params=sampling_params
            )
    ### Final answer ###
    prompt += o[0].outputs[0].text # You can also append "Final Answer:" here like we do for some evaluations to prevent the model from just continuing to reason in its answer when early exiting
    stop_token_ids = tok("<|im_end|>")["input_ids"]
    sampling_params = SamplingParams(
        max_tokens=32768,
        min_tokens=0,
        stop_token_ids=stop_token_ids,
        skip_special_tokens=False,
        temperature=0.0,
    )
    o = model.generate(
        prompt,
        sampling_params=sampling_params,
    )
    print("With budget forcing:") # You will see that after the "Wait" in the reasoning trace it fixes its answer
    print(prompt + o[0].outputs[0].text)

# llama-cpp-rx580
A sample Dockerfile that supports running LLMs with llama.cpp on the AMD RX580 GPU

The RX580 is a wonderful but slightly old GPU, so getting it to run modern LLMs is a little tricky. The most robust method I've found is to compile `llama.cpp` with the Vulkan backend. To isolate the mess of so many different driver versions from my host machine, I created this Docker container. It bakes in everything that's needed to run a modern LLM, specifically [Qwen3-VL:8b](https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct).

I'm sharing it here in case it helps anyone else. As configured, the parameters for `llama.cpp` will consume 8104M / 8147M of the GPU's VRAM. If you need to reduce that slightly, I recommend reducing the batch size or context length.

Many thanks to [Running Large Language Models on Cheap Old RX 580 GPUs with llama.cpp and Vulkan](https://dadhacks.org/2025/08/04/running-large-language-models-on-cheap-old-rx-580-gpus-with-llama-cpp-and-vulkan/) for guidance.
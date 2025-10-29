# Use the prebuilt PyTorch image (PyTorch + CUDA libs preinstalled)
FROM pytorch/pytorch:2.5.0-cuda12.4-cudnn9-devel

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies commonly needed for audio processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    libsndfile1 \
    build-essential \
    curl \
    ca-certificates \
    python3-dev \
    pkg-config \
    sox \
    libcudnn8 \
    && rm -rf /var/lib/apt/lists/*

# Create workspace 
WORKDIR /workspace

# Add these lines after the existing WORKDIR /workspace line
RUN mkdir -p /workspace/in /workspace/out

# Clone the three training repositories into it
RUN git clone https://github.com/feifel/kani-tts-training-wave2dataset.git \
 && git clone https://github.com/feifel/kani-tts-training-dataset2nano.git \
 && git clone https://github.com/feifel/kani-tts-training-finetune.git

# Setup kani-tts-training-wave2dataset
WORKDIR /workspace/kani-tts-training-wave2dataset
mkdir -p in out
RUN bash setup.sh

 # Setup dataset2nana repo
WORKDIR /workspace/kani-tts-training-dataset2nano
RUN yes '' | bash setup.sh



# Expose workspace for mounting; default to an interactive shell
VOLUME ["/workspace"]

# Add volume for Hugging Face cache to persist model downloads
VOLUME ["/root/.cache/huggingface"]
CMD ["bash"]
# Use the prebuilt PyTorch image (PyTorch + CUDA libs preinstalled)
FROM pytorch/pytorch:2.8.0-cuda12.9-cudnn9-devel

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
    software-properties-common \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Setup kani-tts-training-wave2dataset
RUN git clone https://github.com/feifel/kani-tts-training-wave2dataset.git /workspace/1-audio-to-dataset
WORKDIR /workspace/1-audio-to-dataset
RUN chmod +x setup.sh && bash setup.sh

# Setup dataset2nano repo
RUN git clone https://github.com/feifel/kani-tts-training-dataset2nano.git /workspace/2-dataset-to-nano
WORKDIR /workspace/2-dataset-to-nano
ENV TERM=xterm
RUN sed -i 's/sudo //g' setup.sh && chmod +x setup.sh && yes '' | bash setup.sh

# Setup finetune repo
RUN git clone https://github.com/feifel/kani-tts-training-finetune.git /workspace/3-nano-to-kanitts
WORKDIR /workspace/3-nano-to-kanitts
RUN make setup

# Start an interactive shell in the /workspace
WORKDIR /workspace

CMD ["bash"]